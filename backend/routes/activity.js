const express = require('express');
const requireAuth = require('../middleware/requireAuth');
const RecentActivity = require('../models/RecentActivity');

const router = express.Router();

/**
 * CREATE ACTIVITY
 * - Adds a new activity
 * - Keeps only latest 10 per user
 * - Always preserves at least ONE repo_chat activity
 */
router.post('/', requireAuth, async (req, res) => {
  try {
    const { message, repoName, type } = req.body;
    const userId = req.user.userId;

    // 1️⃣ Create new activity
    await RecentActivity.create({
      userId,
      message,
      repoName,
      type,
    });

    // 2️⃣ Fetch all activities (newest first)
    const activities = await RecentActivity.find({ userId })
      .sort({ createdAt: -1 })
      .lean();

    // If within limit, nothing to delete
    if (activities.length <= 10) {
      return res.status(201).json({ success: true });
    }

    // 3️⃣ Identify repo_chat activities
    const chatActivities = activities.filter(
      a => a.type === 'repo_chat'
    );

    // 4️⃣ Candidates for deletion (oldest first)
    const deletionCandidates = [...activities]
      .reverse(); // oldest → newest

    const idsToDelete = [];

    for (const activity of deletionCandidates) {
      if (activities.length - idsToDelete.length <= 10) break;

      // ❌ If this is the ONLY repo_chat, skip deleting it
      if (
        activity.type === 'repo_chat' &&
        chatActivities.length === 1
      ) {
        continue;
      }

      idsToDelete.push(activity._id);

      // Track chat deletion
      if (activity.type === 'repo_chat') {
        chatActivities.pop();
      }
    }

    // 5️⃣ Delete selected activities
    if (idsToDelete.length > 0) {
      await RecentActivity.deleteMany({
        _id: { $in: idsToDelete },
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
