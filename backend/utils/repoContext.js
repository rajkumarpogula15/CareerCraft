function extractKeywords(message) {
  return message
    .toLowerCase()
    .replace(/[^a-z0-9 ]/g, '')
    .split(/\s+/)
    .filter(w => w.length > 3);
}

/**
 * Build LLM context from ANY repo files
 */
function buildRepoContext(files, message) {
  const keywords = extractKeywords(message);
  const scored = [];

  for (const file of files) {
    const lower = file.content.toLowerCase();
    let score = 0;

    for (const k of keywords) {
      if (lower.includes(k)) score++;
    }

    if (score > 0) {
      scored.push({ ...file, score });
    }
  }

  if (!scored.length) {
    return 'NO_RELEVANT_FILES';
  }

  return scored
    .sort((a, b) => b.score - a.score)
    .slice(0, 6)
    .map(
      f => `\n\nFile: ${f.path}\n${f.content}`
    )
    .join('');
}

module.exports = { buildRepoContext };
