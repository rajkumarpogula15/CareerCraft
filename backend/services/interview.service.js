const interviewRepository = require('../repositories/interview.repository');
const userRepository = require('../repositories/user.repository');
const { fetchReadme, fetchRepoStructure } = require('./github.service');
const { firstQuestionPrompt, nextQuestionPrompt, evaluateAnswerPrompt, finalAnalysisPrompt } = require('./gemini.prompts');
const { runGemini, summarizeRepo } = require('./gemini.service');

function safeParseGeminiJSON(raw, context = 'Gemini') {
  try {
    if (!raw || typeof raw !== 'string') {
      throw new Error('Empty Gemini response');
    }

    const cleaned = raw.replace(/```json\s*/i, '').replace(/```/g, '').trim();
    return JSON.parse(cleaned);
  } catch (err) {
    throw new Error(`${context} returned invalid JSON`);
  }
}

const summarizeRepos = async ({ userId, repos }) => {
  const user = await userRepository.findById(userId);
  if (!user) throw Object.assign(new Error('User not found'), { status: 404 });

  const summaries = [];

  for (const repo of repos) {
    const existing = await interviewRepository.findRepoSummary(user._id, repo.id);
    if (existing && new Date(existing.lastRepoUpdate).getTime() === new Date(repo.updated_at).getTime()) {
      summaries.push(existing);
      continue;
    }

    let readme = '';
    let structure = [];

    try {
      readme = await fetchReadme(user.username, repo.name, user.githubAccessToken);
    } catch {}

    try {
      structure = await fetchRepoStructure(user.username, repo.name, user.githubAccessToken);
    } catch {}

    if (!readme && structure.length === 0) {
      throw new Error(`Repo "${repo.name}" has no usable data`);
    }

    const summary = await summarizeRepo({
      repoName: repo.name,
      description: repo.description || '',
      readme,
      structure,
    });

    const saved = await interviewRepository.upsertRepoSummary(user._id, repo.id, {
      repoName: repo.name,
      description: repo.description || '',
      ...summary,
      lastRepoUpdate: repo.updated_at,
      summarizedAt: new Date(),
    });

    summaries.push(saved);
  }

  return summaries;
};

const startInterview = async ({ userId, repoIds, difficulty }) => {
  const summaries = await interviewRepository.findRepoSummariesByRepoIds(userId, repoIds);
  if (summaries.length !== repoIds.length) {
    throw Object.assign(new Error('Some repositories are not summarized yet'), { status: 400 });
  }

  const session = await interviewRepository.createInterviewSession({
    userId,
    repos: summaries.map(s => ({ repoId: s.repoId, repoName: s.repoName })),
    difficulty,
    status: 'created',
    startedAt: new Date(),
  });

  return session;
};

const generateFirstQuestion = async sessionId => {
  const session = await interviewRepository.findInterviewById(sessionId);
  if (!session) throw Object.assign(new Error('Session not found'), { status: 404 });

  const repoSummaries = await interviewRepository.findRepoSummariesByRepoIds(
    session.userId,
    session.repos.map(r => r.repoId)
  );

  const prompt = firstQuestionPrompt({ repoSummaries, difficulty: session.difficulty });
  const parsed = safeParseGeminiJSON(await runGemini(prompt), 'First Question');

  session.questions.push({ index: 0, text: parsed.question, repoName: parsed.repoName, topic: parsed.topic });
  session.status = 'in_progress';
  session.currentQuestionIndex = 0;
  await session.save();

  return { questionIndex: 0, question: parsed.question };
};

const submitAnswer = async ({ sessionId, answer }) => {
  const session = await interviewRepository.findInterviewById(sessionId);
  if (!session) throw Object.assign(new Error('Session not found'), { status: 404 });

  const index = session.currentQuestionIndex;
  session.answers.push({ index, text: answer });

  const evalPrompt = evaluateAnswerPrompt({
    question: session.questions[index].text,
    answer,
    difficulty: session.difficulty,
  });

  const evalResult = safeParseGeminiJSON(await runGemini(evalPrompt), 'Answer Evaluation');
  session.evaluations.push({ index, ...evalResult });

  if (index === 9) {
    session.status = 'completed';
    session.completedAt = new Date();
    await session.save();
    return { done: true };
  }

  const repoSummaries = await interviewRepository.findRepoSummariesByRepoIds(
    session.userId,
    session.repos.map(r => r.repoId)
  );

  const nextPrompt = nextQuestionPrompt({
    repoSummaries,
    difficulty: session.difficulty,
    previousQuestions: session.questions,
    previousAnswers: session.answers,
    previousEvaluations: session.evaluations,
  });

  const nextQ = safeParseGeminiJSON(await runGemini(nextPrompt), 'Next Question');

  session.currentQuestionIndex += 1;
  session.questions.push({
    index: session.currentQuestionIndex,
    text: nextQ.question,
    repoName: nextQ.repoName,
    topic: nextQ.topic,
  });

  await session.save();

  return {
    questionIndex: session.currentQuestionIndex,
    question: nextQ.question,
  };
};

const getFinalAnalysis = async sessionId => {
  const session = await interviewRepository.findInterviewById(sessionId);
  if (!session) throw Object.assign(new Error('Session not found'), { status: 404 });

  if (session.status !== 'completed') {
    throw Object.assign(new Error('Interview not completed yet'), { status: 400 });
  }

  if (session.finalResult?.overallScore !== undefined) {
    return session.finalResult;
  }

  const repoSummaries = await interviewRepository.findRepoSummariesByRepoIds(
    session.userId,
    session.repos.map(r => r.repoId)
  );

  const prompt = finalAnalysisPrompt({
    repoSummaries,
    difficulty: session.difficulty,
    questions: session.questions,
    answers: session.answers,
    evaluations: session.evaluations,
  });

  const analysis = safeParseGeminiJSON(await runGemini(prompt), 'Final Analysis');
  session.finalResult = analysis;
  await session.save();

  return analysis;
};

const getInterviewHistory = userId => interviewRepository.findInterviewHistory(userId);
const getInterviewById = (sessionId, userId) => interviewRepository.findInterviewForUser(sessionId, userId);

module.exports = {
  summarizeRepos,
  startInterview,
  generateFirstQuestion,
  submitAnswer,
  getFinalAnalysis,
  getInterviewHistory,
  getInterviewById,
};
