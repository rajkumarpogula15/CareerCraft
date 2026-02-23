const RecentActivity = require('../models/RecentActivity');

const create = payload => RecentActivity.create(payload);

const findByUserSorted = userId =>
  RecentActivity.find({ userId }).sort({ createdAt: -1 }).lean();

const deleteManyByIds = ids => RecentActivity.deleteMany({ _id: { $in: ids } });

const findRecentByUser = (userId, limit = 5) =>
  RecentActivity.find({ userId })
    .sort({ createdAt: -1 })
    .limit(limit)
    .select('message repoName type createdAt')
    .lean();

module.exports = {
  create,
  findByUserSorted,
  deleteManyByIds,
  findRecentByUser,
};
