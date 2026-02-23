const interviewService = require('../services/interview.service');

const summarizeRepos = async (req, res) => {
  const { repos } = req.body;
  if (!Array.isArray(repos) || repos.length < 1) {
    return res.status(400).json({ error: 'Invalid repo list' });
  }

  try {
    const summaries = await interviewService.summarizeRepos({ userId: req.user.userId, repos });
    res.json({ success: true, summaries });
  } catch (err) {
    res.status(err.status || 500).json({ error: 'Failed to summarize repos' });
  }
};

const startInterview = async (req, res) => {
  const { repoIds, difficulty } = req.body;

  if (!Array.isArray(repoIds) || repoIds.length < 1 || repoIds.length > 4) {
    return res.status(400).json({ error: 'Select 1 to 4 repositories' });
  }

  if (!['easy', 'medium', 'hard'].includes(difficulty)) {
    return res.status(400).json({ error: 'Invalid difficulty' });
  }

  try {
    const session = await interviewService.startInterview({ userId: req.user.userId, repoIds, difficulty });
    res.json({ success: true, sessionId: session._id });
  } catch (err) {
    res.status(err.status || 500).json({ error: err.message || 'Failed to start interview' });
  }
};

const firstQuestion = async (req, res) => {
  try {
    const result = await interviewService.generateFirstQuestion(req.params.sessionId);
    res.json(result);
  } catch (err) {
    res.status(err.status || 500).json({ error: err.message || 'Failed to generate question' });
  }
};

const answerQuestion = async (req, res) => {
  try {
    const result = await interviewService.submitAnswer({ sessionId: req.params.sessionId, answer: req.body.answer });
    res.json(result);
  } catch (err) {
    res.status(err.status || 500).json({ error: err.message || 'Failed to evaluate answer' });
  }
};

const finalAnalysis = async (req, res) => {
  try {
    const finalResult = await interviewService.getFinalAnalysis(req.params.sessionId);
    res.json({ success: true, finalResult });
  } catch (err) {
    res.status(err.status || 500).json({ error: err.message || 'Final analysis failed' });
  }
};

const history = async (req, res) => {
  const interviews = await interviewService.getInterviewHistory(req.user.userId);
  res.json({ success: true, interviews });
};

const getSession = async (req, res) => {
  const session = await interviewService.getInterviewById(req.params.sessionId, req.user.userId);
  if (!session) {
    return res.status(404).json({ error: 'Interview not found' });
  }

  res.json({ success: true, interview: session });
};

module.exports = {
  summarizeRepos,
  startInterview,
  firstQuestion,
  answerQuestion,
  finalAnalysis,
  history,
  getSession,
};
