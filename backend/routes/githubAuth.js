const express = require('express');
const axios = require('axios');
const jwt = require('jsonwebtoken');

const User = require('../models/User');
const requireAuth = require('../middleware/requireAuth');

const router = express.Router();

/**
 * STEP 1: Redirect to GitHub OAuth
 */
router.get('/login', (req, res) => {
  const githubUrl =
    'https://github.com/login/oauth/authorize' +
    `?client_id=${process.env.GITHUB_CLIENT_ID}` +
    '&scope=read:user repo';

  res.redirect(githubUrl);
});

/**
 * STEP 2: GitHub OAuth Callback
 */
router.get('/callback', async (req, res) => {
  const { code } = req.query;
  if (!code) return res.status(400).send('Missing code');

  try {
    // 🔑 Exchange code for access token
    const tokenRes = await axios.post(
      'https://github.com/login/oauth/access_token',
      {
        client_id: process.env.GITHUB_CLIENT_ID,
        client_secret: process.env.GITHUB_CLIENT_SECRET,
        code,
      },
      { headers: { Accept: 'application/json' } }
    );

    const accessToken = tokenRes.data.access_token;
    if (!accessToken) return res.status(401).send('No access token');

    // 👤 Fetch GitHub user profile
    const ghUserRes = await axios.get('https://api.github.com/user', {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        Accept: 'application/vnd.github+json',
      },
    });

    const gh = ghUserRes.data;

    // ✅ CREATE OR UPDATE USER (IMPORTANT FIX)
    const user = await User.findOneAndUpdate(
      { githubId: gh.id },
      {
        githubId: gh.id,
        username: gh.login,
        name: gh.name,
        avatar: gh.avatar_url,
        email: gh.email,

        // 🔥 GitHub stats (THIS FIXES 0 FOLLOWERS ISSUE)
        public_repos: gh.public_repos,
        followers: gh.followers,
        following: gh.following,

        githubAccessToken: accessToken,
      },
      { upsert: true, new: true }
    );

    // 🔐 Create JWT for app auth
    const jwtToken = jwt.sign(
      { userId: user._id },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    // 📱 Deep link back to Flutter app
    res.redirect(`careercraft://login-success?token=${jwtToken}`);
    // res.json({ jwt: jwtToken });

  } catch (err) {
    console.error('GitHub OAuth error:', err);
    res.status(500).send('GitHub login failed');
  }
});

/**
 * FETCH REPOSITORIES (JWT + GitHub)
 */
router.get('/repos', requireAuth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ error: 'User not found' });

    const reposRes = await axios.get('https://api.github.com/user/repos', {
      headers: {
        Authorization: `Bearer ${user.githubAccessToken}`,
        Accept: 'application/vnd.github+json',
      },
      params: { per_page: 50, sort: 'updated' },
    });

    res.json(
      reposRes.data.map(repo => ({
        id: repo.id,
        name: repo.name,
        description: repo.description,
        private: repo.private,
        html_url: repo.html_url,
      }))
    );
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch repos' });
  }
});

/**
 * FETCH PROFILE (JWT + DB)
 */
router.get('/profile', requireAuth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).select(
      'username name avatar email public_repos followers following'
    );

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      username: user.username,
      name: user.name,
      avatar: user.avatar,
      email: user.email,
      public_repos: user.public_repos,
      followers: user.followers,
      following: user.following,
    });
  } catch (err) {
    console.error('Profile fetch error:', err);
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

module.exports = router;
