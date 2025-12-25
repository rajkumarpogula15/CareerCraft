const express = require('express');
const requireAuth = require('../middleware/requireAuth');
const Repository = require('../models/Repository');
const logActivity = require('../utils/logActivity');

const router = express.Router();

/**
 * ADD TO FAVOURITES
 * POST /:repoId/favourite
 */
router.post('/:repoId/favourite', requireAuth, async (req, res) => {
  try {
    const repoId = Number(req.params.repoId);

    if (Number.isNaN(repoId)) {
      return res.status(400).json({ error: 'Invalid repoId' });
    }

    const userId = req.user.userId;
    const repoPayload = req.body;

    if (!repoPayload || !repoPayload.name) {
      return res.status(400).json({ error: 'Invalid repo payload' });
    }

    let repo = await Repository.findOne({ userId, repoId });

    // If repo exists, just mark as favourite
    if (repo) {
      if (repo.favourite) {
        return res.json({
          success: true,
          action: 'already_favourite',
          favourite: true,
          repo,
        });
      }

      repo.favourite = true;
      await repo.save();
    } else {
      // Create repo and favourite it
      repo = await Repository.create({
        userId,
        repoId,
        name: repoPayload.name,
        fullName: repoPayload.fullName,
        description: repoPayload.description,
        private: repoPayload.private,
        htmlUrl: repoPayload.htmlUrl,
        favourite: true,
      });
    }

    await logActivity({
      userId,
      type: 'repo_favourite',
      repoName: repo.name,
      message: `Marked ${repo.name} as favourite`,
    });

    res.json({
      success: true,
      action: 'added',
      favourite: true,
      repo,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Failed to add favourite',
      message: err.message,
    });
  }
});

/**
 * REMOVE FROM FAVOURITES
 * DELETE /:repoId/favourite
 */
router.delete('/:repoId/favourite', requireAuth, async (req, res) => {
  try {
    const repoId = Number(req.params.repoId);

    if (Number.isNaN(repoId)) {
      return res.status(400).json({ error: 'Invalid repoId' });
    }

    const userId = req.user.userId;

    const repo = await Repository.findOne({ userId, repoId });

    if (!repo || !repo.favourite) {
      return res.json({
        success: true,
        action: 'already_removed',
        favourite: false,
      });
    }

    repo.favourite = false;
    await repo.save();

    await logActivity({
      userId,
      type: 'repo_favourite',
      repoName: repo.name,
      message: `Removed ${repo.name} from favourites`,
    });

    res.json({
      success: true,
      action: 'removed',
      favourite: false,
      repo,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Failed to remove favourite',
      message: err.message,
    });
  }
});

/**
 * GET FAVOURITES
 * GET /favourites
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
