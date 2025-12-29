const express = require('express');
const Resume = require('../models/Resume');
const requireAuth = require('../middleware/requireAuth');

const router = express.Router();

/* ================= GET RESUME ================= */

router.get('/', requireAuth, async (req, res) => {
  try {
    const resume = await Resume.findOne({ userId: req.user.userId }).lean();
    res.json(resume || null);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch resume' });
  }
});

/* ================= SAVE / UPDATE RESUME ================= */

router.post('/', requireAuth, async (req, res) => {
  try {
    // Normalize education Percentage / grade field
    if (Array.isArray(req.body.education)) {
      req.body.education = req.body.education.map((edu) => ({
        ...edu,
        Percentage: edu.Percentage ?? edu.grade ?? '',
      }));
    }

    const resume = await Resume.findOneAndUpdate(
      { userId: req.user.userId },
      {
        ...req.body,
        userId: req.user.userId,
      },
      {
        upsert: true,
        new: true,
        runValidators: true,
        setDefaultsOnInsert: true,
      }
    );

    res.json({ success: true, resume });
  } catch (err) {
    res.status(500).json({ success: false });
  }
});

module.exports = router;
