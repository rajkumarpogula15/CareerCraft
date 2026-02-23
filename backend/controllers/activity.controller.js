const activityService = require('../services/activity.service');

const createActivity = async (req, res) => {
  try {
    const { message, repoName, type } = req.body;
    await activityService.createActivity({ userId: req.user.userId, message, repoName, type });
    return res.status(201).json({ success: true });
  } catch (err) {
    return res.status(500).json({ success: false });
  }
};

const getRecent = async (req, res) => {
  try {
    const activities = await activityService.getRecentActivities(req.user.userId);
    return res.status(200).json(activities);
  } catch (err) {
    return res.status(500).json([]);
  }
};

module.exports = {
  createActivity,
  getRecent,
};
