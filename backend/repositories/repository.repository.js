const Repository = require('../models/Repository');

const findByUserAndRepoId = (userId, repoId) => Repository.findOne({ userId, repoId });

const create = payload => Repository.create(payload);

const findFavouritesByUser = userId =>
  Repository.find({ userId, favourite: true }).sort({ updatedAt: -1 });

module.exports = {
  findByUserAndRepoId,
  create,
  findFavouritesByUser,
};
