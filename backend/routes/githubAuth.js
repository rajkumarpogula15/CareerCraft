const express = require('express');
const axios = require('axios');
const jwt = require('jsonwebtoken');

const User = require('../models/User');
const ChatSession = require('../models/ChatSession');
const InterviewSession = require('../models/InterviewSession');
const RepoSummary = require('../models/RepoSummary');
const requireAuth = require('../middleware/requireAuth');

const router = express.Router();

/**
 * ================================
 * HELPER FUNCTIONS
 * ================================
 */
function startOfUtcDay(date) {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
}

function dayDiffUtc(a, b) {
  const ms = startOfUtcDay(a).getTime() - startOfUtcDay(b).getTime();
  return Math.round(ms / (24 * 60 * 60 * 1000));
}

function normalizeSkillMap(skillMap = {}) {
  return {
    java: Math.max(0, Math.min(100, Math.round(skillMap.java ?? 0))),
    dsa: Math.max(0, Math.min(100, Math.round(skillMap.dsa ?? 0))),
    systemDesign: Math.max(0, Math.min(100, Math.round(skillMap.systemDesign ?? 0))),
    fullStack: Math.max(0, Math.min(100, Math.round(skillMap.fullStack ?? 0))),
    aiMl: Math.max(0, Math.min(100, Math.round(skillMap.aiMl ?? 0))),
  };
}

function computeSkillProgress(summaries = []) {
  const scores = {
    java: 0,
    dsa: 0,
    systemDesign: 0,
    fullStack: 0,
    aiMl: 0,
  };

  for (const summary of summaries) {
    const stack = (summary.techStack || []).map(v => String(v).toLowerCase());
    const features = (summary.keyFeatures || []).join(' ').toLowerCase();
    const arch = (summary.architectureHints || []).join(' ').toLowerCase();
    const purpose = String(summary.purpose || '').toLowerCase();
    const desc = String(summary.description || '').toLowerCase();
    const text = `${stack.join(' ')} ${features} ${arch} ${purpose} ${desc}`;

    if (/(java|spring|jdk|jvm)/.test(text)) scores.java += 22;
    if (/(algorithm|dsa|binary tree|graph|dp|complexity|leetcode)/.test(text)) scores.dsa += 20;
    if (/(system design|architecture|microservice|distributed|scalab|cache|queue|load balanc)/.test(text)) scores.systemDesign += 22;
    if (/(react|node|express|full stack|flutter|dart|frontend|backend|mongodb|sql)/.test(text)) scores.fullStack += 18;
    if (/(ai|ml|machine learning|tensorflow|pytorch|llm|nlp|model|inference)/.test(text)) scores.aiMl += 24;
  }

  return normalizeSkillMap(scores);
}

function computeLanguageDistribution(repos = []) {
  const languageCount = {};
  let total = 0;

  for (const repo of repos) {
    const lang = repo.language ? String(repo.language).trim() : '';
    if (!lang) continue;
    languageCount[lang] = (languageCount[lang] || 0) + 1;
    total++;
  }

  if (total === 0) return {};

  const sorted = Object.entries(languageCount).sort((a, b) => b[1] - a[1]);
  const top = sorted.slice(0, 5);
  const otherCount = sorted.slice(5).reduce((acc, [, count]) => acc + count, 0);

  const result = {};
  for (const [lang, count] of top) {
    result[lang] = Math.round((count / total) * 100);
  }

  if (otherCount > 0) {
    result.Other = Math.round((otherCount / total) * 100);
  }

  const keys = Object.keys(result);
  const sum = keys.reduce((acc, key) => acc + result[key], 0);
  if (sum !== 100 && keys.length > 0) {
    result[keys[0]] += (100 - sum);
  }

  return result;
}

/**
 * ================================
 * LOGIN (WITH PROXY FIX)
 * ================================
 */
router.get('/login', (req, res) => {
  try {
    console.log('\n===== 🔐 GITHUB LOGIN STARTED =====');

    if (!process.env.GITHUB_CLIENT_ID) {
      return res.status(500).json({ error: 'GitHub Client ID not configured' });
    }

    const protocol = req.headers['x-forwarded-proto'] || req.protocol;
    const host = req.headers['x-forwarded-host'] || req.get('host');

    const redirectUri = `${protocol}://${host}/auth/github/callback`;

    const githubUrl =
      'https://github.com/login/oauth/authorize' +
      `?client_id=${process.env.GITHUB_CLIENT_ID}` +
      `&redirect_uri=${encodeURIComponent(redirectUri)}` +
      '&scope=read:user repo';

    res.redirect(githubUrl);
  } catch (error) {
    res.status(500).json({ error: 'Failed to start GitHub auth' });
  }
});

/**
 * ================================
 * CALLBACK (WITH ALL FEATURES)
 * ================================
 */
