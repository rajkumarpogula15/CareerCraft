const aiContentService = require('../services/aiContent.service');

const generateReadme = async (req, res) => {
  const { repoName, description, language } = req.body;
  if (!repoName) {
    return res.status(400).json({ message: 'repoName is required' });
  }

  try {
    const result = await aiContentService.generateReadme({
      userId: req.user.userId,
      repoName,
      description,
      language,
    });

    res.json(result);
  } catch (err) {
    res.status(err.status || 500).json({ message: err.message || 'Failed to generate README' });
  }
};

const generateSocialPost = async (req, res) => {
  const { repoName, platform = 'LinkedIn' } = req.body;
  if (!repoName) {
    return res.status(400).json({ message: 'repoName is required' });
  }

  try {
    const result = await aiContentService.generateSocialPost({
      userId: req.user.userId,
      repoName,
      platform,
    });

    res.json(result);
  } catch (err) {
    res.status(err.status || 500).json({
      message:
        err.status === 429
          ? 'AI service is busy. Please try again shortly.'
          : err.message || 'Failed to generate social post',
    });
  }
};

const generateResumePoints = async (req, res) => {
  const { repoName } = req.body;
  if (!repoName) {
    return res.status(400).json({ message: 'repoName is required' });
  }

  try {
    const result = await aiContentService.generateResumePoints({
      userId: req.user.userId,
      repoName,
    });

    res.json(result);
  } catch (err) {
    res.status(err.status || 500).json({
      message:
        err.status === 429
          ? 'AI service is busy. Please try again shortly.'
          : err.message || 'Failed to generate resume points',
    });
  }
};

module.exports = {
  generateReadme,
  generateSocialPost,
  generateResumePoints,
};
