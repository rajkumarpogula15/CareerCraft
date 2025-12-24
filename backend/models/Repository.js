const mongoose = require('mongoose');

const RepoSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  repoId: Number,
  name: String,
  fullName: String,
  description: String,
  private: Boolean,
  htmlUrl: String,
  favourite: { type: Boolean, default: false },
  updatedAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Repository', RepoSchema);
