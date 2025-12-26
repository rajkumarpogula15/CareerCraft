const DEBUG_REPO_CONTEXT = false;

/* ---------------- NORMALIZATION ---------------- */

function normalizeIdentifiers(text) {
  return text
    .toLowerCase()
    .replace(/[_\-]/g, ' ')
    .replace(/([a-z])([A-Z])/g, '$1 $2')
    .replace(/[^a-z0-9 ]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function extractKeywords(message) {
  return normalizeIdentifiers(message)
    .split(' ')
    .filter(w => w.length >= 2);
}

/* ---------------- SAFETY ---------------- */

function isBinaryText(text) {
  return typeof text === 'string' && text.includes('\u0000');
}

/* ---------------- CONTEXT BUILDER ---------------- */

function buildRepoContext(files, message) {
  if (!Array.isArray(files) || !message) {
    return 'NO_RELEVANT_FILES';
  }

  const keywords = extractKeywords(message);
  const candidates = [];

  for (const file of files) {
    if (!file?.path || typeof file.content !== 'string') {
      continue;
    }

    if (isBinaryText(file.content)) {
      continue;
    }

    const searchablePath = normalizeIdentifiers(file.path);
    const searchableContent = normalizeIdentifiers(file.content);

    let score = 0;
    for (const k of keywords) {
      if (searchablePath.includes(k)) score += 4;
      if (searchableContent.includes(k)) score += 2;
    }

    if (score > 0) {
      candidates.push({
        path: file.path,
        score,
        content: file.content,
      });
    }
  }

  if (!candidates.length) {
    return 'NO_RELEVANT_FILES';
  }

  const sorted = candidates
    .sort((a, b) => b.score - a.score)
    .slice(0, 6);

  const finalContext = sorted
    .map(
      f =>
        `\n\nFile: ${f.path}\n${f.content.slice(0, 3000)}`
    )
    .join('')
    .slice(0, 12000);

  return finalContext;
}

module.exports = { buildRepoContext };
