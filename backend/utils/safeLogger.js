/**
 * Safe logging utility to prevent sensitive data leaks
 * Sanitizes error messages and request data before logging
 */

// Fields that should never be logged
const SENSITIVE_FIELDS = [
  'password', 'password_hash', 'token', 'refresh_token', 'csrf_token',
  'phone_number', 'email', 'ssn', 'credit_card', 'api_key', 'secret',
  'authorization', 'cookie', 'x-api-key', 'x-auth-token'
];

// SQL error patterns that might contain sensitive data
const SQL_SENSITIVE_PATTERNS = [
  /password/i,
  /token/i,
  /phone/i,
  /email/i,
  /credit/i,
  /ssn/i,
  /secret/i
];

/**
 * Sanitizes an object by removing or masking sensitive fields
 * @param {Object} obj - Object to sanitize
 * @param {number} maxDepth - Maximum depth to traverse (default: 3)
 * @returns {Object} - Sanitized object
 */
const sanitizeObject = (obj, maxDepth = 3, currentDepth = 0) => {
  if (currentDepth >= maxDepth || obj === null || typeof obj !== 'object') {
    return obj;
  }

  if (Array.isArray(obj)) {
    return obj.map(item => sanitizeObject(item, maxDepth, currentDepth + 1));
  }

  const sanitized = {};
  for (const [key, value] of Object.entries(obj)) {
    const lowerKey = key.toLowerCase();
    
    // Check if field is sensitive
    const isSensitive = SENSITIVE_FIELDS.some(field => 
      lowerKey.includes(field.toLowerCase())
    );

    if (isSensitive) {
      sanitized[key] = '[REDACTED]';
    } else if (typeof value === 'object' && value !== null) {
      sanitized[key] = sanitizeObject(value, maxDepth, currentDepth + 1);
    } else {
      sanitized[key] = value;
    }
  }

  return sanitized;
};

/**
 * Sanitizes an error message to remove potentially sensitive information
 * @param {string} message - Error message to sanitize
 * @returns {string} - Sanitized error message
 */
const sanitizeErrorMessage = (message) => {
  if (typeof message !== 'string') {
    return '[Non-string error message]';
  }

  // Check for SQL sensitive patterns
  const hasSensitivePattern = SQL_SENSITIVE_PATTERNS.some(pattern => 
    pattern.test(message)
  );

  if (hasSensitivePattern) {
    return '[Error message contains potentially sensitive data]';
  }

  // Truncate very long messages
  if (message.length > 500) {
    return message.substring(0, 500) + '...[truncated]';
  }

  return message;
};

/**
 * Creates a safe logger that sanitizes data before logging
 * @param {Object} logger - Original logger instance
 * @returns {Object} - Safe logger with sanitized methods
 */
const createSafeLogger = (logger) => {
  if (!logger) {
    return {
      error: () => {},
      warn: () => {},
      info: () => {},
      debug: () => {}
    };
  }

  return {
    error: (message, data = {}) => {
      const sanitizedMessage = sanitizeErrorMessage(message);
      const sanitizedData = sanitizeObject(data);
      logger.error(sanitizedMessage, sanitizedData);
    },
    warn: (message, data = {}) => {
      const sanitizedMessage = sanitizeErrorMessage(message);
      const sanitizedData = sanitizeObject(data);
      logger.warn(sanitizedMessage, sanitizedData);
    },
    info: (message, data = {}) => {
      const sanitizedMessage = sanitizeErrorMessage(message);
      const sanitizedData = sanitizeObject(data);
      logger.info(sanitizedMessage, sanitizedData);
    },
    debug: (message, data = {}) => {
      const sanitizedMessage = sanitizeErrorMessage(message);
      const sanitizedData = sanitizeObject(data);
      logger.debug(sanitizedMessage, sanitizedData);
    }
  };
};

/**
 * Safely logs database errors without exposing sensitive information
 * @param {Object} logger - Logger instance
 * @param {string} context - Context where error occurred
 * @param {Error} error - Error object
 * @param {Object} additionalData - Additional data to log (will be sanitized)
 */
const logDatabaseError = (logger, context, error, additionalData = {}) => {
  const safeLogger = createSafeLogger(logger);
  
  const errorInfo = {
    context,
    errorCode: error.code || 'UNKNOWN',
    errorType: error.name || 'Error',
    ...additionalData
  };

  // Don't include the raw error message as it might contain sensitive data
  safeLogger.error(`${context}: Database error`, errorInfo);
};

/**
 * Safely logs request errors without exposing sensitive request data
 * @param {Object} logger - Logger instance
 * @param {string} context - Context where error occurred
 * @param {Error} error - Error object
 * @param {Object} req - Request object (will be sanitized)
 * @param {Object} additionalData - Additional data to log (will be sanitized)
 */
const logRequestError = (logger, context, error, req, additionalData = {}) => {
  const safeLogger = createSafeLogger(logger);
  
  const errorInfo = {
    context,
    errorCode: error.code || 'UNKNOWN',
    errorType: error.name || 'Error',
    userId: req.user?.id || null,
    method: req.method,
    path: req.path,
    ...additionalData
  };

  safeLogger.error(`${context}: Request error`, errorInfo);
};

module.exports = {
  sanitizeObject,
  sanitizeErrorMessage,
  createSafeLogger,
  logDatabaseError,
  logRequestError
};
