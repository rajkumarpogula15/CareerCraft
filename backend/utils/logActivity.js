const RecentActivity = require('../models/RecentActivity');

const logActivity = async ({ userId, type, repoName, message }) => {
  try {
    await RecentActivity.create({
      userId,
      type,
      repoName,
      message,
    });
  } catch (err) {
    console.error('[ACTIVITY LOG ERROR]', err);
  }
};

module.exports = logActivity;
