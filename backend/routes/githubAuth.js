const express = require('express');
const axios = require('axios');
const jwt = require('jsonwebtoken');

const User = require('../models/User');

const router = express.Router();

/**
 * ================================
 * STEP 1: Redirect to GitHub OAuth
 * ================================
 */
router.get('/login', (req, res) => {
  try {
    console.log('\n===== 🔐 GITHUB LOGIN STARTED =====');

    console.log('🌐 FULL REQUEST URL:', req.originalUrl);
    console.log('📡 Protocol:', req.protocol);
    console.log('🏠 Host:', req.get('host'));
    console.log('🔁 X-Forwarded-Proto:', req.headers['x-forwarded-proto']);
    console.log('🔁 X-Forwarded-Host:', req.headers['x-forwarded-host']);

    if (!process.env.GITHUB_CLIENT_ID) {
      console.error('❌ GITHUB_CLIENT_ID missing!');
      return res.status(500).json({
        error: 'GitHub Client ID not configured',
      });
    }

    // 🔥 FIX: Handle Render proxy (IMPORTANT)
    const protocol = req.headers['x-forwarded-proto'] || req.protocol;
    const host = req.headers['x-forwarded-host'] || req.get('host');

    const redirectUri = `${protocol}://${host}/auth/github/callback`;

    console.log('🚨 FINAL REDIRECT URI:', redirectUri);

    const githubUrl =
      'https://github.com/login/oauth/authorize' +
      `?client_id=${process.env.GITHUB_CLIENT_ID}` +
      `&redirect_uri=${encodeURIComponent(redirectUri)}` +
      '&scope=read:user repo';

    console.log('✅ GitHub URL:', githubUrl);
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
    // 🔥 FIX: Handle Render proxy again
    const protocol = req.headers['x-forwarded-proto'] || req.protocol;
    const host = req.headers['x-forwarded-host'] || req.get('host');

    const redirectUri = `${protocol}://${host}/auth/github/callback`;

    console.log('🔁 CALLBACK REDIRECT URI:', redirectUri);

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
        redirect_uri: redirectUri,
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
     * 💾 SAVE USER
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

module.exports = router;