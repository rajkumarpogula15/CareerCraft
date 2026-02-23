const User = require('../models/User');

const findById = userId => User.findById(userId);

const upsertGithubUser = (githubId, payload) =>
  User.findOneAndUpdate({ githubId }, payload, { upsert: true, new: true });

const findProfileById = userId =>
  User.findById(userId).select(
    'username name avatar email public_repos followers following'
  );

module.exports = {
  findById,
  upsertGithubUser,
  findProfileById,
};
