const express = require('express');
const axios = require('axios');
const requireAuth = require('../middleware/requireAuth');
const User = require('../models/User');
const logActivity = require('../utils/logActivity');

const router = express.Router();

/* ============================
   CONFIG / CONSTANTS
============================ */

const GITHUB_API = 'https://api.github.com';
const GEMINI_API =
  'https://generativelanguage.googleapis.com/v1beta/models';

const GEMINI_MAX_RETRIES = 3;
const GEMINI_TIMEOUT = 20000;

/* ============================
   SIMPLE IN-MEMORY CACHE (DEV)
============================ */

const aiCache = new Map();
const getCacheKey = (...parts) => parts.join(':');

/* ============================
   HELPERS
============================ */

const githubHeaders = token => ({
  Authorization: `Bearer ${token}`,
  Accept: 'application/vnd.github+json',
});

const githubGet = (url, token) =>
  axios.get(url, {
    headers: githubHeaders(token),
    timeout: 15000,
  });

const normalizeAxiosError = err => {
  const status = err.response?.status;
  const message =
    err.response?.data?.message ||
    err.response?.data?.error ||
    err.message;

  return Object.assign(new Error(message), { status });
};

/**
 * Resolve repo from user + orgs (push access only)
 */
const resolveRepo = async (token, repoName) => {
  const repos = [];

  const userRepos = await githubGet(
    `${GITHUB_API}/user/repos?per_page=100`,
    token
  );
  repos.push(...userRepos.data);

  const orgs = await githubGet(`${GITHUB_API}/user/orgs`, token);

  for (const org of orgs.data) {
    const orgRepos = await githubGet(
      `${GITHUB_API}/orgs/${org.login}/repos?per_page=100`,
      token
    );
    repos.push(...orgRepos.data);
  }

  const repo = repos.find(r => r.name === repoName);

  if (!repo) {
    throw Object.assign(
      new Error('Repository not found or inaccessible'),
      { status: 404 }
    );
  }

  if (!repo.permissions?.push) {
    throw Object.assign(
      new Error('Insufficient permissions on repository'),
      { status: 403 }
    );
  }

  return repo;
};

/**
 * Fetch repo root structure (non-fatal)
 */
const fetchFolderStructure = async (token, owner, repo) => {
  try {
    const res = await githubGet(
      `${GITHUB_API}/repos/${owner}/${repo}/contents`,
      token
    );

    return res.data.map(item => ({
      name: item.name,
      type: item.type,
    }));
  } catch {
    return [];
  }
};

/**
 * Gemini generator with retry + backoff
 */
const generateWithGemini = async prompt => {
  let attempt = 0;

  while (attempt < GEMINI_MAX_RETRIES) {
    try {
      const res = await axios.post(
        `${GEMINI_API}/${process.env.GEMINI_MODEL}:generateContent`,
        {
          contents: [{ role: 'user', parts: [{ text: prompt }] }],
        },
        {
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': process.env.GEMINI_API_KEY,
          },
          timeout: GEMINI_TIMEOUT,
        }
      );

      const text =
        res.data?.candidates?.[0]?.content?.parts?.[0]?.text;

      if (!text || !text.trim()) {
        throw new Error('AI returned empty response');
      }

      return text.trim();
    } catch (err) {
      const normalized = normalizeAxiosError(err);

      if (normalized.status === 429 && attempt < GEMINI_MAX_RETRIES - 1) {
        const delay = 1000 * Math.pow(2, attempt);
        await new Promise(r => setTimeout(r, delay));
        attempt++;
        continue;
      }

      throw normalized;
    }
  }
};

/* ============================
   GENERATE README
============================ */

