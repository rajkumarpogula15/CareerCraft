const { GoogleGenerativeAI } = require('@google/generative-ai');

const DEFAULT_MODEL = process.env.GEMINI_MODEL || 'gemini-1.5-flash';

const PURPOSE_KEY_ENV = {
  question_generation: 'GEMINI_API_KEY_QUESTION',
  answer_evaluation: 'GEMINI_API_KEY_EVALUATION',
  final_analysis: 'GEMINI_API_KEY_ANALYSIS',
  repo_summary: 'GEMINI_API_KEY_ANALYSIS',
};

function unique(values) {
  return [...new Set(values.filter(Boolean))];
}

function keysForPurpose(purpose = 'repo_summary') {
  const primary = process.env[PURPOSE_KEY_ENV[purpose]];
  const fallback = process.env.GEMINI_API_KEY;

  if (purpose === 'question_generation') {
    return unique([
      primary,
      process.env.GEMINI_API_KEY_EVALUATION,
      process.env.GEMINI_API_KEY_ANALYSIS,
      fallback,
    ]);
  }

  if (purpose === 'answer_evaluation') {
    return unique([
      primary,
      process.env.GEMINI_API_KEY_QUESTION,
      process.env.GEMINI_API_KEY_ANALYSIS,
      fallback,
    ]);
  }

  return unique([
    primary,
    process.env.GEMINI_API_KEY_QUESTION,
    process.env.GEMINI_API_KEY_EVALUATION,
    fallback,
  ]);
}

function extractJson(raw) {
  if (!raw) throw new Error('Empty Gemini output');

  return raw
    .replace(/```json/gi, '')
    .replace(/```/g, '')
    .trim();
}

async function runGemini(prompt, { purpose = 'repo_summary' } = {}) {
  if (!prompt) throw new Error('Gemini prompt is required');

  const keys = keysForPurpose(purpose);
  if (keys.length === 0) {
    throw new Error('No Gemini API keys configured');
  }

  let lastError;

  for (const key of keys) {
    try {
      const genAI = new GoogleGenerativeAI(key);
      const model = genAI.getGenerativeModel({ model: DEFAULT_MODEL });

      const result = await model.generateContent(prompt);
      const response = await result.response;
      const text = response.text()?.trim();

      if (!text) throw new Error('Empty Gemini response');
      return text;
    } catch (err) {
      lastError = err;
      const message = err?.message || String(err);
      console.error(`Gemini call failed for purpose=${purpose}: ${message}`);
    }
  }

  throw new Error(
    `Gemini request failed after trying ${keys.length} key(s): ${lastError?.message || 'unknown error'}`
  );
}

async function summarizeRepo({ repoName, description, readme, structure }) {
  const prompt = `
You are an expert software interviewer.

Analyze the following GitHub repository and return STRICT JSON.
DO NOT wrap the response in markdown.
DO NOT include explanations.

Repo Name: ${repoName}
Description: ${description || 'N/A'}

README:
${readme || 'N/A'}

Top-level Structure:
${structure.map(i => i.path).join('\n')}

Return ONLY valid JSON in this format:
{
  "techStack": [],
  "purpose": "",
  "keyFeatures": [],
  "architectureHints": []
}
`;

  const raw = await runGemini(prompt, { purpose: 'repo_summary' });

  let parsed;
  try {
    const cleaned = extractJson(raw);
    parsed = JSON.parse(cleaned);
  } catch (err) {
    console.error('Gemini raw output:\n', raw);
    console.error('Gemini JSON parse error:', err.message);
    throw new Error('Failed to parse Gemini summary JSON');
  }

  const requiredKeys = [
    'techStack',
    'purpose',
    'keyFeatures',
    'architectureHints',
  ];

  for (const key of requiredKeys) {
    if (!(key in parsed)) {
      throw new Error(`Gemini response missing key: ${key}`);
    }
  }

  return parsed;
}

module.exports = {
  runGemini,
  summarizeRepo,
};
