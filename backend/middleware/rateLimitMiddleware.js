const slowDown = require('express-slow-down');
const rateLimit = require('express-rate-limit');
const { logger } = require('../utils/logger');

// Normalized key generator for IPv4 and IPv6
const defaultKeyGenerator = (req) => {
  const ip = req.ip.replace(/^::ffff:/, '').trim();
  return req.user?.id || ip;
};

// Rate limit configurations
const rateLimitConfigs = {
  auth: {
    windowMs: 15 * 60 * 1000,
    max: 1000,
    message: {
      success: false,
      error: {
        message: "Too many authentication attempts. Please try again later.",
        code: "RATE_LIMIT_EXCEEDED",
        type: "rate_limit",
        retryAfter: Math.ceil((15 * 60 * 1000) / 1000)
      }
    },
    standardHeaders: true,
    legacyHeaders: false,
    skipSuccessfulRequests: false,
    skipFailedRequests: false,
    handler: (req, res) => {
      logger.warn("Rate limit exceeded for auth endpoint", {
        ip: req.ip,
        path: req.path,
        method: req.method,
        security: true,
        event: "rate_limit_exceeded"
      });
      res.status(429).json(rateLimitConfigs.auth.message);
    }
  },

  passwordReset: {
    windowMs: 15 * 60 * 1000,
    max: 3,
    message: {
      success: false,
      error: {
        message: "Too many password reset requests. Please try again later.",
        code: "RATE_LIMIT_EXCEEDED",
        type: "rate_limit",
        retryAfter: Math.ceil((15 * 60 * 1000) / 1000)
      }
    },
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res) => {
      logger.warn("Rate limit exceeded for password reset", {
        ip: req.ip,
        path: req.path,
        method: req.method,
        security: true,
        event: "rate_limit_exceeded"
      });
      res.status(429).json(rateLimitConfigs.passwordReset.message);
    }
  },

  tournament: {
    windowMs: 60 * 60 * 1000,
    max: 50,
    message: {
      success: false,
      error: {
        message: "Too many tournament creation requests. Please try again later.",
        code: "RATE_LIMIT_EXCEEDED",
        type: "rate_limit",
        retryAfter: Math.ceil((60 * 60 * 1000) / 1000)
      }
    },
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: (req) => defaultKeyGenerator(req),
    handler: (req, res) => {
      logger.warn("Rate limit exceeded for tournament creation", {
        userId: req.user?.id,
        ip: req.ip,
        path: req.path,
        method: req.method
      });
      res.status(429).json(rateLimitConfigs.tournament.message);
    }
  },

  liveScoring: {
    windowMs: 60 * 1000,
    max: 600,
    message: {
      success: false,
      error: {
        message: "Too many scoring requests. Please slow down.",
        code: "RATE_LIMIT_EXCEEDED",
        type: "rate_limit",
        retryAfter: Math.ceil((60 * 1000) / 1000)
      }
    },
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: (req) => defaultKeyGenerator(req),
    handler: (req, res) => {
      logger.warn("Rate limit exceeded for live scoring", {
        userId: req.user?.id,
        ip: req.ip,
        path: req.path,
        method: req.method
      });
      res.status(429).json(rateLimitConfigs.liveScoring.message);
    }
  },

  stats: {
    windowMs: 60 * 1000,
    max: 120,
    message: {
      success: false,
      error: {
        message: "Too many statistics requests. Please try again later.",
        code: "RATE_LIMIT_EXCEEDED",
        type: "rate_limit",
        retryAfter: Math.ceil((60 * 1000) / 1000)
      }
    },
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res) => {
      logger.info("Rate limit exceeded for stats endpoint", {
        ip: req.ip,
        path: req.path,
        method: req.method
      });
      res.status(429).json(rateLimitConfigs.stats.message);
    }
  },

  general: {
    windowMs: 60 * 1000,
    max: 300,
    message: {
      success: false,
      error: {
        message: "Too many requests. Please try again later.",
        code: "RATE_LIMIT_EXCEEDED",
        type: "rate_limit",
        retryAfter: Math.ceil((60 * 1000) / 1000)
      }
    },
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res) => {
      logger.info("Rate limit exceeded for general endpoint", {
        ip: req.ip,
        path: req.path,
        method: req.method
      });
      res.status(429).json(rateLimitConfigs.general.message);
    }
  }
};

