const axios = require('axios');

const IGNORE_DIRS = [
  'node_modules',
  'vendor',
  'build',
  'dist',
  'out',
  'target',
  '.next',
  '.nuxt',
  '.dart_tool',
  '.idea',
  '.vscode',
  '.git',
  'coverage',
  '__pycache__',
];

const IGNORE_EXTENSIONS = [
  '.png', '.jpg', '.jpeg', '.gif', '.svg',
  '.exe', '.dll', '.so',
  '.zip', '.tar', '.gz', '.7z',
  '.pdf', '.mp4', '.mp3',
];

const MAX_FILE_SIZE = 150_000;
const MAX_FILES = 30;

function shouldIgnoreFile(filePath) {
  const lower = filePath.toLowerCase();
  if (IGNORE_DIRS.some(dir => lower.includes(`/${dir}/`))) return true;
  if (IGNORE_EXTENSIONS.some(ext => lower.endsWith(ext))) return true;
  return false;
}

async function fetchRepoFiles(owner, repo, token) {
  const headers = {
    Authorization: `Bearer ${token}`,
    Accept: 'application/vnd.github+json',
  };

  // ✅ 1. FETCH REPO INFO (to get default branch)
  const repoRes = await axios.get(
    `https://api.github.com/repos/${owner}/${repo}`,
    { headers }
  );

  const defaultBranch = repoRes.data.default_branch;

  // ✅ 2. FETCH TREE USING DEFAULT BRANCH
  const treeRes = await axios.get(
    `https://api.github.com/repos/${owner}/${repo}/git/trees/${defaultBranch}?recursive=1`,
    { headers }
  );

  const blobs = treeRes.data.tree.filter(
    file =>
      file.type === 'blob' &&
      file.size > 0 &&
      file.size <= MAX_FILE_SIZE &&
      !shouldIgnoreFile(file.path)
  );

  const files = [];

  for (const file of blobs.slice(0, MAX_FILES)) {
    try {
      const rawRes = await axios.get(
        `https://raw.githubusercontent.com/${owner}/${repo}/${defaultBranch}/${file.path}`,
        { headers }
      );

      files.push({
        path: file.path,
        content: rawRes.data,
      });
    } catch {
      // ignore unreadable files
    }
  }

  return files;
}

module.exports = { fetchRepoFiles };
