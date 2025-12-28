const express = require('express');
const Resume = require('../models/Resume');
const requireAuth = require('../middleware/requireAuth');

const router = express.Router();

/**
 * GET SAVED RESUME
 */
router.get('/', requireAuth, async (req, res) => {
  const resume = await Resume.findOne({ userId: req.user.userId });
  res.json(resume || null);
});

/**
 * CREATE / UPDATE RESUME
 */
router.post('/', requireAuth, async (req, res) => {
  const resume = await Resume.findOneAndUpdate(
    { userId: req.user.userId },
    { ...req.body, userId: req.user.userId },
    { upsert: true, new: true }
  );

  res.json({ success: true, resume });
});

module.exports = router;
