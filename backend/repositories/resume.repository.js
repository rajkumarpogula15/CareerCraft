const Resume = require('../models/Resume');

const findByUserId = userId => Resume.findOne({ userId }).lean();

const upsertByUserId = (userId, payload) =>
  Resume.findOneAndUpdate(
    { userId },
    { ...payload, userId },
    { upsert: true, new: true, runValidators: true, setDefaultsOnInsert: true }
  );

module.exports = {
  findByUserId,
  upsertByUserId,
};
