const express = require('express');
const router = express.Router();
const { registerCaptain, loginCaptain, refreshToken, logout, requestPasswordReset, verifyPasswordReset, confirmPasswordReset, changePassword, changePhoneNumber, clearAuthFailures } = require('../controllers/authController');
const { verifyToken } = require('../middleware/authMiddleware');
const rateLimit = require('express-rate-limit');

// Rate limits configurable via environment variables with safe production defaults
const parseRateLimit = (envVar, defaultWindow, defaultMax) => {
  const value = process.env[envVar];
  if (!value) return { windowMs: defaultWindow, max: defaultMax };
  
  const [max, window] = value.split('/');
  const windowMs = window ? parseInt(window) * 1000 : defaultWindow;
  return { windowMs, max: parseInt(max) || defaultMax };
};

const registerLimiter = rateLimit({
  ...parseRateLimit('REGISTER_RATE_LIMIT', 60 * 60 * 1000, 10), // 10 per hour in production
  standardHeaders: true,
  legacyHeaders: false,
});
const loginLimiter = rateLimit({
  ...parseRateLimit('LOGIN_RATE_LIMIT', 15 * 60 * 1000, 10), // 10 per 15 minutes in production
  standardHeaders: true,
  legacyHeaders: false,
});
const forgotLimiter = rateLimit({
  ...parseRateLimit('FORGOT_RATE_LIMIT', 15 * 60 * 1000, 5), // 5 per 15 minutes in production
  standardHeaders: true,
  legacyHeaders: false,
});
const changeLimiter = rateLimit({
  ...parseRateLimit('CHANGE_RATE_LIMIT', 15 * 60 * 1000, 10), // 10 per 15 minutes in production
  standardHeaders: true,
  legacyHeaders: false,
});

// Register new captain
router.post('/register', registerLimiter, registerCaptain);

// Login existing captain
router.post('/login', loginLimiter, loginCaptain);

// Refresh access token
router.post('/refresh', refreshToken);

// Logout
router.post('/logout', logout);

// Forgot / Reset Password
router.post('/forgot-password', forgotLimiter, requestPasswordReset);
// Optional verify endpoint
router.post('/verify-reset', forgotLimiter, verifyPasswordReset);
router.post('/reset-password', forgotLimiter, confirmPasswordReset);

// Account management
router.put('/change-password', verifyToken, changeLimiter, changePassword);
router.put('/change-phone', verifyToken, changeLimiter, changePhoneNumber);

// Test cleanup (development only)
if (process.env.NODE_ENV !== 'production') {
  router.post('/clear-auth-failures', clearAuthFailures);
}

module.exports = router;
