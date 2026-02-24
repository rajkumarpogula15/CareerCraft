const express = require('express');
const axios = require('axios');
const jwt = require('jsonwebtoken');

const User = require('../models/User');
const ChatSession = require('../models/ChatSession');
const InterviewSession = require('../models/InterviewSession');
const RepoSummary = require('../models/RepoSummary');
const requireAuth = require('../middleware/requireAuth');

const router = express.Router();

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
    if (/(system design|architecture|microservice|distributed|scalab|cache|queue|load balanc)/.test(text)) {
      scores.systemDesign += 22;
    }
    if (/(react|node|express|full stack|flutter|dart|frontend|backend|mongodb|sql)/.test(text)) {
      scores.fullStack += 18;
    }
    if (/(ai|ml|machine learning|tensorflow|pytorch|llm|nlp|model|inference)/.test(text)) {
      scores.aiMl += 24;
    }
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
    total += 1;
  }

  if (total === 0) {
    return {};
  }

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

  // Normalize rounding drift to 100.
  const keys = Object.keys(result);
  const sum = keys.reduce((acc, key) => acc + result[key], 0);
  if (sum !== 100 && keys.length > 0) {
    const delta = 100 - sum;
    result[keys[0]] = Math.max(0, result[keys[0]] + delta);
  }

  return result;
}

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

    const now = new Date();
    const lastLoginAt = user.lastLoginAt ? new Date(user.lastLoginAt) : null;
    const loginDates = Array.isArray(user.loginDates) ? user.loginDates.map(d => new Date(d)) : [];
    const todayStart = startOfUtcDay(now);

    const alreadyLoggedToday = loginDates.some(d => startOfUtcDay(d).getTime() === todayStart.getTime());
    if (!alreadyLoggedToday) {
      loginDates.push(now);
    }

    let loginStreak = user.loginStreak || 0;
    if (!lastLoginAt) {
      loginStreak = 1;
    } else {
      const diff = dayDiffUtc(now, lastLoginAt);
      if (diff === 0) {
        loginStreak = user.loginStreak || 1;
      } else if (diff === 1) {
        loginStreak = (user.loginStreak || 0) + 1;
      } else {
        loginStreak = 1;
      }
    }

    user.lastLoginAt = now;
    user.loginStreak = loginStreak;
    user.maxLoginStreak = Math.max(user.maxLoginStreak || 0, loginStreak);
    user.loginDates = loginDates;
    await user.save();

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
      'username name avatar email public_repos followers following loginStreak loginDates notificationEnabled'
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
      login_streak: user.loginStreak || 0,
      total_active_days: user.loginDates?.length || 0,
      notification_enabled: user.notificationEnabled !== false,
    });
  } catch (err) {
    console.error('🔥 PROFILE ERROR:', err.response?.data || err.message);

    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

router.get('/dashboard', requireAuth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).select(
      'username name avatar email public_repos followers following githubAccessToken loginStreak loginDates notificationEnabled'
    );

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const [completedInterviews, summaries, reposRes] = await Promise.all([
      InterviewSession.countDocuments({
        userId: user._id,
        status: 'completed',
      }),
      RepoSummary.find({ userId: user._id }).select(
        'techStack description purpose keyFeatures architectureHints'
      ),
      axios.get('https://api.github.com/user/repos', {
        headers: {
          Authorization: `Bearer ${user.githubAccessToken}`,
          Accept: 'application/vnd.github+json',
        },
        params: { per_page: 100, sort: 'updated' },
      }),
    ]);

    const skills = computeSkillProgress(summaries);
    const languageDistribution = computeLanguageDistribution(reposRes.data || []);

    res.json({
      profile: {
        username: user.username,
        name: user.name,
        avatar: user.avatar,
        email: user.email,
        public_repos: user.public_repos,
        followers: user.followers,
        following: user.following,
      },
      stats: {
        loginStreak: user.loginStreak || 0,
        totalActiveDays: user.loginDates?.length || 0,
        completedInterviews,
        notificationsEnabled: user.notificationEnabled !== false,
      },
      skills,
      languageDistribution,
    });
  } catch (err) {
    console.error('DASHBOARD ERROR:', err.response?.data || err.message);
    res.status(500).json({ error: 'Failed to fetch dashboard data' });
  }
});

router.post('/settings', requireAuth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ error: 'User not found' });

    if (typeof req.body.notificationEnabled === 'boolean') {
      user.notificationEnabled = req.body.notificationEnabled;
    }
    await user.save();

    res.json({
      success: true,
      notificationEnabled: user.notificationEnabled !== false,
    });
  } catch (err) {
    console.error('SETTINGS ERROR:', err.response?.data || err.message);
    res.status(500).json({ error: 'Failed to update settings' });
  }
});

router.get('/search', requireAuth, async (req, res) => {
  try {
    const query = String(req.query.q || '').trim();
    if (!query) {
      return res.json({ repos: [], chats: [], interviews: [] });
    }

    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ error: 'User not found' });

    const queryRegex = new RegExp(query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');

    const [reposRes, chats, interviews] = await Promise.all([
      axios.get('https://api.github.com/user/repos', {
        headers: {
          Authorization: `Bearer ${user.githubAccessToken}`,
          Accept: 'application/vnd.github+json',
        },
        params: { per_page: 100, sort: 'updated' },
      }),
      ChatSession.find({
        userId: user._id,
        $or: [{ repoName: queryRegex }, { title: queryRegex }],
      })
        .select('repoOwner repoName title updatedAt')
        .sort({ updatedAt: -1 })
        .limit(10),
      InterviewSession.find({
        userId: user._id,
        status: 'completed',
      })
        .select('difficulty completedAt finalResult repos')
        .sort({ completedAt: -1 })
        .limit(20),
    ]);

    const repos = reposRes.data
      .filter(repo => queryRegex.test(repo.name) || queryRegex.test(repo.description || ''))
      .slice(0, 15)
      .map(repo => ({
        id: repo.id,
        name: repo.name,
        description: repo.description,
        private: repo.private,
        html_url: repo.html_url,
        full_name: repo.full_name,
        language: repo.language,
      }));

    const interviewResults = interviews
      .filter(interview => {
        const byDifficulty = queryRegex.test(interview.difficulty || '');
        const byRepo = (interview.repos || []).some(r => queryRegex.test(r.repoName || ''));
        return byDifficulty || byRepo;
      })
      .map(interview => ({
        id: interview._id,
        difficulty: interview.difficulty,
        completedAt: interview.completedAt,
        score: interview.finalResult?.overallScore ?? null,
        repos: interview.repos || [],
      }));

    res.json({
      repos,
      chats,
      interviews: interviewResults,
    });
  } catch (err) {
    console.error('SEARCH ERROR:', err.response?.data || err.message);
    res.status(500).json({ error: 'Search failed' });
  }
});

module.exports = router;
