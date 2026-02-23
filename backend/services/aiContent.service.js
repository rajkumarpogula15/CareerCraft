const axios = require('axios');
const userRepository = require('../repositories/user.repository');
const logActivity = require('../utils/logActivity');

const GITHUB_API = 'https://api.github.com';
const GEMINI_API = 'https://generativelanguage.googleapis.com/v1beta/models';
const GEMINI_MAX_RETRIES = 3;
const GEMINI_TIMEOUT = 20000;

const aiCache = new Map();
const getCacheKey = (...parts) => parts.join(':');

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
  const message = err.response?.data?.message || err.response?.data?.error || err.message;
  return Object.assign(new Error(message), { status });
};

const resolveRepo = async (token, repoName) => {
  const repos = [];
  const userRepos = await githubGet(`${GITHUB_API}/user/repos?per_page=100`, token);
  repos.push(...userRepos.data);

  const orgs = await githubGet(`${GITHUB_API}/user/orgs`, token);
  for (const org of orgs.data) {
    const orgRepos = await githubGet(`${GITHUB_API}/orgs/${org.login}/repos?per_page=100`, token);
    repos.push(...orgRepos.data);
  }

  const repo = repos.find(r => r.name === repoName);
  if (!repo) throw Object.assign(new Error('Repository not found or inaccessible'), { status: 404 });
  if (!repo.permissions?.push) throw Object.assign(new Error('Insufficient permissions on repository'), { status: 403 });
  return repo;
};

const fetchFolderStructure = async (token, owner, repo) => {
  try {
    const res = await githubGet(`${GITHUB_API}/repos/${owner}/${repo}/contents`, token);
    return res.data.map(item => ({ name: item.name, type: item.type }));
  } catch {
    return [];
  }
};

const fetchReadme = async (token, owner, repo) => {
  try {
    const res = await githubGet(`${GITHUB_API}/repos/${owner}/${repo}/readme`, token);
    return Buffer.from(res.data.content, 'base64').toString('utf-8');
  } catch {
    return null;
  }
};

const sanitizeReadme = (readme, maxChars = 4000) => {
  if (!readme) return 'Not available';
  return readme
    .replace(/!\[.*?\]\(.*?\)/g, '')
    .replace(/```[\s\S]*?```/g, '')
    .replace(/\n{3,}/g, '\n\n')
    .slice(0, maxChars)
    .trim();
};

const generateWithGemini = async prompt => {
  let attempt = 0;
  while (attempt < GEMINI_MAX_RETRIES) {
    try {
      const res = await axios.post(
        `${GEMINI_API}/${process.env.GEMINI_MODEL}:generateContent`,
        { contents: [{ role: 'user', parts: [{ text: prompt }] }] },
        {
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': process.env.GEMINI_API_KEY,
          },
          timeout: GEMINI_TIMEOUT,
        }
      );

      const text = res.data?.candidates?.[0]?.content?.parts?.[0]?.text;
      if (!text || !text.trim()) {
        throw new Error('AI returned empty response');
      }

      return text.trim();
    } catch (err) {
      const normalized = normalizeAxiosError(err);
      if (normalized.status === 429 && attempt < GEMINI_MAX_RETRIES - 1) {
        await new Promise(r => setTimeout(r, 1000 * Math.pow(2, attempt)));
        attempt += 1;
        continue;
      }

      throw normalized;
    }
  }
};

const getUserAndRepo = async (userId, repoName) => {
  const user = await userRepository.findById(userId);
  if (!user?.githubAccessToken) {
    throw Object.assign(new Error('GitHub token missing'), { status: 401 });
  }

  const repo = await resolveRepo(user.githubAccessToken, repoName);
  return { user, repo };
};

const generateReadme = async ({ userId, repoName, description, language }) => {
  const { user, repo } = await getUserAndRepo(userId, repoName);
  const structure = await fetchFolderStructure(user.githubAccessToken, repo.owner.login, repo.name);

  const prompt = `
You are a senior open-source engineer.
Generate a PROFESSIONAL README.md.
Repository: ${repo.name}
Owner: ${repo.owner.login}
Description: ${repo.description || description || 'N/A'}
Language: ${repo.language || language || 'Unknown'}
Folder Structure:
${
  structure.length
    ? structure.map(f => `- ${f.type === 'dir' ? '📁' : '📄'} ${f.name}`).join('\n')
    : 'Not available'
}
Rules:
- Clean Markdown
- No hallucinations
- Best open-source practices
- Output markdown only
`.trim();

  const readme = await generateWithGemini(prompt);

  await logActivity({
    userId,
    type: 'readme_generated',
    repoName: repo.name,
    message: `Generated README for ${repo.name}`,
  });

  return {
    readme,
    owner: repo.owner.login,
    defaultBranch: repo.default_branch,
  };
};

const generateSocialPost = async ({ userId, repoName, platform = 'LinkedIn' }) => {
  const { user, repo } = await getUserAndRepo(userId, repoName);
  const readmeRaw = await fetchReadme(user.githubAccessToken, repo.owner.login, repo.name);
  const readme = sanitizeReadme(readmeRaw);

  const cacheKey = getCacheKey('social', userId, repo.name, platform);
  if (aiCache.has(cacheKey)) {
    return { post: aiCache.get(cacheKey) };
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
    userId,
    type: 'social_post_generated',
    repoName: repo.name,
    message: `Generated social post for ${repo.name}`,
  });

  return { post };
};

const generateResumePoints = async ({ userId, repoName }) => {
  const { user, repo } = await getUserAndRepo(userId, repoName);
  const readmeRaw = await fetchReadme(user.githubAccessToken, repo.owner.login, repo.name);
  const readme = sanitizeReadme(readmeRaw);

  const prompt = `
You are a senior software engineer and ATS resume optimization expert.
Generate EXACTLY 2–4 resume bullet points using only provided data.
Project Context:
- Name: ${repo.name}
- Description: ${repo.description || 'N/A'}
- Primary Language / Stack: ${repo.language || 'Unknown'}
README:
${readme}
Rules:
- Bullet points only
- No assumptions
- No invented metrics
- ATS-ready language
`.trim();

  const points = await generateWithGemini(prompt);

  await logActivity({
    userId,
    type: 'resume_points_generated',
    repoName: repo.name,
    message: `Generated resume points for ${repo.name}`,
  });

  return { points };
};

module.exports = {
  generateReadme,
  generateSocialPost,
  generateResumePoints,
};
