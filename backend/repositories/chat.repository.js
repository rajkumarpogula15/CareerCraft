const ChatSession = require('../models/ChatSession');
const ChatMessage = require('../models/ChatMessage');

const findSessionByUserAndRepo = (userId, repoName) =>
  ChatSession.findOne({ userId, repoName });

const createSession = payload => ChatSession.create(payload);

const findSessionById = sessionId => ChatSession.findById(sessionId);

const createMessage = payload => ChatMessage.create(payload);

const findRecentHistory = (sessionId, limit = 10) =>
  ChatMessage.find({ sessionId }).sort({ createdAt: 1 }).limit(limit);

const findFullHistory = sessionId => ChatMessage.find({ sessionId }).sort({ createdAt: 1 });

module.exports = {
  findSessionByUserAndRepo,
  createSession,
  findSessionById,
  createMessage,
  findRecentHistory,
  findFullHistory,
};
