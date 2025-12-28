require('dotenv').config();

const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db');

// Routes
const githubAuth = require('./routes/githubAuth');
const aiReadmeRoutes = require('./routes/geminiroutes');
const chatRoutes = require('./routes/repoChat');
const repositoryRoutes = require('./routes/repositories');
const activityRoutes = require('./routes/activity');
const interviewRoutes = require('./routes/interview');
const resumeRoutes = require('./routes/resume');

// Initialize app
const app = express();

// Connect Database
connectDB();

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/auth/github', githubAuth);
app.use('/ai/readme', aiReadmeRoutes);
app.use('/chat', chatRoutes);
app.use('/repositories', repositoryRoutes);
app.use('/activity', activityRoutes);
app.use('/interviews', interviewRoutes);
app.use('/resume', resumeRoutes);

// Health check
app.get('/', (req, res) => {
  res.json({ message: 'CareerCraft backend running' });
});

// Start server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
