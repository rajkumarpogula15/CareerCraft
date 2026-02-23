const express = require('express');
const requireAuth = require('../middleware/requireAuth');
const chatController = require('../controllers/chat.controller');

const router = express.Router();

router.post('/session', requireAuth, chatController.createSession);
router.post('/message', requireAuth, chatController.sendMessage);
router.get('/history/:sessionId', requireAuth, chatController.getHistory);

module.exports = router;
