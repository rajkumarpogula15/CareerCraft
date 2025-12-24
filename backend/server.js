require('dotenv').config();

const express = require('express');
const cors = require('cors');

const githubAuth = require('./routes/githubAuth');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/auth/github', githubAuth);

app.get('/', (req, res) => {
  res.json({ message: 'CareerCraft backend running' });
});

// Server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
