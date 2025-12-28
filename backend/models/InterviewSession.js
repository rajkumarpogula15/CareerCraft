const mongoose = require('mongoose');

const InterviewSessionSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    repos: [
      {
        repoId: Number,
        repoName: String,
      },
    ],

    difficulty: {
      type: String,
      enum: ['easy', 'medium', 'hard'],
      required: true,
    },

    status: {
      type: String,
      enum: ['created', 'in_progress', 'completed'],
      default: 'created',
    },

    currentQuestionIndex: {
      type: Number,
      default: 0,
    },

    questions: [
      {
        index: Number,
        text: String,
        repoName: String,
        topic: String,
      },
    ],

    answers: [
      {
        index: Number,
        text: String,
      },
    ],

    evaluations: [
      {
        index: Number,
        correctness: String,
        clarity: String,
        notes: String,
      },
    ],

    finalResult: {
      overallScore: Number,
      strengths: [String],
      weaknesses: [String],
      improvements: [String],
      suggestedDifficulty: String,
    },

    startedAt: Date,
    completedAt: Date,
  },
  { timestamps: true }
);

module.exports = mongoose.model('InterviewSession', InterviewSessionSchema);
