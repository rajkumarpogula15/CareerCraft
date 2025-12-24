const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema(
  {
    githubId: {
      type: Number,
      required: true,
      unique: true,
      index: true
    },

    username: {
      type: String,
      required: true
    },

    name: {
      type: String
    },

    avatar: {
      type: String
    },

    email: {
      type: String
    },

    role: {
      type: String,
      enum: ['user', 'admin'],
      default: 'user'
    },

    authProvider: {
      type: String,
      enum: ['github'],
      default: 'github'
    }
  },
  {
    timestamps: true
  }
);

module.exports = mongoose.model('User', UserSchema);
