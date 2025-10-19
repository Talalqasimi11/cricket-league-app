/**
 * Standardized error message mapping for user-friendly responses
 */

const ERROR_MESSAGES = {
  // Authentication errors
  AUTH_REQUIRED: "Please log in to access this feature",
  AUTH_INVALID_TOKEN: "Your session has expired. Please log in again",
  AUTH_INVALID_CREDENTIALS: "Invalid phone number or password",
  AUTH_ACCOUNT_LOCKED: "Account temporarily locked due to multiple failed attempts. Please try again later",
  AUTH_PHONE_ALREADY_EXISTS: "This phone number is already registered",
  AUTH_PHONE_NOT_FOUND: "No account found with this phone number",
  AUTH_WEAK_PASSWORD: "Password must be at least 8 characters long",
  AUTH_INVALID_PHONE: "Please enter a valid phone number",
  
  // Team errors
  TEAM_NOT_FOUND: "Team not found",
  TEAM_ACCESS_DENIED: "You don't have permission to access this team",
  TEAM_ALREADY_EXISTS: "You already have a team",
  TEAM_CANNOT_DELETE_TOURNAMENT: "Cannot delete team that is participating in tournaments",
  TEAM_CANNOT_DELETE_MATCHES: "Cannot delete team that has match history",
  TEAM_CAPTAIN_SAME_AS_VICE: "Captain and Vice Captain must be different players",
  TEAM_CAPTAIN_NOT_IN_TEAM: "Captain must be a member of this team",
  TEAM_VICE_CAPTAIN_NOT_IN_TEAM: "Vice Captain must be a member of this team",
  
  // Player errors
  PLAYER_NOT_FOUND: "Player not found",
  PLAYER_ACCESS_DENIED: "You don't have permission to access this player",
  PLAYER_ALREADY_EXISTS: "Player with this name already exists in your team",
  PLAYER_INVALID_ROLE: "Please select a valid player role",
  PLAYER_NAME_REQUIRED: "Player name is required",
  PLAYER_NAME_TOO_SHORT: "Player name must be at least 2 characters long",
  PLAYER_NAME_TOO_LONG: "Player name cannot exceed 50 characters",
  
  // Tournament errors
  TOURNAMENT_NOT_FOUND: "Tournament not found",
  TOURNAMENT_ACCESS_DENIED: "You don't have permission to access this tournament",
  TOURNAMENT_ALREADY_STARTED: "Cannot modify tournament that has already started",
  TOURNAMENT_TEAM_ALREADY_ADDED: "This team is already added to the tournament",
  TOURNAMENT_TEAM_LIMIT_REACHED: "Maximum number of teams reached for this tournament",
  TOURNAMENT_INVALID_DATES: "Tournament end date must be after start date",
  TOURNAMENT_NAME_REQUIRED: "Tournament name is required",
  TOURNAMENT_LOCATION_REQUIRED: "Tournament location is required",
  
  // Match errors
  MATCH_NOT_FOUND: "Match not found",
  MATCH_ACCESS_DENIED: "You don't have permission to access this match",
  MATCH_ALREADY_STARTED: "Cannot modify match that has already started",
  MATCH_ALREADY_ENDED: "Cannot modify match that has already ended",
  MATCH_INVALID_TEAMS: "Match must have two different teams",
  MATCH_INVALID_DATETIME: "Match date and time must be in the future",
  MATCH_SCORING_UNAUTHORIZED: "You are not authorized to score for this match",
  
  // Live scoring errors
  INNINGS_NOT_FOUND: "Innings not found",
  INNINGS_ALREADY_ENDED: "Innings has already ended",
  INNINGS_NOT_IN_PROGRESS: "Innings is not in progress",
  BALL_ALREADY_EXISTS: "Ball already exists for this position",
  BALL_INVALID_SEQUENCE: "Invalid ball sequence. Please score balls in order",
  BALL_INVALID_NUMBER: "Ball number must be between 1 and 6",
  BALL_INVALID_OVER: "Over number must be non-negative",
  BALL_INVALID_RUNS: "Runs must be between 0 and 6",
  
  // Validation errors
  VALIDATION_REQUIRED_FIELD: "This field is required",
  VALIDATION_INVALID_EMAIL: "Please enter a valid email address",
  VALIDATION_INVALID_PHONE: "Please enter a valid phone number",
  VALIDATION_INVALID_URL: "Please enter a valid URL",
  VALIDATION_INVALID_DATE: "Please enter a valid date",
  VALIDATION_INVALID_NUMBER: "Please enter a valid number",
  VALIDATION_NUMBER_TOO_SMALL: "Number must be greater than or equal to {min}",
  VALIDATION_NUMBER_TOO_LARGE: "Number must be less than or equal to {max}",
  VALIDATION_STRING_TOO_SHORT: "Text must be at least {min} characters long",
  VALIDATION_STRING_TOO_LONG: "Text cannot exceed {max} characters",
  
  // Database errors
  DATABASE_CONNECTION_ERROR: "Database connection error. Please try again later",
  DATABASE_CONSTRAINT_ERROR: "Operation failed due to data constraints",
  DATABASE_DUPLICATE_ENTRY: "This record already exists",
  DATABASE_FOREIGN_KEY_ERROR: "Cannot perform this operation due to related data",
  
  // Server errors
  SERVER_ERROR: "An unexpected error occurred. Please try again later",
  SERVER_TIMEOUT: "Request timed out. Please try again",
  SERVER_MAINTENANCE: "Server is under maintenance. Please try again later",
  
  // Network errors
  NETWORK_ERROR: "Network error. Please check your connection and try again",
  NETWORK_TIMEOUT: "Request timed out. Please check your connection",
  NETWORK_OFFLINE: "You are offline. Please check your connection",
  
  // File upload errors
  FILE_TOO_LARGE: "File is too large. Maximum size is {maxSize}",
  FILE_INVALID_TYPE: "Invalid file type. Allowed types: {allowedTypes}",
  FILE_UPLOAD_ERROR: "Failed to upload file. Please try again",
  
  // Rate limiting
  RATE_LIMIT_EXCEEDED: "Too many requests. Please wait before trying again",
  
  // Feedback errors
  FEEDBACK_MESSAGE_REQUIRED: "Feedback message is required",
  FEEDBACK_MESSAGE_TOO_SHORT: "Feedback message must be at least 5 characters long",
  FEEDBACK_MESSAGE_TOO_LONG: "Feedback message cannot exceed 1000 characters",
  FEEDBACK_INAPPROPRIATE_CONTENT: "Inappropriate content detected. Please use respectful language",
};

