const DEBUG_REPO_CONTEXT = false;
const NO_RELEVANT_FILES = 'NO_RELEVANT_FILES';

const STOPWORDS = new Set([
  'a', 'an', 'and', 'are', 'as', 'at', 'be', 'by', 'do', 'does', 'for',
  'from', 'how', 'i', 'if', 'in', 'is', 'it', 'me', 'my', 'of', 'on',
  'or', 'show', 'that', 'the', 'this', 'to', 'was', 'what', 'where',
  'which', 'who', 'why', 'with', 'you', 'your',
]);

const WEIGHTS = {
  pathKeyword: 14,
  pathPhrase: 22,
  functionKeyword: 10,
  functionPhrase: 16,
  contentKeyword: 4,
  contentPhrase: 8,
  commentKeyword: 6,
  commentPhrase: 10,
};

const MAX_CHUNK_CHARS = 2200;
const CHUNK_OVERLAP_LINES = 6;
const MAX_CONTEXT_CHARS = 12000;
const MAX_CONTEXT_RESULTS = 6;
const MAX_SEMANTIC_CANDIDATES = 24;
const PREPARED_CACHE_TTL_MS = 10 * 60 * 1000;
const MIN_HYBRID_SCORE = 8;
const ADJACENT_CHUNK_WINDOW = 1;
const MAX_BLOCK_SCAN_LINES = 160;

const preparedRepoCache = new Map();

/* ---------------- NORMALIZATION ---------------- */

