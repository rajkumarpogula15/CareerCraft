const axios = require('axios');

async function fetchReadme(owner, repo, token) {
  try {
    const res = await axios.get(
      `https://api.github.com/repos/${owner}/${repo}/readme`,
      {
        headers: {
          Authorization: `Bearer ${token}`,
          Accept: 'application/vnd.github.raw',
        },
      }
    );
    return res.data;
  } catch {
    return '';
  }
}

async function fetchRepoStructure(owner, repo, token) {
  try {
    const res = await axios.get(
      `https://api.github.com/repos/${owner}/${repo}/contents`,
      {
        headers: {
          Authorization: `Bearer ${token}`,
          Accept: 'application/vnd.github+json',
        },
      }
    );

    return res.data
      .filter(item => item.type === 'dir' || item.type === 'file')
      .map(item => item.name);
  } catch {
    return [];
  }
}

module.exports = {
  fetchReadme,
  fetchRepoStructure,
};