/**
 * Get user-friendly error message
 * @param {string} errorKey - The error key from ERROR_MESSAGES
 * @param {object} params - Parameters to replace in the message
 * @returns {string} User-friendly error message
 */
function getUserFriendlyMessage(errorKey, params = {}) {
  let message = ERROR_MESSAGES[errorKey] || ERROR_MESSAGES.SERVER_ERROR;
  
  // Replace parameters in the message
  Object.keys(params).forEach(key => {
    const placeholder = `{${key}}`;
    message = message.replace(new RegExp(placeholder, 'g'), params[key]);
  });
  
  return message;
}

/**
 * Map database error codes to user-friendly messages
 * @param {Error} error - Database error object
 * @returns {string} User-friendly error message
 */
function mapDatabaseError(error) {
  if (!error || !error.code) {
    return ERROR_MESSAGES.SERVER_ERROR;
  }
  
  switch (error.code) {
    case 'ER_DUP_ENTRY':
      return ERROR_MESSAGES.DATABASE_DUPLICATE_ENTRY;
    case 'ER_NO_REFERENCED_ROW_2':
    case 'ER_ROW_IS_REFERENCED_2':
      return ERROR_MESSAGES.DATABASE_FOREIGN_KEY_ERROR;
    case 'ER_CONNECTION_LOST':
    case 'ER_CONNECTION_KILLED':
      return ERROR_MESSAGES.DATABASE_CONNECTION_ERROR;
    case 'ER_DATA_TOO_LONG':
      return ERROR_MESSAGES.VALIDATION_STRING_TOO_LONG;
    case 'ER_BAD_NULL_ERROR':
      return ERROR_MESSAGES.VALIDATION_REQUIRED_FIELD;
    default:
      return ERROR_MESSAGES.SERVER_ERROR;
  }
}

/**
 * Map HTTP status codes to user-friendly messages
 * @param {number} statusCode - HTTP status code
 * @returns {string} User-friendly error message
 */
function mapHttpError(statusCode) {
  switch (statusCode) {
    case 400:
      return ERROR_MESSAGES.VALIDATION_REQUIRED_FIELD;
    case 401:
      return ERROR_MESSAGES.AUTH_INVALID_TOKEN;
    case 403:
      return ERROR_MESSAGES.AUTH_ACCESS_DENIED;
    case 404:
      return ERROR_MESSAGES.SERVER_ERROR; // Generic 404 message
    case 409:
      return ERROR_MESSAGES.DATABASE_DUPLICATE_ENTRY;
    case 422:
      return ERROR_MESSAGES.VALIDATION_REQUIRED_FIELD;
    case 429:
      return ERROR_MESSAGES.RATE_LIMIT_EXCEEDED;
    case 500:
      return ERROR_MESSAGES.SERVER_ERROR;
    case 503:
      return ERROR_MESSAGES.SERVER_MAINTENANCE;
    default:
      return ERROR_MESSAGES.SERVER_ERROR;
  }
}

module.exports = {
  ERROR_MESSAGES,
  getUserFriendlyMessage,
  mapDatabaseError,
  mapHttpError,
};
