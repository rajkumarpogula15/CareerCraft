const { GoogleGenerativeAI } = require('@google/generative-ai');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

/**
 * Utility: Clean Gemini output to pure JSON
 */
function extractJson(raw) {
  if (!raw) throw new Error('Empty Gemini output');

  // Remove ```json and ``` fences
  const cleaned = raw
    .replace(/```json/gi, '')
    .replace(/```/g, '')
    .trim();

  return cleaned;
}

/**
 * Low-level Gemini call (SAFE + SUPPORTED)
 */
async function runGemini(prompt) {
  if (!prompt) throw new Error('Gemini prompt is required');

  const model = genAI.getGenerativeModel({
    model: process.env.GEMINI_MODEL, // e.g. "gemini-1.5-flash"
  });

  const result = await model.generateContent(prompt);
  const response = await result.response;
  const text = response.text();

  if (!text) {
    throw new Error('Empty Gemini response');
  }

  return text.trim();
}

/**
 * Repo summarization (uses runGemini)
 */
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

  const raw = await runGemini(prompt);

  let parsed;
  try {
    const cleaned = extractJson(raw);
    parsed = JSON.parse(cleaned);
  } catch (err) {
    console.error('🔥 Gemini raw output:\n', raw);
    console.error('🔥 JSON parse error:', err.message);
    throw new Error('Failed to parse Gemini summary JSON');
  }

  // Optional safety validation
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
