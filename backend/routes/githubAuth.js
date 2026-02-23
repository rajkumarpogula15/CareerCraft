const express = require('express');
const requireAuth = require('../middleware/requireAuth');
const authController = require('../controllers/auth.controller');

const router = express.Router();

router.get('/login', authController.login);
router.get('/callback', authController.callback);
router.get('/repos', requireAuth, authController.getRepos);
router.get('/profile', requireAuth, authController.getProfile);

module.exports = router;
