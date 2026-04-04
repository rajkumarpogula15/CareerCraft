const axios = require('axios');

const EMBEDDING_API_BASE = 'https://generativelanguage.googleapis.com/v1beta/models';
const DEFAULT_EMBEDDING_MODEL =
  process.env.GEMINI_EMBEDDING_MODEL || 'gemini-embedding-001';
const EMBEDDING_CACHE_TTL_MS = 30 * 60 * 1000;

const embeddingCache = new Map();

function getCacheKey(model, taskType, text) {
  return `${model}:${taskType}:${text}`;
}

function getCachedEmbedding(cacheKey) {
  const cached = embeddingCache.get(cacheKey);
  if (!cached) {
    return null;
  }

  if (cached.expiresAt <= Date.now()) {
    embeddingCache.delete(cacheKey);
    return null;
  }

  return cached.values;
}

function setCachedEmbedding(cacheKey, values) {
  embeddingCache.set(cacheKey, {
    values,
    expiresAt: Date.now() + EMBEDDING_CACHE_TTL_MS,
  });
}

function hasCompleteEmbeddings(results) {
  return results.length > 0 && results.every(Array.isArray);
}

async function embedTexts(texts, options = {}) {
  const filteredTexts = Array.isArray(texts)
    ? texts.filter(text => typeof text === 'string' && text.trim())
    : [];

  if (!filteredTexts.length || !process.env.GEMINI_API_KEY) {
    return [];
  }

  const model = options.model || DEFAULT_EMBEDDING_MODEL;
  const taskType = options.taskType || 'SEMANTIC_SIMILARITY';
  const results = new Array(filteredTexts.length);
  const uncachedTexts = [];
  const uncachedIndexes = [];

  filteredTexts.forEach((text, index) => {
    const cacheKey = getCacheKey(model, taskType, text);
    const cached = getCachedEmbedding(cacheKey);

    if (cached) {
      results[index] = cached;
      return;
    }

    uncachedTexts.push(text);
    uncachedIndexes.push(index);
  });

  if (!uncachedTexts.length) {
    return hasCompleteEmbeddings(results) ? results : [];
  }

  const response = await axios.post(
    `${EMBEDDING_API_BASE}/${model}:embedContent`,
    {
      model: `models/${model}`,
      content: {
        parts: uncachedTexts.map(text => ({ text })),
      },
      taskType,
    },
    {
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': process.env.GEMINI_API_KEY,
      },
    }
  );

  if (Array.isArray(response.data?.embeddings)) {
    response.data.embeddings
      .map(item => item?.values)
      .filter(Array.isArray)
      .forEach((values, position) => {
        const targetIndex = uncachedIndexes[position];
        if (typeof targetIndex === 'number') {
          results[targetIndex] = values;
          setCachedEmbedding(
            getCacheKey(model, taskType, filteredTexts[targetIndex]),
            values
          );
        }
      });

    return hasCompleteEmbeddings(results) ? results : [];
  }

  if (Array.isArray(response.data?.embedding?.values)) {
    results[uncachedIndexes[0]] = response.data.embedding.values;
    setCachedEmbedding(
      getCacheKey(model, taskType, filteredTexts[uncachedIndexes[0]]),
      response.data.embedding.values
    );
    return hasCompleteEmbeddings(results) ? results : [];
  }

  return [];
}

module.exports = { embedTexts };
