// API Configuration
export const API_CONFIG = {
  BASE_URL: process.env.REACT_APP_API_URL || 'http://localhost:5000/api',
  TIMEOUT: 10000, // 10 seconds
  RETRY_ATTEMPTS: 3,
  RETRY_DELAY: 1000 // 1 second
};

// API Endpoints
export const API_ENDPOINTS = {
  // Auth
  AUTH_LOGIN: '/auth/login',
  AUTH_LOGOUT: '/auth/logout',
  AUTH_REFRESH: '/auth/refresh',
  
  // Admin
  ADMIN_DASHBOARD: '/admin/dashboard',
  ADMIN_USERS: '/admin/users',
  ADMIN_USERS_ADMIN: '/admin/users/:userId/admin',
  ADMIN_USERS_DELETE: '/admin/users/:userId',
  ADMIN_TEAMS: '/admin/teams',
  ADMIN_TEAMS_DETAIL: '/admin/teams/:teamId',
  ADMIN_TEAMS_UPDATE: '/admin/teams/:teamId',
  ADMIN_TEAMS_DELETE: '/admin/teams/:teamId',
  
  // Teams
  TEAMS: '/teams',
  TEAMS_MY: '/teams/my-team',
  
  // Players
  PLAYERS: '/players',
  PLAYERS_TEAM: '/players/team/:teamId',
  
  // Tournaments
  TOURNAMENTS: '/tournaments',
  TOURNAMENTS_DETAIL: '/tournaments/:tournamentId',
  TOURNAMENTS_UPDATE: '/tournaments/:tournamentId',
  TOURNAMENTS_DELETE: '/tournaments/:tournamentId',
  
  // Matches
  MATCHES: '/matches',
  MATCHES_TOURNAMENT: '/tournament-matches',
  MATCHES_DETAIL: '/tournament-matches/:matchId',
  
  // Health
  HEALTH: '/health',
  HEALTH_LIVE: '/health/live',
  HEALTH_READY: '/health/ready',
};

// Status Enums
export const STATUS = {
  // Match Status
  MATCH_NOT_STARTED: 'not_started',
  MATCH_LIVE: 'live',
  MATCH_COMPLETED: 'completed',
  MATCH_ABANDONED: 'abandoned',
  
  // Tournament Status
  TOURNAMENT_UPCOMING: 'upcoming',
  TOURNAMENT_NOT_STARTED: 'not_started',
  TOURNAMENT_LIVE: 'live',
  TOURNAMENT_COMPLETED: 'completed',
  TOURNAMENT_ABANDONED: 'abandoned',
  
  // Generic Status
  PENDING: 'pending',
  ACTIVE: 'active',
  INACTIVE: 'inactive',
  ARCHIVED: 'archived'
};

// Tournament Match Status
export const TOURNAMENT_MATCH_STATUS = {
  UPCOMING: 'upcoming',
  LIVE: 'live',
  FINISHED: 'finished'
};

// Player Roles
export const PLAYER_ROLES = {
  BATSMAN: 'Batsman',
  BOWLER: 'Bowler',
  ALL_ROUNDER: 'All-rounder',
  WICKET_KEEPER: 'Wicket-keeper'
};

// HTTP Status Codes
export const HTTP_STATUS = {
  OK: 200,
  CREATED: 201,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  INTERNAL_ERROR: 500,
  SERVICE_UNAVAILABLE: 503
};

// Error Messages
export const ERROR_MESSAGES = {
  // Network
  NETWORK_ERROR: 'Network connection failed. Please check your internet connection.',
  TIMEOUT_ERROR: 'Request timed out. Please try again.',
  SERVER_ERROR: 'Server error. Please try again later.',
  
  // Authentication
  UNAUTHORIZED: 'Unauthorized access. Please log in again.',
  FORBIDDEN: 'Access denied. You do not have permission to perform this action.',
  TOKEN_EXPIRED: 'Session expired. Please log in again.',
  
  // Validation
  VALIDATION_ERROR: 'Please check your input and try again.',
  REQUIRED_FIELD: 'This field is required.',
  INVALID_EMAIL: 'Invalid email format.',
  INVALID_PHONE: 'Invalid phone number format.',
  
  // Data
  NOT_FOUND: 'The requested resource was not found.',
  DUPLICATE: 'This resource already exists.',
  DELETE_FAILED: 'Failed to delete resource.',
  UPDATE_FAILED: 'Failed to update resource.',
  
  // Generic
  UNKNOWN_ERROR: 'An unknown error occurred. Please try again.'
};

// Success Messages
export const SUCCESS_MESSAGES = {
  LOGIN_SUCCESS: 'Logged in successfully!',
  LOGOUT_SUCCESS: 'Logged out successfully!',
  CREATE_SUCCESS: 'Created successfully!',
  UPDATE_SUCCESS: 'Updated successfully!',
  DELETE_SUCCESS: 'Deleted successfully!',
  DATA_LOADED: 'Data loaded successfully!',
  ACTION_SUCCESS: 'Action completed successfully!'
};

// Validation Rules
export const VALIDATION = {
  PHONE_REGEX: /^\+[1-9]\d{1,14}$/,
  EMAIL_REGEX: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
  PASSWORD_MIN_LENGTH: 8,
  TEAM_NAME_MIN_LENGTH: 2,
  TEAM_NAME_MAX_LENGTH: 100,
  LOCATION_MIN_LENGTH: 2,
  LOCATION_MAX_LENGTH: 100,
  TOURNAMENT_NAME_MIN_LENGTH: 2,
  TOURNAMENT_NAME_MAX_LENGTH: 100
};

// Pagination
export const PAGINATION = {
  DEFAULT_PAGE_SIZE: 10,
  MAX_PAGE_SIZE: 100,
  PAGE_SIZE_OPTIONS: [10, 25, 50, 100]
};

// Date & Time
export const DATE_TIME = {
  DATE_FORMAT: 'YYYY-MM-DD',
  TIME_FORMAT: 'HH:mm:ss',
  DATETIME_FORMAT: 'YYYY-MM-DD HH:mm:ss',
  DISPLAY_DATE_FORMAT: 'MMM DD, YYYY',
  DISPLAY_DATETIME_FORMAT: 'MMM DD, YYYY HH:mm',
  TIMEZONE: 'UTC'
};

// Storage Keys
export const STORAGE_KEYS = {
  AUTH_TOKEN: 'admin_token',
  USER_DATA: 'admin_user',
  USER_PREFERENCES: 'admin_preferences',
  CACHED_DATA: 'admin_cache'
};

// Theme
export const THEME = {
  COLORS: {
    PRIMARY: '#4F46E5', // Indigo
    SUCCESS: '#10B981', // Green
    WARNING: '#F59E0B', // Amber
    ERROR: '#EF4444', // Red
    INFO: '#3B82F6', // Blue
    LIGHT: '#F3F4F6', // Light gray
    DARK: '#1F2937' // Dark gray
  }
};

// Notification Types
export const NOTIFICATION_TYPES = {
  SUCCESS: 'success',
  ERROR: 'error',
  WARNING: 'warning',
  INFO: 'info'
};

// Sort Options
export const SORT_OPTIONS = {
  ASC: 'asc',
  DESC: 'desc'
};

// Default Limits
export const LIMITS = {
  MAX_FILE_SIZE: 5 * 1024 * 1024, // 5MB
  MAX_TEXTAREA_LENGTH: 5000,
  MAX_INPUT_LENGTH: 255
};

// App Version
export const APP_VERSION = '1.0.0';
