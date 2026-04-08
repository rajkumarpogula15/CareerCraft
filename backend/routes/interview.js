const express = require('express');
const requireAuth = require('../middleware/requireAuth');
const RepoSummary = require('../models/RepoSummary');
const User = require('../models/User');
const InterviewSession = require('../models/InterviewSession');

const {
  fetchReadme,
  fetchRepoStructure,
} = require('../services/github.service');

const {
  firstQuestionPrompt,
  nextQuestionPrompt,
  evaluateAnswerPrompt,
  finalAnalysisPrompt,
} = require('../services/gemini.prompts');

const {
  runGemini,
  summarizeRepo,
} = require('../services/gemini.service');

const router = express.Router();
const TOTAL_QUESTIONS = 10;

function safeParseGeminiJSON(raw, context = 'Gemini') {
  try {
    if (!raw || typeof raw !== 'string') {
      throw new Error('Empty Gemini response');
    }

    const cleaned = raw
      .replace(/```json\s*/i, '')
      .replace(/```/g, '')
      .trim();

    return JSON.parse(cleaned);
  } catch (err) {
    console.error(`${context} JSON parse failed`);
    console.error('Raw response:\n', raw);
    throw new Error(`${context} returned invalid JSON`);
  }
}

async function getSessionForUser(sessionId, userId) {
  return InterviewSession.findOne({
    _id: sessionId,
    userId,
  });
}

async function generateAndAppendFirstQuestion(session, repoSummaries) {
  const prompt = firstQuestionPrompt({
    repoSummaries,
    difficulty: session.difficulty,
  });

  const parsed = safeParseGeminiJSON(
    await runGemini(prompt, { purpose: 'question_generation' }),
    'First Question'
  );

  session.questions.push({
    index: 0,
    text: parsed.question,
    repoName: parsed.repoName,
    topic: parsed.topic,
  });

  session.status = 'in_progress';
  session.currentQuestionIndex = 0;
  await session.save();
}

router.post('/summarize-repos', requireAuth, async (req, res) => {
  const { repos } = req.body;

  if (!Array.isArray(repos) || repos.length < 1 || repos.length > 4) {
    return res.status(400).json({ error: 'Select 1 to 4 repositories' });
  }

  try {
    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ error: 'User not found' });

    const summaries = [];

    for (const repo of repos) {
      const existing = await RepoSummary.findOne({
        userId: user._id,
        repoId: repo.id,
      });

      if (
        existing &&
        new Date(existing.lastRepoUpdate).getTime() ===
          new Date(repo.updated_at).getTime()
      ) {
        summaries.push(existing);
        continue;
      }

      let readme = '';
      let structure = [];

      try {
        readme = await fetchReadme(
          user.username,
          repo.name,
          user.githubAccessToken
        );
      } catch {}

      try {
        structure = await fetchRepoStructure(
          user.username,
          repo.name,
          user.githubAccessToken
        );
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

      const saved = await RepoSummary.findOneAndUpdate(
        { userId: user._id, repoId: repo.id },
        {
          userId: user._id,
          repoId: repo.id,
          repoName: repo.name,
          description: repo.description || '',
          ...summary,
          lastRepoUpdate: repo.updated_at,
          summarizedAt: new Date(),
        },
        { upsert: true, new: true }
      );

      summaries.push(saved);
    }

    res.json({ success: true, summaries });
  } catch (err) {
    console.error('Repo summarization error:', err);
    res.status(500).json({ error: 'Failed to summarize repos' });
  }
});

