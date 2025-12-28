const mongoose = require('mongoose');

const RepoSummarySchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    repoId: {
      type: Number, // GitHub repo ID
      required: true,
    },

    repoName: {
      type: String,
      required: true,
    },

    description: String,

    techStack: [String], // Flutter, Node, React, etc.

    purpose: String,

    keyFeatures: [String],

    architectureHints: [String],

    lastRepoUpdate: Date, // from GitHub updated_at

    summarizedAt: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

// 🔑 Prevent duplicate summaries per user + repo
RepoSummarySchema.index({ userId: 1, repoId: 1 }, { unique: true });

module.exports = mongoose.model('RepoSummary', RepoSummarySchema);
