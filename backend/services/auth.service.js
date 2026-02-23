const axios = require('axios');
const jwt = require('jsonwebtoken');
const userRepository = require('../repositories/user.repository');

const githubHeaders = token => ({
  Authorization: `Bearer ${token}`,
  Accept: 'application/vnd.github+json',
});

const getGithubLoginUrl = () => {
  if (!process.env.GITHUB_CLIENT_ID) {
    throw new Error('GitHub Client ID not configured');
  }

  return (
    'https://github.com/login/oauth/authorize' +
    `?client_id=${process.env.GITHUB_CLIENT_ID}` +
    '&scope=read:user repo'
  );
};

const exchangeCodeForToken = async code => {
  const tokenRes = await axios.post(
    'https://github.com/login/oauth/access_token',
    {
      client_id: process.env.GITHUB_CLIENT_ID,
      client_secret: process.env.GITHUB_CLIENT_SECRET,
      code,
    },
    { headers: { Accept: 'application/json' } }
  );

  return tokenRes.data.access_token;
};

const fetchGithubUser = async accessToken => {
  const ghUserRes = await axios.get('https://api.github.com/user', {
    headers: githubHeaders(accessToken),
  });

  return ghUserRes.data;
};

const loginWithGithubCode = async code => {
  const accessToken = await exchangeCodeForToken(code);
  if (!accessToken) {
    throw Object.assign(new Error('No access token'), { status: 401 });
  }

  const gh = await fetchGithubUser(accessToken);

  const user = await userRepository.upsertGithubUser(gh.id, {
    githubId: gh.id,
    username: gh.login,
    name: gh.name,
    avatar: gh.avatar_url,
    email: gh.email,
    public_repos: gh.public_repos,
    followers: gh.followers,
    following: gh.following,
    githubAccessToken: accessToken,
  });

  if (!process.env.JWT_SECRET) {
    throw new Error('JWT Secret missing');
  }

  const jwtToken = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, {
    expiresIn: '7d',
  });

  return { jwtToken, user };
};

const fetchReposForUser = async userId => {
  const user = await userRepository.findById(userId);
  if (!user) {
    throw Object.assign(new Error('User not found'), { status: 404 });
  }

  const reposRes = await axios.get('https://api.github.com/user/repos', {
    headers: githubHeaders(user.githubAccessToken),
    params: { per_page: 50, sort: 'updated' },
  });

  return reposRes.data.map(repo => ({
    id: repo.id,
    name: repo.name,
    description: repo.description,
    private: repo.private,
    html_url: repo.html_url,
    updated_at: repo.updated_at,
    has_readme: !!repo.has_wiki || !!repo.description,
  }));
};

const fetchProfile = async userId => {
  const user = await userRepository.findProfileById(userId);
  if (!user) {
    throw Object.assign(new Error('User not found'), { status: 404 });
  }

  return {
    username: user.username,
    name: user.name,
    avatar: user.avatar,
    email: user.email,
    public_repos: user.public_repos,
    followers: user.followers,
    following: user.following,
  };
};

module.exports = {
  getGithubLoginUrl,
  loginWithGithubCode,
  fetchReposForUser,
  fetchProfile,
};
