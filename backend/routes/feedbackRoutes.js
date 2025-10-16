const express = require('express');
const router = express.Router();
const rateLimit = require('express-rate-limit');
const { createFeedback } = require('../controllers/feedbackController');
const { verifyToken } = require('../middleware/authMiddleware');

// Allow anonymous but bind user when token provided
const feedbackLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 20 });

router.post('/', feedbackLimiter, (req, res, next) => {
  // Optionally attach user when Authorization header is present
  const auth = req.headers['authorization'] || '';
  if (!auth.startsWith('Bearer ')) return createFeedback(req, res);
  return verifyToken(req, res, () => createFeedback(req, res));
});

module.exports = router;