router.post('/generate', requireAuth, async (req, res) => {
  const { repoName, description, language } = req.body;

  if (!repoName) {
    return res.status(400).json({ message: 'repoName is required' });
  }

  try {
    const user = await User.findById(req.user.userId);
    if (!user?.githubAccessToken) {
      return res.status(401).json({ message: 'GitHub token missing' });
    }

    const repo = await resolveRepo(user.githubAccessToken, repoName);
    const structure = await fetchFolderStructure(
      user.githubAccessToken,
      repo.owner.login,
      repo.name
    );

    const prompt = `
You are a senior open-source engineer.

Generate a PROFESSIONAL README.md.

Repository: ${repo.name}
Owner: ${repo.owner.login}
Description: ${repo.description || description || 'N/A'}
Language: ${repo.language || language || 'Unknown'}

Folder Structure:
${structure.length
  ? structure.map(f => `- ${f.type === 'dir' ? '📁' : '📄'} ${f.name}`).join('\n')
  : 'Not available'}

Rules:
- Clean Markdown
- No hallucinations
- Best open-source practices
- Output markdown only
`.trim();

    const readme = await generateWithGemini(prompt);

    await logActivity({
      userId: req.user.userId,
      type: 'readme_generated',
      repoName: repo.name,
      message: `Generated README for ${repo.name}`,
    });

    res.json({
      readme,
      owner: repo.owner.login,
      defaultBranch: repo.default_branch,
    });
  } catch (err) {
    res.status(err.status || 500).json({
      message: err.message || 'Failed to generate README',
    });
  }
});

/* ============================
   GENERATE SOCIAL POST
============================ */

router.post('/generate-social-post', requireAuth, async (req, res) => {
  const { repoName, platform = 'LinkedIn' } = req.body;

  if (!repoName) {
    return res.status(400).json({ message: 'repoName is required' });
  }

  try {
    const user = await User.findById(req.user.userId);
    if (!user?.githubAccessToken) {
      return res.status(401).json({ message: 'GitHub token missing' });
    }

    const repo = await resolveRepo(user.githubAccessToken, repoName);

    const cacheKey = getCacheKey(
      'social',
      req.user.userId,
      repo.name,
      platform
    );

    if (aiCache.has(cacheKey)) {
      return res.json({ post: aiCache.get(cacheKey) });
    }

    const prompt = `
You are a professional software engineer and personal branding expert.

Generate a ${platform}-friendly social media post.

Project:
- ${repo.name}
- ${repo.description || 'N/A'}
- ${repo.language || 'Unknown'}

Rules:
- Professional & engaging
- 1–2 emojis max
- No hallucinations
- Plain text only
`.trim();

    const post = await generateWithGemini(prompt);

    aiCache.set(cacheKey, post);

    await logActivity({
      userId: req.user.userId,
      type: 'social_post_generated',
      repoName: repo.name,
      message: `Generated social post for ${repo.name}`,
    });

    res.json({ post });
  } catch (err) {
    res.status(err.status || 500).json({
      message:
        err.status === 429
          ? 'AI service is busy. Please try again shortly.'
          : err.message || 'Failed to generate social post',
    });
  }
});

/* ============================
   GENERATE RESUME POINTS
============================ */

router.post('/generate-resume-points', requireAuth, async (req, res) => {
  const { repoName } = req.body;

  if (!repoName) {
    return res.status(400).json({ message: 'repoName is required' });
  }

  try {
    const user = await User.findById(req.user.userId);
    if (!user?.githubAccessToken) {
      return res.status(401).json({ message: 'GitHub token missing' });
    }

    const repo = await resolveRepo(user.githubAccessToken, repoName);

    const prompt = `
You are a senior software engineer and ATS resume expert.

Generate 4–6 ATS-friendly resume bullet points.

Project:
- ${repo.name}
- ${repo.description || 'N/A'}
- ${repo.language || 'Unknown'}

Rules:
- Action verbs
- No emojis
- Bullet points only
- No hallucinations
`.trim();

    const points = await generateWithGemini(prompt);

    await logActivity({
      userId: req.user.userId,
      type: 'resume_points_generated',
      repoName: repo.name,
      message: `Generated resume points for ${repo.name}`,
    });

    res.json({ points });
  } catch (err) {
    res.status(err.status || 500).json({
      message:
        err.status === 429
          ? 'AI service is busy. Please try again shortly.'
          : err.message || 'Failed to generate resume points',
    });
  }
});

module.exports = router;
