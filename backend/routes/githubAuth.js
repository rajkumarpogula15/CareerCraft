const express = require('express');
const axios = require('axios');

const router = express.Router();

const User = require('../models/User');
const Repository = require('../models/Repository');

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

  if (!code) {
    return res.status(400).send('Missing OAuth code');
  }

  try {
    /**
     * Exchange code for access token
     */
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

    const accessToken = tokenRes.data.access_token;

    if (!accessToken) {
      return res.status(401).send('Failed to obtain access token');
    }

    /**
     * Fetch GitHub user profile
     */
    const userRes = await axios.get('https://api.github.com/user', {
      headers: {
        Authorization: `token ${accessToken}`,
        Accept: 'application/vnd.github+json',
      },
    });

    const githubUser = userRes.data;

    /**
     * Create or update user in DB
     */
    let user = await User.findOne({ githubId: githubUser.id });

    if (!user) {
      user = await User.create({
        githubId: githubUser.id,
        username: githubUser.login,
        name: githubUser.name,
        avatar: githubUser.avatar_url,
        accessToken,
      });
    } else {
      user.accessToken = accessToken;
      user.username = githubUser.login;
      user.name = githubUser.name;
      user.avatar = githubUser.avatar_url;
      await user.save();
    }

    /**
     * Save session
     */
    req.session.userId = user._id;

    /**
     * Redirect back to Flutter app
     */
    res.redirect('careercraft://login-success');
  } catch (err) {
    console.error(err);
    res.status(500).send('GitHub login failed');
  }
});

/**
 * Check login status
 */
router.get('/status', (req, res) => {
  res.json({ loggedIn: !!req.session.userId });
});

/**
 * Fetch GitHub Repositories
 */
router.get('/repos', async (req, res) => {
  if (!req.session.userId) {
    return res.status(401).json({ error: 'Not authenticated' });
  }

  try {
    const user = await User.findById(req.session.userId);

    const reposRes = await axios.get(
      'https://api.github.com/user/repos',
      {
        headers: {
          Authorization: `token ${user.accessToken}`,
          Accept: 'application/vnd.github+json',
        },
        params: {
          sort: 'updated',
          per_page: 50,
        },
      }
    );

    /**
     * Save/update repos in DB
     */
    for (const repo of reposRes.data) {
      await Repository.findOneAndUpdate(
        { repoId: repo.id, userId: user._id },
        {
          userId: user._id,
          repoId: repo.id,
          name: repo.name,
          fullName: repo.full_name,
          description: repo.description,
          private: repo.private,
          htmlUrl: repo.html_url,
          updatedAt: new Date(),
        },
        { upsert: true }
      );
    }

    /**
     * Send clean response
     */
    res.json(
      reposRes.data.map(repo => ({
        id: repo.id,
        name: repo.name,
        full_name: repo.full_name,
        private: repo.private,
        description: repo.description,
        html_url: repo.html_url,
      }))
    );
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch repositories' });
  }
});

/**
 * Fetch GitHub Profile
 */
router.get('/profile', async (req, res) => {
  if (!req.session.userId) {
    return res.status(401).json({ error: 'Not authenticated' });
  }

  try {
    const user = await User.findById(req.session.userId);

    const userRes = await axios.get(
      'https://api.github.com/user',
      {
        headers: {
          Authorization: `token ${user.accessToken}`,
          Accept: 'application/vnd.github+json',
        },
      }
    );

    res.json({
      name: userRes.data.name,
      username: userRes.data.login,
      avatar: userRes.data.avatar_url,
      bio: userRes.data.bio,
      followers: userRes.data.followers,
      following: userRes.data.following,
      public_repos: userRes.data.public_repos,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

module.exports = router;
