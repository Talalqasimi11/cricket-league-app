// Standardized API response utilities

/**
 * Standardized success response format
 * @param {Object} res - Express response object
 * @param {number} statusCode - HTTP status code (default: 200)
 * @param {string} message - Success message
 * @param {Object} data - Response data (optional)
 * @param {Object} meta - Additional metadata (optional)
 */
const sendSuccess = (res, statusCode = 200, message = 'Success', data = null, meta = null) => {
  const response = {
    success: true,
    message,
    timestamp: new Date().toISOString()
  };

  if (data !== null) {
    response.data = data;
  }

  if (meta !== null) {
    response.meta = meta;
  }

  return res.status(statusCode).json(response);
};

/**
 * Standardized error response format
 * @param {Object} res - Express response object
 * @param {number} statusCode - HTTP status code (default: 400)
 * @param {string} message - Error message
 * @param {string} code - Error code (optional)
 * @param {Object} details - Additional error details (optional)
 */
const sendError = (res, statusCode = 400, message = 'An error occurred', code = null, details = null) => {
  const response = {
    success: false,
    error: {
      message,
      timestamp: new Date().toISOString()
    }
  };

  if (code !== null) {
    response.error.code = code;
  }

  if (details !== null) {
    response.error.details = details;
  }

  return res.status(statusCode).json(response);
};

/**
 * Standardized validation error response
 * @param {Object} res - Express response object
 * @param {string} message - Validation error message
 * @param {Object} validationErrors - Specific validation errors (optional)
 */
const sendValidationError = (res, message = 'Validation failed', validationErrors = null) => {
  const response = {
    success: false,
    error: {
      message,
      type: 'validation',
      timestamp: new Date().toISOString()
    }
  };

  if (validationErrors !== null) {
    response.error.validation = validationErrors;
  }

  return res.status(400).json(response);
};

/**
 * Standardized authentication error response
 * @param {Object} res - Express response object
 * @param {string} message - Authentication error message
 */
const sendAuthError = (res, message = 'Authentication required') => {
  return sendError(res, 401, message, 'AUTH_REQUIRED');
};

/**
 * Standardized authorization error response
 * @param {Object} res - Express response object
 * @param {string} message - Authorization error message
 */
const sendForbiddenError = (res, message = 'Access denied') => {
  return sendError(res, 403, message, 'ACCESS_DENIED');
};

/**
 * Standardized not found error response
 * @param {Object} res - Express response object
 * @param {string} resource - Resource that was not found
 */
const sendNotFoundError = (res, resource = 'Resource') => {
  return sendError(res, 404, `${resource} not found`, 'NOT_FOUND');
};

/**
 * Standardized server error response
 * @param {Object} res - Express response object
 * @param {string} message - Server error message
 * @param {Object} details - Error details (optional)
 */
const sendServerError = (res, message = 'Internal server error', details = null) => {
  return sendError(res, 500, message, 'SERVER_ERROR', details);
};

/**
 * Standardized paginated response
 * @param {Object} res - Express response object
 * @param {Array} data - Array of data items
 * @param {Object} pagination - Pagination metadata
 * @param {string} message - Success message (optional)
 */
const sendPaginatedResponse = (res, data, pagination, message = 'Data retrieved successfully') => {
  return sendSuccess(res, 200, message, data, { pagination });
};

/**
 * Standardized created response
 * @param {Object} res - Express response object
 * @param {Object} data - Created resource data
 * @param {string} message - Success message (optional)
 */
const sendCreated = (res, data, message = 'Resource created successfully') => {
  return sendSuccess(res, 201, message, data);
};

/**
 * Standardized updated response
 * @param {Object} res - Express response object
 * @param {Object} data - Updated resource data (optional)
 * @param {string} message - Success message (optional)
 */
const sendUpdated = (res, data = null, message = 'Resource updated successfully') => {
  return sendSuccess(res, 200, message, data);
};

/**
 * Standardized deleted response
 * @param {Object} res - Express response object
 * @param {string} message - Success message (optional)
 */
const sendDeleted = (res, message = 'Resource deleted successfully') => {
  return sendSuccess(res, 200, message);
};

module.exports = {
  sendSuccess,
  sendError,
  sendValidationError,
  sendAuthError,
  sendForbiddenError,
  sendNotFoundError,
  sendServerError,
  sendPaginatedResponse,
  sendCreated,
  sendUpdated,
  sendDeleted
};
