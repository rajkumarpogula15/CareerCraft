const express = require('express');
const axios = require('axios');
const requireAuth = require('../middleware/requireAuth');

const ChatSession = require('../models/ChatSession');
const ChatMessage = require('../models/ChatMessage');
const User = require('../models/User');
const { runGemini } = require('../services/gemini.service');

const { fetchRepoFiles } = require('../utils/githubRepoReader');
const { buildRepoContext, NO_RELEVANT_FILES } = require('../utils/repoContext');
const { embedTexts } = require('../utils/geminiEmbedding');
const { resolveRepo } = require('../utils/resolveRepo');
const logActivity = require('../utils/logActivity');

const router = express.Router();

const NO_CONTEXT_REPLY =
  'The provided repository context does not contain this implementation.';

const RECENT_USER_MESSAGES = 4;
const RECENT_HISTORY = 8;

/* ---------------- HELPERS ---------------- */

function normalize(text) {
  return String(text || '').replace(/\s+/g, ' ').trim();
}

function unique(arr) {
  return [...new Set(arr.filter(Boolean))];
}

function isVague(text) {
  return /\b(it|this|that|they|them)\b/i.test(text);
}

function extractRecentUserMessages(history) {
  return unique(
    history
      .filter(m => m.role === 'user')
      .map(m => m.content)
      .slice(-RECENT_USER_MESSAGES)
  );
}

function inferTopic(history) {
  const reversed = [...history].reverse();
  for (const m of reversed) {
    if (m.content && m.content.length > 5) return m.content;
  }
  return '';
}

function buildSeed(message, recent, topic) {
  return unique([...recent, message, topic]).join(' ');
}

/* ---------------- QUERY REWRITE ---------------- */

async function rewriteQuery({ message, recent, topic, files }) {
  const seed = buildSeed(message, recent, topic);

  const prompt = `
You rewrite repository-chat follow-up questions into a clear standalone query.

RULES:
- Return ONLY rewritten query
- Keep under 35 words
- Replace vague words like "it", "this"
- NEVER leave ambiguity
- Do NOT answer

PRIORITY:
1. recent messages
2. topic
3. files

EXAMPLES:
Input: suggest improvements for it
Output: suggest improvements for chat bubble widget implementation

Recent:
${recent.join('\n')}

Message:
${message}

Topic:
${topic || 'None'}

Files:
${files?.join(', ') || 'None'}

Fallback:
${seed}
`;

  try {
    const rewritten = normalize(await runGemini(prompt));

    console.log('[REWRITE] Original:', message);
    console.log('[REWRITE] New:', rewritten);

    if (!rewritten || isVague(rewritten)) {
      console.log('[REWRITE] Using fallback');
      return seed || message;
    }

    return rewritten;
  } catch (err) {
    console.error('[REWRITE ERROR]', err);
    return seed || message;
  }
}

/* ---------------- HISTORY ---------------- */

async function getHistory(sessionId) {
  const messages = await ChatMessage.find({ sessionId })
    .sort({ createdAt: -1 })
    .limit(RECENT_HISTORY);

  return messages.reverse();
}

function buildConversation(history) {
  return history.map(m => ({
    role: m.role === 'assistant' ? 'model' : 'user',
    parts: [{ text: m.content }],
  }));
}

/* ---------------- SESSION ---------------- */

router.post('/session', requireAuth, async (req, res) => {
  try {
    const { repoOwner, repoName } = req.body;

    let session = await ChatSession.findOne({
      userId: req.user.userId,
      repoName,
    });

    if (!session) {
      session = await ChatSession.create({
        userId: req.user.userId,
        repoOwner,
        repoName,
        title: `${repoName} Assistant`,
      });
    }

    res.json(session);
  } catch {
    res.status(500).json({ error: 'Failed to create session' });
  }
});

/* ---------------- MESSAGE ---------------- */

router.post('/message', requireAuth, async (req, res) => {
  try {
    const { sessionId, message } = req.body;

    console.log('\n=== NEW MESSAGE ===');
    console.log('[USER]:', message);

    const session = await ChatSession.findById(sessionId);
    const user = await User.findById(req.user.userId);

    if (!session || !user?.githubAccessToken) {
      return res.json({ reply: NO_CONTEXT_REPLY });
    }

    const history = await getHistory(sessionId);
    const recent = extractRecentUserMessages(history);
    const topic = session.lastTopic || inferTopic(history);

    const query = await rewriteQuery({
      message,
      recent,
      topic,
      files: session.lastContextPaths,
    });

    console.log('[QUERY]:', query);

    await ChatMessage.create({
      sessionId,
      role: 'user',
      content: message,
    });

    const repo = await resolveRepo(user.githubAccessToken, session.repoName);

    const files = await fetchRepoFiles(
      repo.owner.login,
      repo.name,
      user.githubAccessToken
    );

    const contextResult = await buildRepoContext(files, query, {
      cacheKey: `${repo.owner.login}/${repo.name}`,
      embedTextBatch: texts =>
        embedTexts(texts, { taskType: 'SEMANTIC_SIMILARITY' }),
    });

    if (!contextResult.found) {
      return res.json({ reply: NO_CONTEXT_REPLY });
    }

    const conversation = buildConversation([
      ...history,
      { role: 'user', content: message },
    ]);

    /* 🔥 IMPROVED SYSTEM PROMPT */
    const systemPrompt = `
You are a STRICT repository-specific senior developer assistant.

Repository Context:
${contextResult.context}

INSTRUCTIONS:
- Answer ONLY using the repository context above
- ALWAYS mention file names and function/class names
- Explain clearly step-by-step
- Use bullet points for readability

STRICT RULES:
- DO NOT guess
- DO NOT use outside knowledge
- If not found, reply EXACTLY:
"${NO_CONTEXT_REPLY}"

OUTPUT STYLE:
- Start with direct answer
- Then detailed explanation
`;

    const geminiRes = await axios.post(
      `https://generativelanguage.googleapis.com/v1beta/models/${process.env.GEMINI_MODEL}:generateContent`,
      {
        contents: [
          { role: 'user', parts: [{ text: systemPrompt }] },
          ...conversation,
        ],
      },
      {
        headers: {
          'X-goog-api-key': process.env.GEMINI_API_KEY,
        },
      }
    );

    const reply =
      geminiRes.data?.candidates?.[0]?.content?.parts?.[0]?.text ||
      NO_CONTEXT_REPLY;

    console.log('[REPLY]:', reply);

    await ChatMessage.create({
      sessionId,
      role: 'assistant',
      content: reply,
    });

    await logActivity({
      userId: req.user.userId,
      type: 'repo_chat',
      repoName: session.repoName,
      message: `Chatted with ${session.repoName}`,
    });

    res.json({ reply });
  } catch (err) {
    console.error('[ERROR]', err);
    res.status(500).json({ reply: NO_CONTEXT_REPLY });
  }
});

/* ---------------- HISTORY ---------------- */

router.get('/history/:sessionId', requireAuth, async (req, res) => {
  try {
    const messages = await ChatMessage.find({
      sessionId: req.params.sessionId,
    }).sort({ createdAt: 1 });

    res.json(messages);
  } catch {
    res.status(500).json([]);
  }
});

module.exports = router;