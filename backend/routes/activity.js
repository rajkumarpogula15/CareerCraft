const express = require('express');
const requireAuth = require('../middleware/requireAuth');
const activityController = require('../controllers/activity.controller');

const router = express.Router();

router.post('/', requireAuth, activityController.createActivity);
router.get('/recent', requireAuth, activityController.getRecent);

module.exports = router;
