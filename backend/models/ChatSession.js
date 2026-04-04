// models/ChatSession.js
const mongoose = require('mongoose');

const ChatSessionSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    repoOwner: String,
    repoName: String,
    title: String, // e.g. "Auth Logic Discussion"
    lastTopic: String,
    lastContextPaths: [String],
  },
  { timestamps: true }
);

module.exports = mongoose.model('ChatSession', ChatSessionSchema);
