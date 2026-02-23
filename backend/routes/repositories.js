const express = require('express');
const requireAuth = require('../middleware/requireAuth');
const repositoryController = require('../controllers/repository.controller');

const router = express.Router();

router.post('/:repoId/favourite', requireAuth, repositoryController.addFavourite);
router.delete('/:repoId/favourite', requireAuth, repositoryController.removeFavourite);
router.get('/favourites', requireAuth, repositoryController.getFavourites);

module.exports = router;
