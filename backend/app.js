const express = require('express');
const cors = require('cors');

const githubAuthRoutes = require('./routes/githubAuth');
const aiReadmeRoutes = require('./routes/geminiroutes');
const chatRoutes = require('./routes/repoChat');
const repositoryRoutes = require('./routes/repositories');
const activityRoutes = require('./routes/activity');
const interviewRoutes = require('./routes/interview');
const resumeRoutes = require('./routes/resume');

const app = express();

app.use(cors());
app.use(express.json());

app.use('/auth/github', githubAuthRoutes);
app.use('/ai/readme', aiReadmeRoutes);
app.use('/chat', chatRoutes);
app.use('/repositories', repositoryRoutes);
app.use('/activity', activityRoutes);
app.use('/interviews', interviewRoutes);
app.use('/resume', resumeRoutes);

app.get('/', (req, res) => {
  res.json({ message: 'CareerCraft backend running' });
});

module.exports = app;
