const axios = require('axios');

/**
 * Resolve a repository by name using GitHub API
 * This matches the logic used in /commit
 */
async function resolveRepo(githubToken, repoName) {
  const headers = {
    Authorization: `Bearer ${githubToken}`,
    Accept: 'application/vnd.github+json',
  };

  // 1️⃣ Get all repos for authenticated user
  const res = await axios.get(
    'https://api.github.com/user/repos?per_page=100',
    { headers }
  );

  const repo = res.data.find(r => r.name === repoName);

  if (!repo) {
    throw new Error(`Repository "${repoName}" not found for user`);
  }

  return repo; // contains owner, name, full_name, default_branch, etc.
}

module.exports = { resolveRepo };
