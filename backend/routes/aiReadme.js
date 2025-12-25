const express = require('express');
const axios = require('axios');
const requireAuth = require('../middleware/requireAuth');
const User = require('../models/User');

const router = express.Router();

/* ============================
   HELPERS
============================ */

const githubHeaders = token => ({
  Authorization: `Bearer ${token}`,
  Accept: 'application/vnd.github+json',
});

/**
 * Resolve repo ONLY from repos the user actually has access to
 * (Fixes 404 caused by global search)
 */
const resolveRepo = async (token, repoName) => {
  console.log('🔍 Resolving repo:', repoName);

  const repos = [];

  // 1️⃣ User repos
  const userRepos = await axios.get(
    'https://api.github.com/user/repos?per_page=100',
    { headers: githubHeaders(token) }
  );
  repos.push(...userRepos.data);

  // 2️⃣ Org repos
  const orgs = await axios.get(
    'https://api.github.com/user/orgs',
    { headers: githubHeaders(token) }
  );

  for (const org of orgs.data) {
    const orgRepos = await axios.get(
      `https://api.github.com/orgs/${org.login}/repos?per_page=100`,
      { headers: githubHeaders(token) }
    );
    repos.push(...orgRepos.data);
  }

  const repo = repos.find(r => r.name === repoName);

  if (!repo) {
    throw new Error('Repository not found in user/org scope');
  }

  console.log('✅ Repo resolved:', {
    full_name: repo.full_name,
    private: repo.private,
    default_branch: repo.default_branch,
    permissions: repo.permissions,
  });

  if (!repo.permissions?.push) {
    throw new Error('No push permission on this repository');
  }

  return repo;
};

/**
 * Fetch folder structure (non-fatal)
 */
const fetchFolderStructure = async (token, owner, repo) => {
  try {
    const res = await axios.get(
      `https://api.github.com/repos/${owner}/${repo}/contents`,
      { headers: githubHeaders(token) }
    );

    return res.data.map(item => ({
      name: item.name,
      type: item.type,
    }));
  } catch (err) {
    console.log('⚠️ Folder structure fetch failed');
    return [];
  }
};

/* ============================
   GENERATE README
============================ */
router.post('/generate', requireAuth, async (req, res) => {
  const { repoName, description, language } = req.body;

  if (!repoName) {
    return res.status(400).json({ error: 'repoName is required' });
  }

  try {
    const user = await User.findById(req.user.userId);
    if (!user?.githubAccessToken) {
      return res.status(401).json({ error: 'GitHub token missing' });
    }

    console.log('🔑 Token prefix:', user.githubAccessToken.slice(0, 6));

    const repo = await resolveRepo(user.githubAccessToken, repoName);

    const folderStructure = await fetchFolderStructure(
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
${folderStructure.length
  ? folderStructure.map(f => `- ${f.type === 'dir' ? '📁' : '📄'} ${f.name}`).join('\n')
  : 'Not available'}

Rules:
- Clean Markdown
- No hallucinations
- Best open-source practices
- Output markdown only
`;

    const geminiRes = await axios.post(
      `https://generativelanguage.googleapis.com/v1beta/models/${process.env.GEMINI_MODEL}:generateContent`,
      {
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': process.env.GEMINI_API_KEY,
        },
      }
    );

    const readme =
      geminiRes.data?.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!readme) {
      throw new Error('Gemini returned empty README');
    }

    res.json({
      readme,
      owner: repo.owner.login,
      defaultBranch: repo.default_branch,
    });
  } catch (err) {
    console.error('❌ GENERATE ERROR:', err.message);
    res.status(500).json({ error: err.message });
  }
});

/* ============================
   COMMIT README
============================ */
router.post('/commit', requireAuth, async (req, res) => {
  const { repoName, readme } = req.body;

  if (!repoName || !readme) {
    return res.status(400).json({
      error: 'repoName and readme are required',
    });
  }

  try {
    const user = await User.findById(req.user.userId);
    if (!user?.githubAccessToken) {
      return res.status(401).json({ error: 'GitHub token missing' });
    }

    console.log('🔑 Token prefix:', user.githubAccessToken.slice(0, 6));

    const repo = await resolveRepo(user.githubAccessToken, repoName);

    const apiUrl = `https://api.github.com/repos/${repo.owner.login}/${repo.name}/contents/README.md`;
    console.log('📄 README API URL:', apiUrl);

    let sha = null;

    try {
      const existing = await axios.get(apiUrl, {
        headers: githubHeaders(user.githubAccessToken),
      });
      sha = existing.data.sha;
      console.log('📘 README exists, SHA:', sha);
    } catch (err) {
      console.log('📕 README does not exist');
    }

    const payload = {
      message: 'docs: add AI-generated README',
      content: Buffer.from(readme).toString('base64'),
      branch: repo.default_branch,
      ...(sha && { sha }),
    };

    console.log('⬆️ Commit payload:', {
      branch: payload.branch,
      hasSha: Boolean(sha),
      contentLength: readme.length,
    });

    await axios.put(apiUrl, payload, {
      headers: githubHeaders(user.githubAccessToken),
    });

    res.json({
      success: true,
      repo: repo.full_name,
    });
  } catch (err) {
    console.error('❌ COMMIT ERROR:', {
      status: err.response?.status,
      data: err.response?.data,
    });

    res.status(500).json({
      error: 'Failed to commit README',
      details: err.response?.data || err.message,
    });
  }
});

module.exports = router;
