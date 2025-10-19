// Standardized validation error messages
const VALIDATION_MESSAGES = {
  // Required field errors
  REQUIRED_FIELD: (field) => `${field} is required`,
  REQUIRED_FIELDS: (fields) => `${fields.join(', ')} are required`,
  
  // Format validation errors
  INVALID_EMAIL: 'Invalid email format',
  INVALID_PHONE: 'Invalid phone number format',
  INVALID_URL: 'Invalid URL format',
  INVALID_DATE: 'Invalid date format',
  INVALID_NUMBER: (field) => `${field} must be a valid number`,
  INVALID_INTEGER: (field) => `${field} must be an integer`,
  INVALID_POSITIVE_NUMBER: (field) => `${field} must be a positive number`,
  INVALID_NON_NEGATIVE_NUMBER: (field) => `${field} must be a non-negative number`,
  
  // Length validation errors
  MIN_LENGTH: (field, min) => `${field} must be at least ${min} characters`,
  MAX_LENGTH: (field, max) => `${field} must not exceed ${max} characters`,
  EXACT_LENGTH: (field, length) => `${field} must be exactly ${length} characters`,
  
  // Range validation errors
  MIN_VALUE: (field, min) => `${field} must be at least ${min}`,
  MAX_VALUE: (field, max) => `${field} must not exceed ${max}`,
  VALUE_RANGE: (field, min, max) => `${field} must be between ${min} and ${max}`,
  
  // Business logic validation errors
  ALREADY_EXISTS: (field) => `${field} already exists`,
  NOT_FOUND: (field) => `${field} not found`,
  INVALID_STATUS_TRANSITION: (from, to) => `Invalid status transition from ${from} to ${to}`,
  INVALID_DATE_RANGE: 'End date must be after start date',
  MATCH_BEFORE_TOURNAMENT: (tournamentDate) => `Match cannot be started before tournament start date (${tournamentDate})`,
  
  // Authorization errors
  UNAUTHORIZED: 'Authentication required',
  FORBIDDEN: 'Not allowed to perform this action',
  NOT_OWNER: 'Not allowed to modify this resource',
  NOT_CAPTAIN: 'Only team captain can perform this action',
  NOT_TOURNAMENT_OWNER: 'Not allowed to modify this tournament',
  NOT_MATCH_PARTICIPANT: 'Not allowed to start/end this match',
  
  // Data integrity errors
  CANNOT_DELETE_WITH_DEPENDENCIES: 'Cannot delete resource with existing dependencies',
  CANNOT_UPDATE_AFTER_START: 'Cannot update after match has started',
  CANNOT_DELETE_AFTER_START: 'Cannot delete after match has started',
  CANNOT_ADD_TEAMS_AFTER_START: 'Cannot add teams once tournament has started',
  CANNOT_UPDATE_TEAMS_AFTER_START: 'Cannot update teams once tournament has started',
  CANNOT_DELETE_TEAMS_AFTER_START: 'Cannot delete teams once tournament has started',
  
  // Server errors
  SERVER_ERROR: 'Server error',
  DATABASE_ERROR: 'Database error',
  VALIDATION_ERROR: 'Validation error',
  
  // Success messages
  CREATED_SUCCESS: (resource) => `${resource} created successfully`,
  UPDATED_SUCCESS: (resource) => `${resource} updated successfully`,
  DELETED_SUCCESS: (resource) => `${resource} deleted successfully`,
  OPERATION_SUCCESS: (operation) => `${operation} completed successfully`,
};

// Helper function to get validation message
const getValidationMessage = (key, ...args) => {
  const message = VALIDATION_MESSAGES[key];
  if (typeof message === 'function') {
    return message(...args);
  }
  return message;
};

// Helper function to create standardized error response
const createErrorResponse = (message, statusCode = 400) => {
  return {
    error: message,
    status: statusCode
  };
};

// Helper function to create standardized success response
const createSuccessResponse = (message, data = null) => {
  const response = { message };
  if (data) {
    response.data = data;
  }
  return response;
};

module.exports = {
  VALIDATION_MESSAGES,
  getValidationMessage,
  createErrorResponse,
  createSuccessResponse,
};
