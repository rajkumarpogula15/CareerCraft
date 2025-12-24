const express = require('express');
const axios = require('axios');

const router = express.Router();

let loggedIn = false;
let githubToken = null;

router.get('/login', (req, res) => {
  const githubUrl =
    `https://github.com/login/oauth/authorize` +
    `?client_id=${process.env.GITHUB_CLIENT_ID}` +
    `&scope=read:user repo`;

  res.redirect(githubUrl);
});

router.get('/callback', async (req, res) => {
  const { code } = req.query;

  try {
    const tokenRes = await axios.post(
      'https://github.com/login/oauth/access_token',
      {
        client_id: process.env.GITHUB_CLIENT_ID,
        client_secret: process.env.GITHUB_CLIENT_SECRET,
        code,
      },
      { headers: { Accept: 'application/json' } }
    );

    githubToken = tokenRes.data.access_token;
    loggedIn = true;

    // 🔥 REDIRECT BACK TO FLUTTER APP
    res.redirect('careercraft://login-success');

  } catch (err) {
    res.status(500).send('GitHub login failed');
  }
});

router.get('/status', (req, res) => {
  res.json({ loggedIn });
});

router.get('/repos', async (req, res) => {
  if (!githubToken) {
    return res.status(401).json({ error: 'Not authenticated' });
  }

  try {
    const reposRes = await axios.get(
      'https://api.github.com/user/repos',
      {
        headers: {
          Authorization: `token ${githubToken}`,
          Accept: 'application/vnd.github+json',
        },
        params: {
          sort: 'updated',
          per_page: 50,
        },
      }
    );

    const repos = reposRes.data.map(repo => ({
      id: repo.id,
      name: repo.name,
      full_name: repo.full_name,
      private: repo.private,
      description: repo.description,
      html_url: repo.html_url,
    }));

    res.json(repos);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch repositories' });
  }
});

router.get('/profile', async (req, res) => {
  if (!githubToken) {
    return res.status(401).json({ error: 'Not authenticated' });
  }

  try {
    const userRes = await axios.get(
      'https://api.github.com/user',
      {
        headers: {
          Authorization: `token ${githubToken}`,
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
  } catch (e) {
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});



module.exports = router;
