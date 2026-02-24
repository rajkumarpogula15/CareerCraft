const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema(
  {
    githubId: {
      type: Number,
      required: true,
      unique: true,
      index: true,
    },

    username: String,
    name: String,
    avatar: String,
    email: String,

    // 🔑 GitHub OAuth token
    githubAccessToken: {
      type: String,
      required: true,
    },

    // ✅ GitHub stats
    public_repos: {
      type: Number,
      default: 0,
    },
    followers: {
      type: Number,
      default: 0,
    },
    following: {
      type: Number,
      default: 0,
    },

    role: {
      type: String,
      enum: ['user', 'admin'],
      default: 'user',
    },

    lastLoginAt: Date,
    loginStreak: {
      type: Number,
      default: 0,
    },
    maxLoginStreak: {
      type: Number,
      default: 0,
    },
    loginDates: {
      type: [Date],
      default: [],
    },
    notificationEnabled: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', UserSchema);