router.post('/start', requireAuth, async (req, res) => {
  const { repoIds, difficulty } = req.body;

  if (!Array.isArray(repoIds) || repoIds.length < 1 || repoIds.length > 4) {
    return res.status(400).json({ error: 'Select 1 to 4 repositories' });
  }

  if (!['easy', 'medium', 'hard'].includes(difficulty)) {
    return res.status(400).json({ error: 'Invalid difficulty' });
  }

  try {
    const summaries = await RepoSummary.find({
      userId: req.user.userId,
      repoId: { $in: repoIds },
    });

    if (summaries.length !== repoIds.length) {
      return res
        .status(400)
        .json({ error: 'Some repositories are not summarized yet' });
    }

    const session = await InterviewSession.create({
      userId: req.user.userId,
      repos: summaries.map(s => ({
        repoId: s.repoId,
        repoName: s.repoName,
      })),
      difficulty,
      status: 'created',
      startedAt: new Date(),
    });

    res.json({ success: true, sessionId: session._id });
  } catch (err) {
    console.error('Start interview error:', err);
    res.status(500).json({ error: 'Failed to start interview' });
  }
});

router.post('/:sessionId/first-question', requireAuth, async (req, res) => {
  const session = await getSessionForUser(req.params.sessionId, req.user.userId);
  if (!session) return res.status(404).json({ error: 'Session not found' });

  if (session.questions.length > 0) {
    return res.json({
      questionIndex: session.currentQuestionIndex,
      question: session.questions[session.currentQuestionIndex]?.text || '',
    });
  }

  const repoSummaries = await RepoSummary.find({
    userId: session.userId,
    repoId: { $in: session.repos.map(r => r.repoId) },
  });

  await generateAndAppendFirstQuestion(session, repoSummaries);

  res.json({ questionIndex: 0, question: session.questions[0].text });
});

router.get('/:sessionId/resume', requireAuth, async (req, res) => {
  const session = await getSessionForUser(req.params.sessionId, req.user.userId);
  if (!session) return res.status(404).json({ error: 'Session not found' });

  if (session.status === 'completed') {
    return res.json({
      done: true,
      sessionId: session._id,
      status: session.status,
      progress: {
        answered: session.answers.length,
        total: TOTAL_QUESTIONS,
      },
    });
  }

  const repoSummaries = await RepoSummary.find({
    userId: session.userId,
    repoId: { $in: session.repos.map(r => r.repoId) },
  });

  if (session.questions.length === 0) {
    await generateAndAppendFirstQuestion(session, repoSummaries);
  }

  const index = session.currentQuestionIndex;
  const currentQuestion = session.questions[index];

  return res.json({
    done: false,
    sessionId: session._id,
    status: session.status,
    difficulty: session.difficulty,
    questionIndex: index,
    question: currentQuestion?.text || '',
    progress: {
      answered: session.answers.length,
      total: TOTAL_QUESTIONS,
    },
  });
});

router.post('/:sessionId/answer', requireAuth, async (req, res) => {
  const session = await getSessionForUser(req.params.sessionId, req.user.userId);
  if (!session) return res.status(404).json({ error: 'Session not found' });

  if (session.status === 'completed') {
    return res.status(400).json({ error: 'Interview already completed' });
  }

  const answerText = String(req.body.answer || '').trim();
  if (!answerText) {
    return res.status(400).json({ error: 'Answer is required' });
  }

  const index = session.currentQuestionIndex;
  const question = session.questions[index];
  if (!question?.text) {
    return res.status(400).json({ error: 'Current question missing' });
  }

  session.answers.push({ index, text: answerText });

  const evalPrompt = evaluateAnswerPrompt({
    question: question.text,
    answer: answerText,
    difficulty: session.difficulty,
  });

  const evalResult = safeParseGeminiJSON(
    await runGemini(evalPrompt, { purpose: 'answer_evaluation' }),
    'Answer Evaluation'
  );

  session.evaluations.push({ index, ...evalResult });

  if (index >= TOTAL_QUESTIONS - 1) {
    session.status = 'completed';
    session.completedAt = new Date();
    await session.save();
    return res.json({
      done: true,
      progress: {
        answered: session.answers.length,
        total: TOTAL_QUESTIONS,
      },
    });
  }

  const repoSummaries = await RepoSummary.find({
    userId: session.userId,
    repoId: { $in: session.repos.map(r => r.repoId) },
  });

  const nextPrompt = nextQuestionPrompt({
    repoSummaries,
    difficulty: session.difficulty,
    previousQuestions: session.questions,
    previousAnswers: session.answers,
    previousEvaluations: session.evaluations,
  });

  const nextQ = safeParseGeminiJSON(
    await runGemini(nextPrompt, { purpose: 'question_generation' }),
    'Next Question'
  );

  session.currentQuestionIndex += 1;
  session.questions.push({
    index: session.currentQuestionIndex,
    text: nextQ.question,
    repoName: nextQ.repoName,
    topic: nextQ.topic,
  });

  session.status = 'in_progress';
  await session.save();

  res.json({
    questionIndex: session.currentQuestionIndex,
    question: nextQ.question,
    progress: {
      answered: session.answers.length,
      total: TOTAL_QUESTIONS,
    },
  });
});

