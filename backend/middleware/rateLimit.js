const rateLimit = require("express-rate-limit");

// Custom rate limiter factory
const createRateLimiter = (requests, windowSeconds, message) => {
  return rateLimit({
    windowMs: windowSeconds * 1000, // Convert seconds to milliseconds
    max: requests,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: message || `Too many requests from this IP, please try again later.` },
    handler: (req, res) => {
      res.status(429).json({
        error: message || `Too many requests from this IP, please try again later.`,
        retryAfter: windowSeconds
      });
    }
  });
};

// Predefined rate limiters
const rateLimiter = (requests = 100, windowSeconds = 60, message = null) => {
  return createRateLimiter(requests, windowSeconds, message);
};

// Specific rate limiters for different endpoints
const registerRateLimiter = createRateLimiter(
  10, // 10 requests
  3600, // per hour (1 hour = 3600 seconds)
  "Too many registration attempts, please try again later"
);

const loginRateLimiter = createRateLimiter(
  10, // 10 requests
  900, // per 15 minutes (15 min = 900 seconds)
  "Too many login attempts, please try again in 15 minutes"
);

const forgotPasswordRateLimiter = createRateLimiter(
  5, // 5 requests
  900, // per 15 minutes
  "Too many password reset requests, please try again in 15 minutes"
);

const changePasswordRateLimiter = createRateLimiter(
  10, // 10 requests
  900, // per 15 minutes
  "Too many password change attempts, please try again in 15 minutes"
);

module.exports = {
  rateLimiter,
  registerRateLimiter,
  loginRateLimiter,
  forgotPasswordRateLimiter,
  changePasswordRateLimiter,
  createRateLimiter
};


