const axios = require('axios');
const { Buffer } = require('buffer');

const IGNORE_DIRS = [
  'node_modules', 'vendor', 'build', 'dist', 'out',
  'target', '.next', '.nuxt', '.dart_tool',
  '.idea', '.vscode', '.git', 'coverage', '__pycache__',
];

const IGNORE_EXTENSIONS = [
  '.png', '.jpg', '.jpeg', '.gif', '.svg',
  '.exe', '.dll', '.so',
  '.zip', '.tar', '.gz', '.7z',
  '.pdf', '.mp4', '.mp3',
];

const CODE_EXTENSIONS = [
  '.js', '.ts', '.jsx', '.tsx',
  '.py', '.java', '.go', '.rb',
  '.php', '.cs', '.cpp', '.c',
  '.rs', '.swift', '.kt',
  '.dart',
];

const MAX_FILE_SIZE = 150_000;
const MAX_FILES = 300;
const REPO_CACHE_TTL_MS = 10 * 60 * 1000;
const FETCH_CONCURRENCY = 12;

const repoFileCache = new Map();

/* ---------------- HELPERS ---------------- */

function shouldIgnoreFile(filePath) {
  const lower = filePath.toLowerCase();

  if (IGNORE_DIRS.some(dir => lower.includes(`/${dir}/`))) {
    return true;
  }

  if (IGNORE_EXTENSIONS.some(ext => lower.endsWith(ext))) {
    return true;
  }

  return false;
}

function filePriority(path) {
  const lower = path.toLowerCase();

  if (CODE_EXTENSIONS.some(ext => lower.endsWith(ext))) return 3;
  if (lower.endsWith('.md')) return 1;
  return 0;
}

function getRepoCacheKey(owner, repo) {
  return `${owner}/${repo}`.toLowerCase();
}

function getCachedRepoFiles(owner, repo) {
  const cached = repoFileCache.get(getRepoCacheKey(owner, repo));
  if (!cached) {
    return null;
  }

  if (cached.expiresAt <= Date.now()) {
    repoFileCache.delete(getRepoCacheKey(owner, repo));
    return null;
  }

  return cached.files;
}

function setCachedRepoFiles(owner, repo, files) {
  repoFileCache.set(getRepoCacheKey(owner, repo), {
    files,
    expiresAt: Date.now() + REPO_CACHE_TTL_MS,
  });
}

async function mapWithConcurrency(items, concurrency, mapper) {
  const results = new Array(items.length);
  let currentIndex = 0;

  async function worker() {
    while (currentIndex < items.length) {
      const itemIndex = currentIndex++;
      results[itemIndex] = await mapper(items[itemIndex], itemIndex);
    }
  }

  const workers = Array.from(
    { length: Math.min(concurrency, items.length) },
    () => worker()
  );

  await Promise.all(workers);
  return results;
}

/* ---------------- MAIN FETCH ---------------- */

async function fetchRepoFiles(owner, repo, token) {
  const cachedFiles = getCachedRepoFiles(owner, repo);
  if (cachedFiles) {
    return cachedFiles;
  }

  const headers = {
    Authorization: `Bearer ${token}`,
    Accept: 'application/vnd.github+json',
  };

  // 1️⃣ Get repository info
  const repoRes = await axios.get(
    `https://api.github.com/repos/${owner}/${repo}`,
    { headers }
  );

  const defaultBranch = repoRes.data.default_branch;

  // 2️⃣ Get full repository tree
  const treeRes = await axios.get(
    `https://api.github.com/repos/${owner}/${repo}/git/trees/${defaultBranch}?recursive=1`,
    { headers }
  );

  // 3️⃣ Filter valid files
  const blobs = treeRes.data.tree
    .filter(file => {
      if (file.type !== 'blob') return false;
      if (!file.size || file.size > MAX_FILE_SIZE) return false;
      if (shouldIgnoreFile(file.path)) return false;
      return true;
    })
    .sort((a, b) => filePriority(b.path) - filePriority(a.path))
    .slice(0, MAX_FILES);

  // 4️⃣ Fetch file contents
  const files = await mapWithConcurrency(
    blobs,
    FETCH_CONCURRENCY,
    async file => {
      try {
        const res = await axios.get(
          `https://api.github.com/repos/${owner}/${repo}/contents/${file.path}?ref=${defaultBranch}`,
          { headers }
        );

        if (res.data.encoding !== 'base64') return null;

        const decoded = Buffer.from(
          res.data.content,
          'base64'
        ).toString('utf-8');

        return {
          path: file.path,
          content: decoded,
        };
      } catch {
        return null;
      }
    }
  );

  const filteredFiles = files.filter(Boolean);
  setCachedRepoFiles(owner, repo, filteredFiles);
  return filteredFiles;
}

module.exports = { fetchRepoFiles };
