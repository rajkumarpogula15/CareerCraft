const express = require('express');
const requireAuth = require('../middleware/requireAuth');
const aiController = require('../controllers/ai.controller');

const router = express.Router();

router.post('/generate', requireAuth, aiController.generateReadme);
router.post('/generate-social-post', requireAuth, aiController.generateSocialPost);
router.post('/generate-resume-points', requireAuth, aiController.generateResumePoints);

module.exports = router;
