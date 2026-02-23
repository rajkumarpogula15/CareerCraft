const express = require('express');
const requireAuth = require('../middleware/requireAuth');
const interviewController = require('../controllers/interview.controller');

const router = express.Router();

router.post('/summarize-repos', requireAuth, interviewController.summarizeRepos);
router.post('/start', requireAuth, interviewController.startInterview);
router.post('/:sessionId/first-question', requireAuth, interviewController.firstQuestion);
router.post('/:sessionId/answer', requireAuth, interviewController.answerQuestion);
router.post('/:sessionId/final-analysis', requireAuth, interviewController.finalAnalysis);
router.get('/history', requireAuth, interviewController.history);
router.get('/:sessionId', requireAuth, interviewController.getSession);

module.exports = router;
