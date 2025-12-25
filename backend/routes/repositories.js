const express = require('express');
const requireAuth = require('../middleware/requireAuth');
const Repository = require('../models/Repository');

const router = express.Router();

/**
 * TOGGLE FAVOURITE
 */
router.post('/:repoId/favourite', requireAuth, async (req, res) => {
  try {
    const repoId = Number(req.params.repoId);

    if (Number.isNaN(repoId)) {
      return res.status(400).json({ error: 'Invalid repoId' });
    }

    const userId = req.user.userId;

    // Check existing repository
    const existing = await Repository.findOne({ userId, repoId });

    if (existing) {
      existing.favourite = !existing.favourite;
      await existing.save();

      return res.json({
        success: true,
        action: 'toggled',
        favourite: existing.favourite,
        repo: existing,
      });
    }

    // Create new favourite
    const repo = req.body;

    if (!repo || !repo.name) {
      return res.status(400).json({ error: 'Invalid repo payload' });
    }

    const created = await Repository.create({
      userId,
      repoId,
      name: repo.name,
      fullName: repo.fullName,
      description: repo.description,
      private: repo.private,
      htmlUrl: repo.htmlUrl,
      favourite: true,
    });

    return res.json({
      success: true,
      action: 'created',
      favourite: true,
      repo: created,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Failed to toggle favourite',
      message: err.message,
    });
  }
});

/**
 * GET FAVOURITES
 */
router.get('/favourites', requireAuth, async (req, res) => {
  try {
    const repos = await Repository.find({
      userId: req.user.userId,
      favourite: true,
    }).sort({ updatedAt: -1 });

    res.json(repos);
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch favourites',
      message: err.message,
    });
  }
});

module.exports = router;