function normalizeIdentifiers(text) {
  return String(text || '')
    .toLowerCase()
    .replace(/[_\-]/g, ' ')
    .replace(/([a-z])([A-Z])/g, '$1 $2')
    .replace(/[^a-z0-9 ]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function unique(values) {
  return [...new Set(values.filter(Boolean))];
}

function extractKeywords(message) {
  return unique(
    normalizeIdentifiers(message)
      .split(' ')
      .filter(word => word.length >= 2 && !STOPWORDS.has(word))
  );
}

function extractPhrases(message) {
  const normalized = normalizeIdentifiers(message);
  const quotedPhrases = [...String(message || '').matchAll(/"([^"]+)"/g)]
    .map(match => normalizeIdentifiers(match[1]))
    .filter(Boolean);
  const words = normalized
    .split(' ')
    .filter(word => word.length >= 2 && !STOPWORDS.has(word));
  const ngrams = [];

  for (let size = 2; size <= 3; size += 1) {
    for (let index = 0; index <= words.length - size; index += 1) {
      ngrams.push(words.slice(index, index + size).join(' '));
    }
  }

  return unique([...quotedPhrases, ...ngrams]);
}

/* ---------------- SAFETY ---------------- */

function isBinaryText(text) {
  return typeof text === 'string' && text.includes('\u0000');
}

function isCommentLine(line) {
  return /^\s*(\/\/|\/\*|\*|#)/.test(line);
}

/* ---------------- CODE INTELLIGENCE ---------------- */

function extractFunctionNames(text) {
  const patterns = [
    /\bfunction\s+([A-Za-z_$][\w$]*)\s*\(/g,
    /\b(?:const|let|var)\s+([A-Za-z_$][\w$]*)\s*=\s*(?:async\s*)?\([^)]*\)\s*=>/g,
    /\b(?:const|let|var)\s+([A-Za-z_$][\w$]*)\s*=\s*function\b/g,
    /\b([A-Za-z_$][\w$]*)\s*:\s*(?:async\s*)?\([^)]*\)\s*=>/g,
    /\bclass\s+([A-Za-z_$][\w$]*)\b/g,
  ];

  const names = [];

  for (const pattern of patterns) {
    for (const match of text.matchAll(pattern)) {
      names.push(normalizeIdentifiers(match[1]));
    }
  }

  return unique(names);
}

function stripStrings(line) {
  return String(line || '')
    .replace(/`(?:\\.|[^`])*`/g, '')
    .replace(/"(?:\\.|[^"])*"/g, '')
    .replace(/'(?:\\.|[^'])*'/g, '');
}

function countBraces(line) {
  const sanitized = stripStrings(line)
    .replace(/\/\/.*$/g, '')
    .replace(/\/\*.*?\*\//g, '');

  return {
    open: (sanitized.match(/{/g) || []).length,
    close: (sanitized.match(/}/g) || []).length,
  };
}

function isDeclarationLine(line) {
  const normalized = String(line || '').trim();

  return (
    /\bfunction\s+[A-Za-z_$][\w$]*\s*\(/.test(normalized) ||
    /\bclass\s+[A-Za-z_$][\w$]*/.test(normalized) ||
    /\b(?:const|let|var)\s+[A-Za-z_$][\w$]*\s*=\s*(?:async\s*)?\([^)]*\)\s*=>/.test(normalized) ||
    /\b(?:async\s+)?[A-Za-z_$][\w$]*\s*\([^)]*\)\s*\{/.test(normalized) ||
    /\b(?:async\s+)?[A-Za-z_$][\w$]*\s*:\s*(?:async\s*)?\([^)]*\)\s*=>/.test(normalized)
  );
}

function hasBlockBoundary(line) {
  return /[{=>]/.test(String(line || ''));
}

function splitIntoChunks(file) {
  const lines = file.content.split('\n');
  const chunks = [];
  let startLine = 0;

  while (startLine < lines.length) {
    let endLine = startLine;
    let currentLength = 0;

    while (endLine < lines.length && currentLength < MAX_CHUNK_CHARS) {
      currentLength += lines[endLine].length + 1;
      endLine += 1;
    }

    const chunkLines = lines.slice(startLine, endLine);
    const chunkText = chunkLines.join('\n').trim();

    if (chunkText) {
      const functionNames = extractFunctionNames(chunkText);
      const commentText = chunkLines.filter(isCommentLine).join('\n');

      chunks.push({
        id: `${file.path}:${startLine + 1}-${endLine}`,
        path: file.path,
        startLine: startLine + 1,
        endLine,
        text: chunkText,
        normalizedText: normalizeIdentifiers(chunkText),
        normalizedPath: normalizeIdentifiers(file.path),
        functionNames,
        normalizedFunctions: functionNames.join(' '),
        normalizedComments: normalizeIdentifiers(commentText),
        sourceLines: lines,
      });
    }

    if (endLine >= lines.length) {
      break;
    }

    startLine = Math.max(endLine - CHUNK_OVERLAP_LINES, startLine + 1);
  }

  const fileChunkRanges = chunks.map(chunk => ({
    startLine: chunk.startLine,
    endLine: chunk.endLine,
  }));

  chunks.forEach((chunk, index) => {
    chunk.chunkIndex = index;
    chunk.fileChunkRanges = fileChunkRanges;
  });

  return chunks;
}

function prepareRepoChunks(files, cacheKey) {
  if (cacheKey) {
    const cached = preparedRepoCache.get(cacheKey);
    if (cached && cached.expiresAt > Date.now()) {
      return cached.chunks;
    }
  }

  const chunks = files
    .filter(file => file?.path && typeof file.content === 'string' && !isBinaryText(file.content))
    .flatMap(splitIntoChunks);

  if (cacheKey) {
    preparedRepoCache.set(cacheKey, {
      chunks,
      expiresAt: Date.now() + PREPARED_CACHE_TTL_MS,
    });
  }

  return chunks;
}

/* ---------------- SCORING ---------------- */

function countKeywordMatches(text, keywords, weight) {
  return keywords.reduce(
    (score, keyword) => score + (text.includes(keyword) ? weight : 0),
    0
  );
}

function countPhraseMatches(text, phrases, weight) {
  return phrases.reduce(
    (score, phrase) => score + (text.includes(phrase) ? weight : 0),
    0
  );
}

function scoreChunkLexically(chunk, query) {
  const pathScore =
    countKeywordMatches(chunk.normalizedPath, query.keywords, WEIGHTS.pathKeyword) +
    countPhraseMatches(chunk.normalizedPath, query.phrases, WEIGHTS.pathPhrase);
  const functionScore =
    countKeywordMatches(chunk.normalizedFunctions, query.keywords, WEIGHTS.functionKeyword) +
    countPhraseMatches(chunk.normalizedFunctions, query.phrases, WEIGHTS.functionPhrase);
  const commentScore =
    countKeywordMatches(chunk.normalizedComments, query.keywords, WEIGHTS.commentKeyword) +
    countPhraseMatches(chunk.normalizedComments, query.phrases, WEIGHTS.commentPhrase);
  const contentScore =
    countKeywordMatches(chunk.normalizedText, query.keywords, WEIGHTS.contentKeyword) +
    countPhraseMatches(chunk.normalizedText, query.phrases, WEIGHTS.contentPhrase);

  const exactFunctionBoost = chunk.functionNames.some(name => query.normalizedMessage.includes(name))
    ? 12
    : 0;

  return pathScore + functionScore + commentScore + contentScore + exactFunctionBoost;
}

function cosineSimilarity(left = [], right = []) {
  if (!left.length || left.length !== right.length) {
    return 0;
  }

  let dotProduct = 0;
  let leftMagnitude = 0;
  let rightMagnitude = 0;

  for (let index = 0; index < left.length; index += 1) {
    dotProduct += left[index] * right[index];
    leftMagnitude += left[index] * left[index];
    rightMagnitude += right[index] * right[index];
  }

  if (!leftMagnitude || !rightMagnitude) {
    return 0;
  }

  return dotProduct / (Math.sqrt(leftMagnitude) * Math.sqrt(rightMagnitude));
}

async function scoreChunksSemantically(scoredChunks, message, embedTextBatch) {
  if (typeof embedTextBatch !== 'function' || !scoredChunks.length) {
    return scoredChunks;
  }

  const semanticCandidates = scoredChunks
    .slice()
    .sort((left, right) => right.lexicalScore - left.lexicalScore)
    .slice(0, MAX_SEMANTIC_CANDIDATES);

  const embeddings = await embedTextBatch([
    message,
    ...semanticCandidates.map(chunk => chunk.text),
  ]);

  if (!Array.isArray(embeddings) || embeddings.length < 2) {
    return scoredChunks;
  }

  const [queryEmbedding, ...chunkEmbeddings] = embeddings;

  semanticCandidates.forEach((chunk, index) => {
    chunk.semanticScore = cosineSimilarity(queryEmbedding, chunkEmbeddings[index]);
    chunk.score = chunk.lexicalScore + chunk.semanticScore * 20;
  });

  return scoredChunks;
}

function formatContext(scoredChunks) {
  let currentLength = 0;
  const contextBlocks = [];

  for (const chunk of scoredChunks) {
    const blockText = Array.isArray(chunk.sourceLines)
      ? chunk.sourceLines.slice(chunk.startLine - 1, chunk.endLine).join('\n').trim()
      : chunk.text;
    const functionNames = extractFunctionNames(blockText);
    const block = [
      `File: ${chunk.path}`,
      `Function: ${functionNames[0] || chunk.functionNames?.[0] || 'Unknown'}`,
      `Lines: ${chunk.startLine}-${chunk.endLine}`,
      `Relevance Score: ${chunk.score.toFixed(2)}`,
      'Code:',
      blockText,
    ].join('\n');

    if (currentLength + block.length > MAX_CONTEXT_CHARS) {
      break;
    }

    contextBlocks.push(block);
    currentLength += block.length + 2;
  }

  return contextBlocks.join('\n\n');
}

function expandToAdjacentChunkRange(chunk) {
  const ranges = Array.isArray(chunk.fileChunkRanges) ? chunk.fileChunkRanges : [];
  if (!ranges.length || typeof chunk.chunkIndex !== 'number') {
    return {
      startLine: chunk.startLine,
      endLine: chunk.endLine,
    };
  }

  const startIndex = Math.max(0, chunk.chunkIndex - ADJACENT_CHUNK_WINDOW);
  const endIndex = Math.min(ranges.length - 1, chunk.chunkIndex + ADJACENT_CHUNK_WINDOW);

  return {
    startLine: ranges[startIndex].startLine,
    endLine: ranges[endIndex].endLine,
  };
}

function findEnclosingBlockStart(lines, startIndex, searchFloor) {
  for (let index = startIndex; index >= searchFloor; index -= 1) {
    const line = lines[index];
    if (!line?.trim()) {
      continue;
    }

    if (isDeclarationLine(line) && hasBlockBoundary(line)) {
      return index;
    }
  }

  return startIndex;
}

function expandRangeToLogicalBlock(chunk, range) {
  const lines = chunk.sourceLines;
  if (!Array.isArray(lines) || !lines.length) {
    return range;
  }

  const searchFloor = Math.max(0, range.startLine - 1 - MAX_BLOCK_SCAN_LINES);
  const startIndex = findEnclosingBlockStart(lines, range.startLine - 1, searchFloor);
  let balance = 0;
  let seenOpeningBrace = false;
  let endIndex = Math.max(range.endLine - 1, startIndex);

  for (let index = startIndex; index < lines.length; index += 1) {
    const { open, close } = countBraces(lines[index]);
    if (open > 0) {
      seenOpeningBrace = true;
    }

    balance += open - close;

    if (index >= endIndex) {
      if (!seenOpeningBrace) {
        endIndex = index;
        break;
      }

      if (balance <= 0) {
        endIndex = index;
        break;
      }
    }

    if (index - startIndex >= MAX_BLOCK_SCAN_LINES && index >= endIndex) {
      endIndex = index;
      break;
    }
  }

  return {
    startLine: startIndex + 1,
    endLine: Math.min(lines.length, endIndex + 1),
  };
}

function expandSelectedChunk(chunk) {
  const adjacentRange = expandToAdjacentChunkRange(chunk);
  const logicalRange = expandRangeToLogicalBlock(chunk, adjacentRange);

  return {
    ...chunk,
    startLine: Math.min(chunk.startLine, logicalRange.startLine),
    endLine: Math.max(chunk.endLine, logicalRange.endLine),
  };
}

function mergeExpandedChunks(chunks) {
  const sortedChunks = chunks
    .slice()
    .sort((left, right) => {
      if (left.path !== right.path) {
        return left.path.localeCompare(right.path);
      }

      return left.startLine - right.startLine;
    });

  const merged = [];

  for (const chunk of sortedChunks) {
    const previous = merged[merged.length - 1];

    if (
      previous &&
      previous.path === chunk.path &&
      chunk.startLine <= previous.endLine + 1
    ) {
      previous.endLine = Math.max(previous.endLine, chunk.endLine);
      previous.score = Math.max(previous.score, chunk.score);
      previous.functionNames = unique([
        ...previous.functionNames,
        ...chunk.functionNames,
      ]);
      continue;
    }

    merged.push({
      ...chunk,
      functionNames: [...chunk.functionNames],
    });
  }

  return merged.sort((left, right) => right.score - left.score);
}

/* ---------------- CONTEXT BUILDER ---------------- */

async function buildRepoContext(files, message, options = {}) {
  if (!Array.isArray(files) || !message) {
    return {
      found: false,
      context: NO_RELEVANT_FILES,
      matches: [],
    };
  }

  const query = {
    normalizedMessage: normalizeIdentifiers(message),
    keywords: extractKeywords(message),
    phrases: extractPhrases(message),
  };

  const preparedChunks = prepareRepoChunks(files, options.cacheKey);
  const scoredChunks = preparedChunks
    .map(chunk => {
      const lexicalScore = scoreChunkLexically(chunk, query);

      return {
        ...chunk,
        lexicalScore,
        semanticScore: 0,
        score: lexicalScore,
      };
    });

  const lexicalCandidates = scoredChunks.filter(chunk => chunk.lexicalScore > 0);
  const retrievalPool = lexicalCandidates.length
    ? lexicalCandidates
    : scoredChunks.slice(0, MAX_SEMANTIC_CANDIDATES);

  if (!retrievalPool.length) {
    return {
      found: false,
      context: NO_RELEVANT_FILES,
      matches: [],
    };
  }

  const hybridCandidates = await scoreChunksSemantically(
    retrievalPool,
    message,
    options.embedTextBatch
  );

  const topMatches = hybridCandidates
    .filter(chunk => chunk.score >= MIN_HYBRID_SCORE)
    .sort((left, right) => right.score - left.score)
    .slice(0, MAX_CONTEXT_RESULTS);

  if (!topMatches.length) {
    return {
      found: false,
      context: NO_RELEVANT_FILES,
      matches: [],
    };
  }

  if (DEBUG_REPO_CONTEXT) {
    console.log(
      topMatches.map(match => ({
        path: match.path,
        lines: `${match.startLine}-${match.endLine}`,
        lexical: match.lexicalScore,
        semantic: match.semanticScore,
        score: match.score,
      }))
    );
  }

  return {
    found: true,
    context: formatContext(mergeExpandedChunks(topMatches.map(expandSelectedChunk))),
    matches: topMatches,
  };
}

module.exports = {
  NO_RELEVANT_FILES,
  buildRepoContext,
  extractFunctionNames,
};
