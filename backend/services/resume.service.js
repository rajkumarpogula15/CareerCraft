const resumeRepository = require('../repositories/resume.repository');

const getResume = userId => resumeRepository.findByUserId(userId);

const saveResume = async (userId, payload) => {
  const normalizedPayload = { ...payload };

  if (Array.isArray(normalizedPayload.education)) {
    normalizedPayload.education = normalizedPayload.education.map(edu => ({
      ...edu,
      Percentage: edu.Percentage ?? edu.grade ?? '',
    }));
  }

  return resumeRepository.upsertByUserId(userId, normalizedPayload);
};

module.exports = {
  getResume,
  saveResume,
};
