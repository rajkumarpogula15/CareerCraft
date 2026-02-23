const repositoryRepository = require('../repositories/repository.repository');
const logActivity = require('../utils/logActivity');

const addFavourite = async ({ userId, repoId, repoPayload }) => {
  let repo = await repositoryRepository.findByUserAndRepoId(userId, repoId);

  if (repo && repo.favourite) {
    return { action: 'already_favourite', favourite: true, repo };
  }

  if (repo) {
    repo.favourite = true;
    await repo.save();
  } else {
    repo = await repositoryRepository.create({
      userId,
      repoId,
      name: repoPayload.name,
      fullName: repoPayload.fullName,
      description: repoPayload.description,
      private: repoPayload.private,
      htmlUrl: repoPayload.htmlUrl,
      favourite: true,
    });
  }

  await logActivity({
    userId,
    type: 'repo_favourite',
    repoName: repo.name,
    message: `Marked ${repo.name} as favourite`,
  });

  return { action: 'added', favourite: true, repo };
};

const removeFavourite = async ({ userId, repoId }) => {
  const repo = await repositoryRepository.findByUserAndRepoId(userId, repoId);

  if (!repo || !repo.favourite) {
    return { action: 'already_removed', favourite: false };
  }

  repo.favourite = false;
  await repo.save();

  await logActivity({
    userId,
    type: 'repo_favourite',
    repoName: repo.name,
    message: `Removed ${repo.name} from favourites`,
  });

  return { action: 'removed', favourite: false, repo };
};

const listFavourites = userId => repositoryRepository.findFavouritesByUser(userId);

module.exports = {
  addFavourite,
  removeFavourite,
  listFavourites,
};
