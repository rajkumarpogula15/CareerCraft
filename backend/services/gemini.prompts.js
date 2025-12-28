function firstQuestionPrompt({ repoSummaries, difficulty }) {
  return `
You are a senior technical interviewer.

Candidate projects:
${JSON.stringify(repoSummaries, null, 2)}

Difficulty: ${difficulty}

Task:
- Ask ONE project-based interview question
- This is the FIRST question
- It should be broad and introductory
- Focus on understanding the project and candidate's role
- Do NOT ask multiple questions
- Do NOT include answers

Return JSON only:
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
You are continuing a mock interview.

Candidate projects:
${JSON.stringify(repoSummaries, null, 2)}

Difficulty: ${difficulty}

Questions already asked:
${JSON.stringify(previousQuestions, null, 2)}

Candidate answers:
${JSON.stringify(previousAnswers, null, 2)}

Answer evaluations:
${JSON.stringify(previousEvaluations, null, 2)}

Task:
- Ask ONE next interview question
- Do NOT repeat topics
- Adapt depth based on last answer quality
- Stay within project context
- One concept only

Return JSON only:
{
  "question": "",
  "repoName": "",
  "topic": ""
}
`;
}

function evaluateAnswerPrompt({ question, answer, difficulty }) {
  return `
You are evaluating a mock interview answer.

Question:
${question}

Candidate Answer:
${answer}

Difficulty: ${difficulty}

Evaluate briefly.

Return JSON only:
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
You are a senior technical interviewer completing a mock interview.

Candidate projects:
${JSON.stringify(repoSummaries, null, 2)}

Interview difficulty: ${difficulty}

Interview transcript:

Questions:
${JSON.stringify(questions, null, 2)}

Answers:
${JSON.stringify(answers, null, 2)}

Answer evaluations:
${JSON.stringify(evaluations, null, 2)}

Task:
- Analyze the interview as a whole
- Identify consistent patterns
- Be fair and constructive
- Do NOT judge based on one answer
- Base insights only on the provided data

Return JSON ONLY in this exact format:
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
