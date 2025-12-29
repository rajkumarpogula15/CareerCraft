const mongoose = require('mongoose');

/* ================= SUB SCHEMAS ================= */

const ProjectSchema = new mongoose.Schema({
  repoName: String,
  included: Boolean,
  bulletPoints: [String],
});

const ExperienceSchema = new mongoose.Schema({
  role: String,
  company: String,
  duration: String,
  description: String,
});

const EducationSchema = new mongoose.Schema({
  degree: String,
  institution: String,
  year: String,
  Percentage: String, // FINAL field name
});

/* ================= MAIN SCHEMA ================= */

const ResumeSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      unique: true,
      required: true,
      index: true,
    },

    profile: {
      name: String,
      title: String, // professional title
      email: String,
      avatar: String,
      username: String,
      phone: String,
      location: String,
      linkedin: String,
      portfolio: String,
    },

    summary: String,

    skills: { type: [String], default: [] },

    education: { type: [EducationSchema], default: [] },

    experience: { type: [ExperienceSchema], default: [] },

    achievements: { type: [String], default: [] },

    projects: { type: [ProjectSchema], default: [] },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Resume', ResumeSchema);
