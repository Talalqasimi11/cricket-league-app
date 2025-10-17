const express = require('express');
const router = express.Router();
const { registerCaptain, loginCaptain, refreshToken, logout, requestPasswordReset, verifyPasswordReset, confirmPasswordReset, changePassword, changePhoneNumber, clearAuthFailures } = require('../controllers/authController');
const { verifyToken } = require('../middleware/authMiddleware');
const rateLimit = require('express-rate-limit');

// Rate limits adjusted for development/testing
const registerLimiter = rateLimit({ windowMs: 60 * 60 * 1000, max: 100 }); // 100 per hour
const loginLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 50 }); // 50 per 15 minutes
const forgotLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 20 }); // 20 per 15 minutes
const changeLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 30 }); // 30 per 15 minutes

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
router.post('/clear-auth-failures', clearAuthFailures);

module.exports = router;
