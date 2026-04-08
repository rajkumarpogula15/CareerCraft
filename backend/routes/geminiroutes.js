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
 * Resolve repo from user + orgs.
 */
const resolveRepo = async (token, repoName, { requirePush = false } = {}) => {
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

  if (requirePush && !repo.permissions?.push) {
    throw Object.assign(
      new Error('Insufficient permissions on repository'),
      { status: 403 }
    );
  }

  return repo;
};

const parseBulletPoints = (text, maxPoints = 2) => {
  if (!text || typeof text !== 'string') {
    return [];
  }

  const points = text
    .split('\n')
    .map(line => line.trim())
    .filter(Boolean)
    .map(line =>
      line
        .replace(/^[-*\u2022]\s*/, '')
        .replace(/^\d+[\).\s-]+/, '')
        .replace(/\*\*/g, '')
        .trim()
    )
    .filter(Boolean);

  return points.slice(0, maxPoints);
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
 * Fetch README.md (non-fatal)
 */
const fetchReadme = async (token, owner, repo) => {
  try {
    const res = await githubGet(
      `${GITHUB_API}/repos/${owner}/${repo}/readme`,
      token
    );

    return Buffer.from(res.data.content, 'base64').toString('utf-8');
  } catch {
    return null;
  }
};

/**
 * Sanitize README for AI safety
 */
const sanitizeReadme = (readme, maxChars = 4000) => {
  if (!readme) return 'Not available';

  return readme
    .replace(/!\[.*?\]\(.*?\)/g, '') // images
    .replace(/```[\s\S]*?```/g, '')  // code blocks
    .replace(/\n{3,}/g, '\n\n')
    .slice(0, maxChars)
    .trim();
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
        await new Promise(r =>
          setTimeout(r, 1000 * Math.pow(2, attempt))
        );
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
    const readmeRaw = await fetchReadme(
      user.githubAccessToken,
      repo.owner.login,
      repo.name
    );
    const readme = sanitizeReadme(readmeRaw);

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

README (source of truth):
${readme}

Rules:
- Use ONLY information present above
- Professional & engaging
- 1–2 emojis max
- Plain text only
- No assumptions
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
    const readmeRaw = await fetchReadme(
      user.githubAccessToken,
      repo.owner.login,
      repo.name
    );
    const readme = sanitizeReadme(readmeRaw);

    const prompt = `
You are a senior software engineer and ATS resume optimization expert.

Generate EXACTLY 2 resume bullet points optimized for:
- Applicant Tracking Systems (ATS)
- Recruiter keyword scanning
- Technical interview screening

Use ONLY the information explicitly present below.

Project Context:
- Name: ${repo.name}
- Description: ${repo.description || 'N/A'}
- Primary Language / Stack: ${repo.language || 'Unknown'}

README (author-written source of truth):
${readme}

Instructions:
- Focus on skills, tools, technologies, and responsibilities mentioned
- Use strong action verbs (e.g., Designed, Implemented, Built, Optimized)
- Include relevant technical keywords naturally (frameworks, APIs, databases, tooling, architecture)
- Emphasize impact, scalability, performance, security, or reliability ONLY if stated
- Prefer concise, high-signal bullets (1 line each)

Hard Rules:
- Bullet points only (no headings, no explanations)
- No emojis
- No filler phrases (e.g., "worked on", "responsible for")
- No assumptions, no inferred features, no invented metrics
- If information is limited, stay high-level and factual

Output:
- Exactly 2 bullet points, ATS-friendly, recruiter-focused, resume-safe
`.trim();


    const pointsText = await generateWithGemini(prompt);
    const points = parseBulletPoints(pointsText);

    if (!points.length) {
      throw new Error('AI returned invalid resume points');
    }

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



