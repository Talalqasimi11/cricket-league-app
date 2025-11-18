const winston = require('winston');
const DailyRotateFile = require('winston-daily-rotate-file');
const { sanitizeObject } = require('./safeLogger');
require('winston-daily-rotate-file');

// Safe stringify function that sanitizes objects before stringifying
const safeStringify = (obj) => {
  try {
    const sanitized = sanitizeObject(obj);
    return JSON.stringify(sanitized);
  } catch (e) {
    return '[CIRCULAR_OR_INVALID_OBJECT]';
  }
};

// Custom log format
const customFormat = winston.format.combine(
  winston.format.timestamp(),
  winston.format.errors({ stack: true }),
  winston.format.printf(({ timestamp, level, message, stack, ...meta }) => {
    const metaStr = Object.keys(meta).length > 0 ? ` ${safeStringify(meta)}` : '';
    const stackStr = stack ? `\n${stack}` : '';
    return `${timestamp} [${level.toUpperCase()}]: ${message}${metaStr}${stackStr}`;
  })
);

// Error log filter
const errorFilter = winston.format((info) => {
  return info.level === 'error' ? info : false;
});

// Combined log filter
const combinedFilter = winston.format((info) => {
  return info.level !== 'error' ? info : false;
});

// Create winston logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: customFormat,
  defaultMeta: { service: 'cricket-league-api' },
  transports: [
    // Console transport for development
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        customFormat
      )
    }),

    // Error log file - rotates daily
    new DailyRotateFile({
      filename: 'logs/error-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      maxSize: '20m',
      maxFiles: '14d',
      level: 'error',
      format: winston.format.combine(
        errorFilter(),
        customFormat
      )
    }),

    // Combined log file - rotates daily
    new DailyRotateFile({
      filename: 'logs/combined-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      maxSize: '20m',
      maxFiles: '30d',
      format: winston.format.combine(
        combinedFilter(),
        customFormat
      )
    }),

    // Security events log - separate file for audit
    new DailyRotateFile({
      filename: 'logs/security-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      maxSize: '20m',
      maxFiles: '90d',
      level: 'warn',
      format: winston.format.combine(
        winston.format((info) => {
          return info.security || info.audit ? info : false;
        })(),
        customFormat
      )
    })
  ],

  // Handle exceptions and rejections
  exceptionHandlers: [
    new DailyRotateFile({
      filename: 'logs/exceptions-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      maxSize: '20m',
      maxFiles: '30d'
    })
  ],
  rejectionHandlers: [
    new DailyRotateFile({
      filename: 'logs/rejections-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      maxSize: '20m',
      maxFiles: '30d'
    })
  ]
});

// Handle uncaught exceptions and unhandled rejections
process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

// Request logging middleware factory
const createRequestLogger = (options = {}) => {
  const {
    logAllRequests = true,
    logErrors = true,
    logPerformance = true,
    excludePaths = ['/health', '/favicon.ico'],
    slowRequestThreshold = 1000 // ms
  } = options;

  return (req, res, next) => {
    const startTime = Date.now();
    const originalSend = res.send;
    let responseBody;

    // Capture response body for logging
    res.send = function(body) {
      responseBody = body;
      return originalSend.call(this, body);
    };

    // Log request when it finishes
    res.on('finish', () => {
      const duration = Date.now() - startTime;
      const isSlow = duration > slowRequestThreshold;

      // Skip excluded paths
      if (excludePaths.includes(req.path)) {
        return;
      }

      // Log all requests or only errors/slow requests
      if (logAllRequests || res.statusCode >= 400 || isSlow) {
        const logLevel = res.statusCode >= 500 ? 'error' :
                        res.statusCode >= 400 ? 'warn' : 'info';

        const logData = {
          method: req.method,
          url: req.originalUrl,
          status: res.statusCode,
          duration: `${duration}ms`,
          userAgent: req.get('User-Agent'),
          ip: req.ip || req.connection.remoteAddress,
          userId: req.user?.id,
          requestId: req.id || req.headers['x-request-id']
        };

        // Add performance warning for slow requests
        if (isSlow && logPerformance) {
          logData.slow = true;
          logData.threshold = `${slowRequestThreshold}ms`;
        }

        // Log error details for server errors
        if (res.statusCode >= 500 && logErrors && responseBody) {
          try {
            const responseJson = JSON.parse(responseBody);
            logData.error = responseJson.error || responseJson.message;
          } catch (e) {
            logData.error = responseBody.substring(0, 200);
          }
        }

        logger.log(logLevel, `${req.method} ${req.originalUrl}`, logData);
      }
    });

    next();
  };
};

// Specialized loggers for different concerns
const securityLogger = {
  logFailedLogin: (data) => logger.warn('Failed login attempt', { ...data, security: true, event: 'failed_login' }),
  logSuspiciousActivity: (data) => logger.warn('Suspicious activity detected', { ...data, security: true, event: 'suspicious_activity' }),
  logPasswordReset: (data) => logger.info('Password reset requested', { ...data, security: true, event: 'password_reset' }),
  logAdminAction: (data) => logger.info('Admin action performed', { ...data, audit: true, event: 'admin_action' })
};

const performanceLogger = {
  logSlowQuery: (query, duration, params = {}) => {
    logger.warn('Slow database query', {
      query: query.substring(0, 500), // Truncate long queries
      duration: `${duration}ms`,
      parameters: Object.keys(params).length,
      performance: true,
      event: 'slow_query'
    });
  },
  logMemoryUsage: (usage) => {
    logger.info('Memory usage', { ...usage, performance: true, event: 'memory_usage' });
  }
};

const auditLogger = {
  logTournamentCreation: (data) => logger.info('Tournament created', { ...data, audit: true, event: 'tournament_created' }),
  logMatchStarted: (data) => logger.info('Match started', { ...data, audit: true, event: 'match_started' }),
  logScoreModified: (data) => logger.info('Score modified', { ...data, audit: true, event: 'score_modified' }),
  logTeamModified: (data) => logger.info('Team modified', { ...data, audit: true, event: 'team_modified' })
};

// Middleware for route-level auditing
const auditMiddleware = (action, getDetails = () => {}) => {
  return (req, res, next) => {
    res.on('finish', () => {
      if (res.statusCode >= 200 && res.statusCode < 400) {
        const details = getDetails(req, res);
        auditLogger.logAdminAction({
          action,
          userId: req.user?.id,
          userIP: req.ip,
          ...details
        });
      }
    });
    next();
  };
};

module.exports = {
  logger,
  createRequestLogger,
  securityLogger,
  performanceLogger,
  auditLogger,
  auditMiddleware
};
