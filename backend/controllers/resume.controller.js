const resumeService = require('../services/resume.service');

const getResume = async (req, res) => {
  try {
    const resume = await resumeService.getResume(req.user.userId);
    res.json(resume || null);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch resume' });
  }
};

const saveResume = async (req, res) => {
  try {
    const resume = await resumeService.saveResume(req.user.userId, req.body);
    res.json({ success: true, resume });
  } catch (err) {
    res.status(500).json({ success: false });
  }
};

module.exports = {
  getResume,
  saveResume,
};
