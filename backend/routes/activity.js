const express = require('express');
const requireAuth = require('../middleware/requireAuth');
const RecentActivity = require('../models/RecentActivity');

const router = express.Router();

/**
 * CREATE ACTIVITY
 * - Adds a new activity
 * - Keeps only latest 10 activities per user
 */
router.post('/', requireAuth, async (req, res) => {
  try {
    const { message, repoName, type } = req.body;

    // 1️⃣ Create new activity
    await RecentActivity.create({
      userId: req.user.userId,
      message,
      repoName,
      type,
    });

    // 2️⃣ Find activities exceeding the latest 10
    const oldActivities = await RecentActivity.find({
      userId: req.user.userId,
    })
      .sort({ createdAt: -1 })
      .skip(10) // everything after the 10 newest
      .select('_id');

    // 3️⃣ Delete old activities
    if (oldActivities.length > 0) {
      await RecentActivity.deleteMany({
        _id: { $in: oldActivities.map(a => a._id) },
      });
    }

    return res.status(201).json({ success: true });
  } catch (err) {
    console.error('[ACTIVITY CREATE ERROR]', err);
    return res.status(500).json({ success: false });
  }
});

/**
 * GET RECENT ACTIVITIES
 * Returns last 5 activities for authenticated user
 */
router.get('/recent', requireAuth, async (req, res) => {
  try {
    const activities = await RecentActivity.find({
      userId: req.user.userId,
    })
      .sort({ createdAt: -1 })
      .limit(5)
      .select('message repoName type createdAt')
      .lean();

    return res.status(200).json(activities);
  } catch (err) {
    console.error('[ACTIVITY FETCH ERROR]', err);
    return res.status(500).json([]);
  }
});

module.exports = router;