// Speed limiters
const speedLimiters = {
  fileUpload: slowDown({
    windowMs: 60 * 1000,
    delayAfter: 10,
    delayMs: () => 500,
    maxDelayMs: 10000,
    skipFailedRequests: true,
    skipSuccessfulRequests: false,
    keyGenerator: (req) => defaultKeyGenerator(req)
  }),

  adminOps: slowDown({
    windowMs: 60 * 1000,
    delayAfter: 20,
    delayMs: () => 200,
    maxDelayMs: 5000,
    skipFailedRequests: true,
    skipSuccessfulRequests: false,
    keyGenerator: (req) => defaultKeyGenerator(req)
  }),

  search: slowDown({
    windowMs: 60 * 1000,
    delayAfter: 30,
    delayMs: () => 100,
    maxDelayMs: 3000,
    skipFailedRequests: true,
    skipSuccessfulRequests: false,
    keyGenerator: (req) => defaultKeyGenerator(req)
  })
};

// Dynamic limiter
const createDynamicRateLimit = (options = {}) => {
  const {
    windowMs = 60 * 1000,
    maxRequests = 100,
    increaseFactor = 1.5,
    maxWindowMs = 15 * 60 * 1000
  } = options;

  let currentWindowMs = windowMs;
  const requestCounts = new Map();

  return (req, res, next) => {
    const key = defaultKeyGenerator(req);
    const now = Date.now();

    for (const [storedKey, data] of requestCounts.entries()) {
      if (now - data.resetTime > currentWindowMs) {
        requestCounts.delete(storedKey);
      }
    }

    const userData = requestCounts.get(key) || { count: 0, resetTime: now };

    if (userData.count >= maxRequests) {
      currentWindowMs = Math.min(currentWindowMs * increaseFactor, maxWindowMs);

      logger.warn("Dynamic rate limit exceeded", {
        key,
        count: userData.count,
        newWindow: currentWindowMs,
        path: req.path,
        method: req.method,
        security: true,
        event: "dynamic_rate_limit"
      });

      return res.status(429).json({
        success: false,
        error: {
          message: "Rate limit exceeded. Window increased due to repeated violations.",
          code: "DYNAMIC_RATE_LIMIT_EXCEEDED",
          type: "rate_limit",
          retryAfter: Math.ceil(currentWindowMs / 1000)
        }
      });
    }

    userData.count++;
    userData.resetTime = now;
    requestCounts.set(key, userData);

    const remaining = Math.max(0, maxRequests - userData.count);
    const resetTime = userData.resetTime + currentWindowMs;

    res.set({
      "X-RateLimit-Limit": maxRequests,
      "X-RateLimit-Remaining": remaining,
      "X-RateLimit-Reset": Math.ceil(resetTime / 1000),
      "X-RateLimit-Window": `${currentWindowMs}ms`
    });

    next();
  };
};

// Middleware functions
const authRateLimit = rateLimit(rateLimitConfigs.auth);
const passwordResetRateLimit = rateLimit(rateLimitConfigs.passwordReset);
const tournamentRateLimit = rateLimit(rateLimitConfigs.tournament);
const liveScoringRateLimit = rateLimit(rateLimitConfigs.liveScoring);
const statsRateLimit = rateLimit(rateLimitConfigs.stats);
const generalRateLimit = rateLimit(rateLimitConfigs.general);

// Combined middleware
const combinedRateLimit = {
  auth: (req, res, next) => {
    speedLimiters.adminOps(req, res, (err) => {
      if (err) return next(err);
      authRateLimit(req, res, next);
    });
  },

  passwordReset: passwordResetRateLimit,

  tournament: (req, res, next) => {
    speedLimiters.adminOps(req, res, (err) => {
      if (err) return next(err);
      tournamentRateLimit(req, res, next);
    });
  },

  liveScoring: liveScoringRateLimit,

  stats: (req, res, next) => {
    speedLimiters.search(req, res, (err) => {
      if (err) return next(err);
      statsRateLimit(req, res, next);
    });
  },

  fileUpload: (req, res, next) => {
    speedLimiters.fileUpload(req, res, (err) => {
      if (err) return next(err);
      generalRateLimit(req, res, next);
    });
  },

  general: generalRateLimit
};

module.exports = {
  rateLimitConfigs,
  speedLimiters,
  createDynamicRateLimit,
  authRateLimit,
  passwordResetRateLimit,
  tournamentRateLimit,
  liveScoringRateLimit,
  statsRateLimit,
  generalRateLimit,
  combinedRateLimit
};
