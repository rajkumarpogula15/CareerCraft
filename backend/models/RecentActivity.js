const mongoose = require('mongoose');

const RecentActivitySchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    type: {
      type: String,
      enum: [
        'readme_generated',
        'repo_chat',
        'repo_favourite',
        'repo_opened',
      ],
      required: true,
    },

    repoName: String,

    message: {
      type: String,
      required: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('RecentActivity', RecentActivitySchema);
