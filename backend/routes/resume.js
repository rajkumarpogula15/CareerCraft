const express = require('express');
const Resume = require('../models/Resume');
const requireAuth = require('../middleware/requireAuth');
const { runGemini } = require('../services/gemini.service');

const router = express.Router();

function cleanList(values) {
  return [...new Set((values || []).map(v => String(v || '').trim()).filter(Boolean))];
}

function extractJson(raw) {
  return String(raw || '')
    .replace(/```json/gi, '')
    .replace(/```/g, '')
    .trim();
}

/* ================= GET RESUME ================= */

router.get('/', requireAuth, async (req, res) => {
  try {
    const resume = await Resume.findOne({ userId: req.user.userId }).lean();
    res.json(resume || null);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch resume' });
  }
});

/* ================= SAVE / UPDATE RESUME ================= */

router.post('/', requireAuth, async (req, res) => {
  try {
    // Normalize education Percentage / grade field
    if (Array.isArray(req.body.education)) {
      req.body.education = req.body.education.map((edu) => ({
        ...edu,
        Percentage: edu.Percentage ?? edu.grade ?? '',
      }));
    }

    const resume = await Resume.findOneAndUpdate(
      { userId: req.user.userId },
      {
        ...req.body,
        userId: req.user.userId,
      },
      {
        upsert: true,
        new: true,
        runValidators: true,
        setDefaultsOnInsert: true,
      }
    );

    res.json({ success: true, resume });
  } catch (err) {
    res.status(500).json({ success: false });
  }
});

router.post('/ai-summary', requireAuth, async (req, res) => {
  try {
    const profile = req.body.profile || {};
    const experience = Array.isArray(req.body.experience) ? req.body.experience : [];
    const skills = cleanList(req.body.skills);
    const repos = Array.isArray(req.body.repos) ? req.body.repos : [];
    const selectedProjects = repos.filter(repo => repo['included'] == true);

    const prompt = `
You are an expert resume writer.

Write ONE concise professional summary for a software resume.
The summary must be:
- 2 to 3 sentences
- ATS-friendly
- recruiter-focused
- clear and factual
- editable by the user

Use only the context below. Do not invent metrics or experience.

Profile:
- Name: ${profile.name || 'N/A'}
- Title: ${profile.title || 'N/A'}
- Location: ${profile.location || 'N/A'}

Skills:
${skills.length ? skills.map(skill => `- ${skill}`).join('\n') : '- None provided'}

Experience:
${experience.length ? experience.map(item => `- ${item.role || 'Role'} at ${item.company || 'Company'} (${item.duration || 'Duration'}): ${item.description || 'No description'}`).join('\n') : '- None provided'}

Selected GitHub Projects:
${selectedProjects.length ? selectedProjects.map(item => `- ${item.name || 'Project'}: ${item.description || 'No description'} | Language: ${item.language || 'Unknown'} | Points: ${(item.bulletPoints || []).join('; ') || 'None'}`).join('\n') : '- None selected'}

Return only the summary text.
`.trim();

    const summary = await runGemini(prompt, { purpose: 'repo_summary' });
    return res.json({ summary: summary.trim() });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Failed to generate summary' });
  }
});

router.post('/skill-suggestions', requireAuth, async (req, res) => {
  try {
    const repos = Array.isArray(req.body.repos) ? req.body.repos : [];
    const currentSkills = cleanList(req.body.currentSkills);
    const selectedProjects = repos.filter(repo => repo['included'] == true);

    const prompt = `
You are an expert ATS resume advisor for software engineers.

Based on the project context below, suggest exactly 8 resume skills.
Rules:
- prioritize tools, frameworks, languages, platforms, and engineering skills
- avoid duplicates or near-duplicates
- avoid soft skills
- keep each skill short
- include skills that improve resume quality and ATS matching

Current skills:
${currentSkills.length ? currentSkills.map(skill => `- ${skill}`).join('\n') : '- None provided'}

Project context:
${selectedProjects.length ? selectedProjects.map(item => `- ${item.name || 'Project'}: ${item.description || 'No description'} | Language: ${item.language || 'Unknown'} | Points: ${(item.bulletPoints || []).join('; ') || 'None'}`).join('\n') : repos.map(item => `- ${item.name || 'Project'}: ${item.description || 'No description'} | Language: ${item.language || 'Unknown'}`).join('\n') || '- None provided'}

Return strict JSON only:
{"skills":["skill 1","skill 2"]}
`.trim();

    const raw = await runGemini(prompt, { purpose: 'repo_summary' });
    const parsed = JSON.parse(extractJson(raw));
    return res.json({ skills: cleanList(parsed.skills).slice(0, 8) });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Failed to suggest skills' });
  }
});

module.exports = router;
