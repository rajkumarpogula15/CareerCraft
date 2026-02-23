const repositoryService = require('../services/repository.service');

const addFavourite = async (req, res) => {
  try {
    const repoId = Number(req.params.repoId);
    if (Number.isNaN(repoId)) {
      return res.status(400).json({ error: 'Invalid repoId' });
    }

    const repoPayload = req.body;
    if (!repoPayload || !repoPayload.name) {
      return res.status(400).json({ error: 'Invalid repo payload' });
    }

    const result = await repositoryService.addFavourite({
      userId: req.user.userId,
      repoId,
      repoPayload,
    });

    res.json({ success: true, ...result });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to add favourite', message: err.message });
  }
};

const removeFavourite = async (req, res) => {
  try {
    const repoId = Number(req.params.repoId);
    if (Number.isNaN(repoId)) {
      return res.status(400).json({ error: 'Invalid repoId' });
    }

    const result = await repositoryService.removeFavourite({ userId: req.user.userId, repoId });
    res.json({ success: true, ...result });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to remove favourite', message: err.message });
  }
};

const getFavourites = async (req, res) => {
  try {
    const repos = await repositoryService.listFavourites(req.user.userId);
    res.json(repos);
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to fetch favourites', message: err.message });
  }
};

module.exports = { addFavourite, removeFavourite, getFavourites };