router.get('/callback', async (req, res) => {
  const { code } = req.query;

  if (!code) return res.status(400).send('Missing code');

  try {
    const protocol = req.headers['x-forwarded-proto'] || req.protocol;
    const host = req.headers['x-forwarded-host'] || req.get('host');

    const redirectUri = `${protocol}://${host}/auth/github/callback`;

    const tokenRes = await axios.post(
      'https://github.com/login/oauth/access_token',
      {
        client_id: process.env.GITHUB_CLIENT_ID,
        client_secret: process.env.GITHUB_CLIENT_SECRET,
        code,
        redirect_uri: redirectUri,
      },
      { headers: { Accept: 'application/json' } }
    );

    const accessToken = tokenRes.data.access_token;
    if (!accessToken) return res.status(401).send('No access token');

    const ghUserRes = await axios.get('https://api.github.com/user', {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        Accept: 'application/vnd.github+json',
      },
    });

    const gh = ghUserRes.data;

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
      { upsert: true, new: true }
    );

    // 🔥 LOGIN STREAK
    const now = new Date();
    const lastLoginAt = user.lastLoginAt ? new Date(user.lastLoginAt) : null;
    const loginDates = user.loginDates || [];

    const todayStart = startOfUtcDay(now);
    const alreadyLoggedToday = loginDates.some(d => startOfUtcDay(new Date(d)).getTime() === todayStart.getTime());

    if (!alreadyLoggedToday) loginDates.push(now);

    let loginStreak = user.loginStreak || 0;

    if (!lastLoginAt) loginStreak = 1;
    else {
      const diff = dayDiffUtc(now, lastLoginAt);
      if (diff === 1) loginStreak += 1;
      else if (diff > 1) loginStreak = 1;
    }

    user.lastLoginAt = now;
    user.loginStreak = loginStreak;
    user.maxLoginStreak = Math.max(user.maxLoginStreak || 0, loginStreak);
    user.loginDates = loginDates;

    await user.save();

    const jwtToken = jwt.sign(
      { userId: user._id },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.redirect(`careercraft://login-success?token=${jwtToken}`);
  } catch (err) {
    console.error(err);
    res.status(500).send('GitHub login failed');
  }
});

/**
 * ================================
 * REPOS
 * ================================
 */
router.get('/repos', requireAuth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);

    const reposRes = await axios.get('https://api.github.com/user/repos', {
      headers: { Authorization: `Bearer ${user.githubAccessToken}` },
      params: { per_page: 50, sort: 'updated' },
    });

    res.json(reposRes.data);
  } catch {
    res.status(500).json({ error: 'Failed to fetch repos' });
  }
});

/**
 * ================================
 * PROFILE
 * ================================
 */
router.get('/profile', requireAuth, async (req, res) => {
  const user = await User.findById(req.user.userId);

  res.json({
    username: user.username,
    name: user.name,
    avatar: user.avatar,
    email: user.email,
    public_repos: user.public_repos,
    followers: user.followers,
    following: user.following,
    login_streak: user.loginStreak || 0,
    total_active_days: user.loginDates?.length || 0,
  });
});

/**
 * ================================
 * DASHBOARD
 * ================================
 */
router.get('/dashboard', requireAuth, async (req, res) => {
  const user = await User.findById(req.user.userId);

  const [completedInterviews, summaries, reposRes] = await Promise.all([
    InterviewSession.countDocuments({ userId: user._id, status: 'completed' }),
    RepoSummary.find({ userId: user._id }),
    axios.get('https://api.github.com/user/repos', {
      headers: { Authorization: `Bearer ${user.githubAccessToken}` },
    }),
  ]);

  res.json({
    profile: user,
    stats: {
      loginStreak: user.loginStreak,
      totalActiveDays: user.loginDates?.length || 0,
      completedInterviews,
    },
    skills: computeSkillProgress(summaries),
    languageDistribution: computeLanguageDistribution(reposRes.data),
  });
});

/**
 * ================================
 * SETTINGS
 * ================================
 */
router.post('/settings', requireAuth, async (req, res) => {
  const user = await User.findById(req.user.userId);

  if (typeof req.body.notificationEnabled === 'boolean') {
    user.notificationEnabled = req.body.notificationEnabled;
  }

  await user.save();

  res.json({ success: true });
});

/**
 * ================================
 * SEARCH
 * ================================
 */
router.get('/search', requireAuth, async (req, res) => {
  const query = String(req.query.q || '').trim();
  if (!query) return res.json({ repos: [], chats: [], interviews: [] });

  const user = await User.findById(req.user.userId);
  const regex = new RegExp(query, 'i');

  const reposRes = await axios.get('https://api.github.com/user/repos', {
    headers: { Authorization: `Bearer ${user.githubAccessToken}` },
  });

  const repos = reposRes.data.filter(r => regex.test(r.name));

  const chats = await ChatSession.find({
    userId: user._id,
    title: regex,
  });

  const interviews = await InterviewSession.find({
    userId: user._id,
  });

  res.json({ repos, chats, interviews });
});

module.exports = router;