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

/* ---------------- MAIN FETCH ---------------- */

async function fetchRepoFiles(owner, repo, token) {
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
  const files = await Promise.all(
    blobs.map(async file => {
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
    })
  );

  return files.filter(Boolean);
}

module.exports = { fetchRepoFiles };
