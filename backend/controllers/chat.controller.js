const chatService = require('../services/chat.service');

const createSession = async (req, res) => {
  try {
    const { repoOwner, repoName } = req.body;
    const session = await chatService.getOrCreateSession({
      userId: req.user.userId,
      repoOwner,
      repoName,
    });

    res.json(session);
  } catch (err) {
    res.status(500).json({ error: 'Failed to create session' });
  }
};

const sendMessage = async (req, res) => {
  try {
    const result = await chatService.sendMessage({
      userId: req.user.userId,
      sessionId: req.body.sessionId,
      message: req.body.message,
    });

    res.json(result);
  } catch (err) {
    res.status(500).json({ reply: chatService.FALLBACK_REPLY });
  }
};

const getHistory = async (req, res) => {
  try {
    const messages = await chatService.getHistory(req.params.sessionId);
    res.json(messages);
  } catch {
    res.status(500).json([]);
  }
};

module.exports = {
  createSession,
  sendMessage,
  getHistory,
};
