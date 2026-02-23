const RepoSummary = require('../models/RepoSummary');
const InterviewSession = require('../models/InterviewSession');

const findRepoSummary = (userId, repoId) => RepoSummary.findOne({ userId, repoId });

const upsertRepoSummary = (userId, repoId, payload) =>
  RepoSummary.findOneAndUpdate({ userId, repoId }, { userId, repoId, ...payload }, { upsert: true, new: true });

const findRepoSummariesByRepoIds = (userId, repoIds) =>
  RepoSummary.find({ userId, repoId: { $in: repoIds } });

const createInterviewSession = payload => InterviewSession.create(payload);

const findInterviewById = id => InterviewSession.findById(id);

const findInterviewForUser = (id, userId) => InterviewSession.findOne({ _id: id, userId });

const findInterviewHistory = userId =>
  InterviewSession.find({ userId, status: 'completed' })
    .select('difficulty completedAt finalResult repos')
    .sort({ completedAt: -1 });

module.exports = {
  findRepoSummary,
  upsertRepoSummary,
  findRepoSummariesByRepoIds,
  createInterviewSession,
  findInterviewById,
  findInterviewForUser,
  findInterviewHistory,
};
