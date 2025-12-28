const mongoose = require('mongoose');

const ProjectSchema = new mongoose.Schema({
  repoName: String,
  included: Boolean,
  bulletPoints: [String],
});

const ResumeSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      unique: true,
      required: true,
    },

    profile: {
      name: String,
      email: String,
      avatar: String,
      username: String,
      phone: String,
      location: String,
      linkedin: String,
      portfolio: String,
    },

    skills: [String],

    education: [
      {
        degree: String,
        institution: String,
        year: String,
      },
    ],

    projects: [ProjectSchema],
  },
  { timestamps: true }
);

module.exports = mongoose.model('Resume', ResumeSchema);
