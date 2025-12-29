function firstQuestionPrompt({ repoSummaries, difficulty }) {
  return `
You are a friendly senior technical interviewer speaking to a junior developer (less than 2 years experience).

Candidate projects:
${JSON.stringify(repoSummaries, null, 2)}

Difficulty: ${difficulty}

Task:
- Ask ONLY ONE introductory, project-based question
- This is the FIRST question of the interview
- Keep it beginner-friendly and conversational
- Focus on:
  - What the project does
  - What the candidate personally worked on
- Do NOT ask follow-ups or multiple parts
- Question must be SHORT (2–4 lines max)
- Avoid deep technical jargon
- Do NOT include answers or hints

Return JSON ONLY:
{
  "question": "",
  "repoName": "",
  "topic": ""
}
`;
}

function nextQuestionPrompt({
  repoSummaries,
  difficulty,
  previousQuestions,
  previousAnswers,
  previousEvaluations,
}) {
  return `
You are continuing a mock interview with a junior developer (less than 2 years experience).

Candidate projects:
${JSON.stringify(repoSummaries, null, 2)}

Difficulty: ${difficulty}

Previously asked questions:
${JSON.stringify(previousQuestions, null, 2)}

Candidate answers:
${JSON.stringify(previousAnswers, null, 2)}

Answer evaluations:
${JSON.stringify(previousEvaluations, null, 2)}

Task:
- Ask ONLY ONE follow-up question
- Keep it friendly and easy to understand
- Question length: 2–4 lines MAX
- Stay within the SAME project context
- Cover ONE concept only
- Do NOT repeat previous topics
- Adjust difficulty gently:
  - If last answer was weak → simpler clarification
  - If strong → slightly deeper but still junior-level
- Avoid system design or advanced architecture

Return JSON ONLY:
{
  "question": "",
  "repoName": "",
  "topic": ""
}
`;
}

function evaluateAnswerPrompt({ question, answer, difficulty }) {
  return `
You are evaluating a junior developer’s interview answer.

Question:
${question}

Candidate Answer:
${answer}

Difficulty: ${difficulty}

Evaluation rules:
- Be lenient and junior-friendly
- Focus on understanding, not perfection
- Keep notes brief and constructive

Return JSON ONLY:
{
  "correctness": "low | medium | high",
  "clarity": "low | medium | high",
  "notes": ""
}
`;
}

function finalAnalysisPrompt({
  repoSummaries,
  difficulty,
  questions,
  answers,
  evaluations,
}) {
  return `
You are a senior interviewer summarizing a junior-level mock interview.

Candidate projects:
${JSON.stringify(repoSummaries, null, 2)}

Interview difficulty: ${difficulty}

Interview transcript:

Questions:
${JSON.stringify(questions, null, 2)}

Answers:
${JSON.stringify(answers, null, 2)}

Evaluations:
${JSON.stringify(evaluations, null, 2)}

Task:
- Review performance holistically
- Identify patterns across answers
- Be supportive and realistic for <2 years experience
- Do NOT penalize for missing advanced knowledge
- Base analysis ONLY on provided data

Return JSON ONLY in this EXACT format:
{
  "overallScore": number,
  "strongAreas": [],
  "weakAreas": [],
  "improvements": [],
  "suggestedDifficulty": "easy | medium | hard"
}
`;
}

module.exports = {
  firstQuestionPrompt,
  nextQuestionPrompt,
  evaluateAnswerPrompt,
  finalAnalysisPrompt,
};
