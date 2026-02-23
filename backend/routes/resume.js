const express = require('express');
const requireAuth = require('../middleware/requireAuth');
const resumeController = require('../controllers/resume.controller');

const router = express.Router();

router.get('/', requireAuth, resumeController.getResume);
router.post('/', requireAuth, resumeController.saveResume);

module.exports = router;
