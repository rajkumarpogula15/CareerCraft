const activityRepository = require('../repositories/activity.repository');

const createActivity = async ({ userId, message, repoName, type }) => {
  await activityRepository.create({ userId, message, repoName, type });

  const activities = await activityRepository.findByUserSorted(userId);
  if (activities.length <= 10) {
    return { success: true };
  }

  const chatActivities = activities.filter(a => a.type === 'repo_chat');
  const deletionCandidates = [...activities].reverse();
  const idsToDelete = [];

  for (const activity of deletionCandidates) {
    if (activities.length - idsToDelete.length <= 10) break;

    if (activity.type === 'repo_chat' && chatActivities.length === 1) {
      continue;
    }

    idsToDelete.push(activity._id);
    if (activity.type === 'repo_chat') {
      chatActivities.pop();
    }
  }

  if (idsToDelete.length > 0) {
    await activityRepository.deleteManyByIds(idsToDelete);
  }

  return { success: true };
};

const getRecentActivities = userId => activityRepository.findRecentByUser(userId, 5);

module.exports = {
  createActivity,
  getRecentActivities,
};
