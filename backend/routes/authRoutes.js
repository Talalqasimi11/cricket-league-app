const express = require('express');
const router = express.Router();
const { registerCaptain, loginCaptain, refreshToken, logout, requestPasswordReset, verifyPasswordReset, confirmPasswordReset, changePassword, changePhoneNumber } = require('../controllers/authController');
const { verifyToken } = require('../middleware/authMiddleware');
const rateLimit = require('express-rate-limit');

// Basic rate limit for register as well to avoid abuse
const registerLimiter = rateLimit({ windowMs: 60 * 60 * 1000, max: 20 });
const loginLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 10 });
const forgotLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 5 });
const changeLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 10 });

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

module.exports = router;
