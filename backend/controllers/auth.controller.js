const authService = require('../services/auth.service');

const login = (req, res) => {
  try {
    const githubUrl = authService.getGithubLoginUrl();
    res.redirect(githubUrl);
  } catch (error) {
    res.status(500).json({ error: 'Failed to start GitHub auth', details: error.message });
  }
};

const callback = async (req, res) => {
  const { code } = req.query;
  if (!code) {
    return res.status(400).send('Missing code');
  }

  try {
    const { jwtToken } = await authService.loginWithGithubCode(code);
    res.redirect(`careercraft://login-success?token=${jwtToken}`);
  } catch (err) {
    res.status(err.status || 500).send('GitHub login failed');
  }
};

const getRepos = async (req, res) => {
  try {
    const repos = await authService.fetchReposForUser(req.user.userId);
    res.json(repos);
  } catch (err) {
    res.status(err.status || 500).json({ error: err.message || 'Failed to fetch repos' });
  }
};

const getProfile = async (req, res) => {
  try {
    const profile = await authService.fetchProfile(req.user.userId);
    res.json(profile);
  } catch (err) {
    res.status(err.status || 500).json({ error: err.message || 'Failed to fetch profile' });
  }
};

module.exports = {
  login,
  callback,
  getRepos,
  getProfile,
};
