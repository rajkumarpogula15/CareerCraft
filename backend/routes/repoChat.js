const express = require('express');
const axios = require('axios');
const requireAuth = require('../middleware/requireAuth');

const ChatSession = require('../models/ChatSession');
const ChatMessage = require('../models/ChatMessage');
const User = require('../models/User');

const { fetchRepoFiles } = require('../utils/githubRepoReader');
const { buildRepoContext } = require('../utils/repoContext');
const { resolveRepo } = require('../utils/resolveRepo');

const router = express.Router();

/**
 * CREATE / GET SESSION
 */
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
  } catch (err) {
    console.error('[CHAT] Session error:', err);
    res.status(500).json({ error: 'Failed to create session' });
  }
});

/**
 * SEND MESSAGE (REPO + MEMORY + GEMINI)
 */
router.post('/message', requireAuth, async (req, res) => {
  try {
    const { sessionId, message } = req.body;

    const session = await ChatSession.findById(sessionId);
    if (!session) {
      return res.json({
        reply:
          'The provided repository context does not contain this implementation.',
      });
    }

    // 🔐 Load user + GitHub token safely
    const user = await User.findById(req.user.userId);
    if (!user?.githubAccessToken) {
      return res.json({
        reply:
          'The provided repository context does not contain this implementation.',
      });
    }

    const githubToken = user.githubAccessToken;

    // Save user message
    await ChatMessage.create({
      sessionId,
      role: 'user',
      content: message,
    });

    /**
     * Resolve repository (owner + name)
     */
    let repo;
    try {
      repo = await resolveRepo(githubToken, session.repoName);
    } catch {
      return res.json({
        reply:
          'The provided repository context does not contain this implementation.',
      });
    }

    /**
     * Fetch repo files
     */
    const repoFiles = await fetchRepoFiles(
      repo.owner.login,
      repo.name,
      githubToken
    );

    /**
     * Build repo-aware context
     */
    const repoContext = buildRepoContext(repoFiles, message);

    /**
     * Load previous chat (MEMORY)
     */
    const history = await ChatMessage.find({ sessionId })
      .sort({ createdAt: 1 })
      .limit(10); // last 10 messages only

    const conversation = history.map(m => ({
      role: m.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: m.content }],
    }));

    /**
     * SYSTEM PROMPT (STRICT)
     */
    const systemPrompt = `
You are a STRICT repository-specific senior developer assistant.

Repository context:
${repoContext}

RULES (MANDATORY):
- Answer ONLY using repository content above
- ALWAYS reference file names
- Maintain conversational context
- NEVER guess or hallucinate
- If not found, reply EXACTLY:
  "The provided repository context does not contain this implementation."
`;

    /**
     * Send to Gemini
     */
    const geminiRes = await axios.post(
      `https://generativelanguage.googleapis.com/v1beta/models/${process.env.GEMINI_MODEL}:generateContent`,
      {
        contents: [
          { role: 'user', parts: [{ text: systemPrompt }] },
          ...conversation,
          { role: 'user', parts: [{ text: message }] },
        ],
        generationConfig: {
          temperature: 0,
          maxOutputTokens: 600,
        },
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': process.env.GEMINI_API_KEY,
        },
      }
    );

    const reply =
      geminiRes.data?.candidates?.[0]?.content?.parts?.[0]?.text ||
      'The provided repository context does not contain this implementation.';

    // Save assistant reply
    await ChatMessage.create({
      sessionId,
      role: 'assistant',
      content: reply,
    });

    res.json({ reply });
  } catch (err) {
    console.error('[CHAT] Error:', err);
    res.status(500).json({
      reply:
        'The provided repository context does not contain this implementation.',
    });
  }
});

/**
 * FETCH HISTORY
 */
router.get('/history/:sessionId', requireAuth, async (req, res) => {
  try {
    const messages = await ChatMessage.find({
      sessionId: req.params.sessionId,
    }).sort({ createdAt: 1 });

    res.json(messages);
  } catch (err) {
    res.status(500).json([]);
  }
});

module.exports = router;
