const express = require('express');
const axios = require('axios');
const jwt = require('jsonwebtoken');

const User = require('../models/User');
const requireAuth = require('../middleware/requireAuth');

const router = express.Router();

/**
 * ================================
 * STEP 1: Redirect to GitHub OAuth
 * ================================
 */
router.get('/login', (req, res) => {
  try {
    console.log('\n===== 🔐 GITHUB LOGIN STARTED =====');

    console.log('🔍 Client ID:', process.env.GITHUB_CLIENT_ID);
    console.log('🔍 Redirect From:', req.ip);

    if (!process.env.GITHUB_CLIENT_ID) {
      console.error('❌ GITHUB_CLIENT_ID missing!');
      return res.status(500).json({
        error: 'GitHub Client ID not configured',
      });
    }

    const githubUrl =
      'https://github.com/login/oauth/authorize' +
      `?client_id=${process.env.GITHUB_CLIENT_ID}` +
      '&scope=read:user repo';

    console.log('✅ OAuth URL:', githubUrl);
    console.log('➡️ Redirecting to GitHub...\n');

    res.redirect(githubUrl);
  } catch (error) {
    console.error('🔥 LOGIN ERROR:', error);

    res.status(500).json({
      error: 'Failed to start GitHub auth',
      details: error.message,
    });
  }
});

/**
 * ================================
 * STEP 2: GitHub OAuth Callback
 * ================================
 */
router.get('/callback', async (req, res) => {
  console.log('\n===== 🔁 GITHUB CALLBACK HIT =====');

  const { code } = req.query;

  console.log('📩 Received Code:', code);

  if (!code) {
    console.error('❌ Code Missing');
    return res.status(400).send('Missing code');
  }

  try {
    /**
     * 🔑 EXCHANGE CODE FOR TOKEN
     */
    console.log('🔄 Exchanging code for token...');

    const tokenRes = await axios.post(
      'https://github.com/login/oauth/access_token',
      {
        client_id: process.env.GITHUB_CLIENT_ID,
        client_secret: process.env.GITHUB_CLIENT_SECRET,
        code,
      },
      {
        headers: { Accept: 'application/json' },
      }
    );

    console.log('✅ Token Response:', tokenRes.data);

    const accessToken = tokenRes.data.access_token;

    if (!accessToken) {
      console.error('❌ No Access Token');
      return res.status(401).send('No access token');
    }

    console.log('🔑 Access Token Received');

    /**
     * 👤 FETCH USER DATA
     */
    console.log('📡 Fetching GitHub User...');

    const ghUserRes = await axios.get(
      'https://api.github.com/user',
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
          Accept: 'application/vnd.github+json',
        },
      }
    );

    const gh = ghUserRes.data;

    console.log('✅ GitHub User:', {
      id: gh.id,
      username: gh.login,
      email: gh.email,
    });

    /**
     * 💾 SAVE TO DATABASE
     */
    console.log('💾 Saving User to DB...');

    const user = await User.findOneAndUpdate(
      { githubId: gh.id },
      {
        githubId: gh.id,
        username: gh.login,
        name: gh.name,
        avatar: gh.avatar_url,
        email: gh.email,

        public_repos: gh.public_repos,
        followers: gh.followers,
        following: gh.following,

        githubAccessToken: accessToken,
      },
      {
        upsert: true,
        new: true,
      }
    );

    console.log('✅ User Saved:', user._id);

    /**
     * 🔐 CREATE JWT
     */
    console.log('🔐 Creating JWT...');

    if (!process.env.JWT_SECRET) {
      console.error('❌ JWT_SECRET Missing!');
      return res.status(500).send('JWT Secret missing');
    }

    const jwtToken = jwt.sign(
      { userId: user._id },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    console.log('✅ JWT Created');

    /**
     * 📱 REDIRECT TO APP
     */
    const redirectUrl = `careercraft://login-success?token=${jwtToken}`;

    console.log('📲 Redirecting to App:', redirectUrl);
    console.log('===== ✅ LOGIN COMPLETE =====\n');

    res.redirect(redirectUrl);
  } catch (err) {
    console.error('🔥 CALLBACK ERROR:', err.response?.data || err.message);

    res.status(500).send('GitHub login failed');
  }
});

/**
 * ================================
 * FETCH REPOSITORIES
 * ================================
 */
router.get('/repos', requireAuth, async (req, res) => {
  console.log('\n===== 📦 FETCHING REPOS =====');

  try {
    console.log('👤 User ID:', req.user.userId);

    const user = await User.findById(req.user.userId);

    if (!user) {
      console.error('❌ User Not Found');
      return res.status(404).json({ error: 'User not found' });
    }

    console.log('✅ User Found:', user.username);

    console.log('📡 Calling GitHub Repos API...');

    const reposRes = await axios.get(
      'https://api.github.com/user/repos',
      {
        headers: {
          Authorization: `Bearer ${user.githubAccessToken}`,
          Accept: 'application/vnd.github+json',
        },
        params: {
          per_page: 50,
          sort: 'updated',
        },
      }
    );

    console.log('✅ Repo Count:', reposRes.data.length);

    const repos = reposRes.data.map(repo => ({
      id: repo.id,
      name: repo.name,
      description: repo.description,
      private: repo.private,
      html_url: repo.html_url,

      updated_at: repo.updated_at,

      has_readme: !!repo.has_wiki || !!repo.description,
    }));

    console.log('📤 Sending Repos');

    res.json(repos);
  } catch (err) {
    console.error('🔥 REPO ERROR:', err.response?.data || err.message);

    res.status(500).json({ error: 'Failed to fetch repos' });
  }
});

/**
 * ================================
 * FETCH PROFILE
 * ================================
 */
router.get('/profile', requireAuth, async (req, res) => {
  console.log('\n===== 👤 FETCH PROFILE =====');

  try {
    console.log('👤 User ID:', req.user.userId);

    const user = await User.findById(req.user.userId).select(
      'username name avatar email public_repos followers following'
    );

    if (!user) {
      console.error('❌ User Not Found');
      return res.status(404).json({ error: 'User not found' });
    }

    console.log('✅ Profile Found:', user.username);

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
    console.error('🔥 PROFILE ERROR:', err.response?.data || err.message);

    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

module.exports = router;