router.post('/:sessionId/final-analysis', requireAuth, async (req, res) => {
  try {
    const session = await getSessionForUser(req.params.sessionId, req.user.userId);
    if (!session) return res.status(404).json({ error: 'Session not found' });

    if (session.status !== 'completed') {
      return res
        .status(400)
        .json({ error: 'Interview not completed yet' });
    }

    if (session.finalResult?.overallScore !== undefined) {
      return res.json({ success: true, finalResult: session.finalResult });
    }

    const repoSummaries = await RepoSummary.find({
      userId: session.userId,
      repoId: { $in: session.repos.map(r => r.repoId) },
    });

    const prompt = finalAnalysisPrompt({
      repoSummaries,
      difficulty: session.difficulty,
      questions: session.questions,
      answers: session.answers,
      evaluations: session.evaluations,
    });

    const analysis = safeParseGeminiJSON(
      await runGemini(prompt, { purpose: 'final_analysis' }),
      'Final Analysis'
    );

    session.finalResult = analysis;
    await session.save();

    res.json({ success: true, finalResult: analysis });
  } catch (err) {
    console.error('Final analysis error:', err);
    res.status(500).json({ error: 'Final analysis failed' });
  }
});

router.get('/history', requireAuth, async (req, res) => {
  const interviews = await InterviewSession.find({
    userId: req.user.userId,
  })
    .select(
      'difficulty status startedAt completedAt finalResult repos currentQuestionIndex questions answers evaluations createdAt updatedAt'
    )
    .sort({ updatedAt: -1 });

  const normalized = interviews.map(interview => ({
    _id: interview._id,
    difficulty: interview.difficulty,
    status: interview.status,
    startedAt: interview.startedAt,
    completedAt: interview.completedAt,
    currentQuestionIndex: interview.currentQuestionIndex,
    questionCount: interview.questions?.length || 0,
    answerCount: interview.answers?.length || 0,
    progressText: `${interview.answers?.length || 0}/${TOTAL_QUESTIONS}`,
    finalResult: interview.finalResult || null,
    repos: interview.repos || [],
    hasFinalAnalysis: interview.finalResult?.overallScore !== undefined,
    createdAt: interview.createdAt,
    updatedAt: interview.updatedAt,
  }));

  res.json({ success: true, interviews: normalized });
});

router.delete('/:sessionId', requireAuth, async (req, res) => {
  const deleted = await InterviewSession.findOneAndDelete({
    _id: req.params.sessionId,
    userId: req.user.userId,
  });

  if (!deleted) {
    return res.status(404).json({ error: 'Interview not found' });
  }

  return res.json({ success: true });
});

router.get('/:sessionId', requireAuth, async (req, res) => {
  const session = await getSessionForUser(req.params.sessionId, req.user.userId);

  if (!session) {
    return res.status(404).json({ error: 'Interview not found' });
  }

  res.json({ success: true, interview: session });
});

module.exports = router;
