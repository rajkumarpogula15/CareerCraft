const axios = require('axios');
const chatRepository = require('../repositories/chat.repository');
const userRepository = require('../repositories/user.repository');
const { fetchRepoFiles } = require('../utils/githubRepoReader');
const { buildRepoContext } = require('../utils/repoContext');
const { resolveRepo } = require('../utils/resolveRepo');
const logActivity = require('../utils/logActivity');

const FALLBACK_REPLY =
  'The provided repository context does not contain this implementation.';

const getOrCreateSession = async ({ userId, repoOwner, repoName }) => {
  let session = await chatRepository.findSessionByUserAndRepo(userId, repoName);

  if (!session) {
    session = await chatRepository.createSession({
      userId,
      repoOwner,
      repoName,
      title: `${repoName} Assistant`,
    });
  }

  return session;
};

const sendMessage = async ({ userId, sessionId, message }) => {
  const session = await chatRepository.findSessionById(sessionId);
  if (!session) return { reply: FALLBACK_REPLY };

  const user = await userRepository.findById(userId);
  if (!user?.githubAccessToken) return { reply: FALLBACK_REPLY };

  await chatRepository.createMessage({ sessionId, role: 'user', content: message });

  let repo;
  try {
    repo = await resolveRepo(user.githubAccessToken, session.repoName);
  } catch {
    return { reply: FALLBACK_REPLY };
  }

  const repoFiles = await fetchRepoFiles(repo.owner.login, repo.name, user.githubAccessToken);
  const repoContext = buildRepoContext(repoFiles, message);

  const history = await chatRepository.findRecentHistory(sessionId, 10);
  const conversation = history.map(m => ({
    role: m.role === 'assistant' ? 'model' : 'user',
    parts: [{ text: m.content }],
  }));

  const systemPrompt = `
You are a STRICT repository-specific senior developer assistant.

Repository context:
${repoContext}

RULES:
- Answer ONLY using repository content above
- ALWAYS reference file names
- NEVER guess or hallucinate
- If not found, reply EXACTLY:
  "${FALLBACK_REPLY}"
`;

  const geminiRes = await axios.post(
    `https://generativelanguage.googleapis.com/v1beta/models/${process.env.GEMINI_MODEL}:generateContent`,
    {
      contents: [
        { role: 'user', parts: [{ text: systemPrompt }] },
        ...conversation,
        { role: 'user', parts: [{ text: message }] },
      ],
      generationConfig: { temperature: 0, maxOutputTokens: 600 },
    },
    {
      headers: {
        'Content-Type': 'application/json',
        'X-goog-api-key': process.env.GEMINI_API_KEY,
      },
    }
  );

  const reply = geminiRes.data?.candidates?.[0]?.content?.parts?.[0]?.text || FALLBACK_REPLY;

  await chatRepository.createMessage({ sessionId, role: 'assistant', content: reply });

  await logActivity({
    userId,
    type: 'repo_chat',
    repoName: session.repoName,
    message: `Chatted with ${session.repoName} assistant`,
  });

  return { reply };
};

const getHistory = sessionId => chatRepository.findFullHistory(sessionId);

module.exports = {
  FALLBACK_REPLY,
  getOrCreateSession,
  sendMessage,
  getHistory,
};
