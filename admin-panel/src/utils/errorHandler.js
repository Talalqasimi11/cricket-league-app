/**
 * Admin Panel Error Handler
 * Provides consistent error handling and user-friendly messaging
 */

/**
 * Parse API error response and extract user-friendly message
 * @param {Error} error - Error object from API call
 * @returns {string} User-friendly error message
 */
export function getErrorMessage(error) {
  // Network error
  if (!error.response) {
    if (error.message === 'Network Error' || error.code === 'ERR_NETWORK') {
      return 'Network error. Please check your internet connection and try again.';
    }
    return 'Unable to connect to server. Please try again later.';
  }

  const { status, data } = error.response;

  // Try to extract error message from response
  const errorMessage = data?.error?.message || data?.error || data?.message || null;

  // Handle specific status codes
  switch (status) {
    case 400:
      return errorMessage || 'Invalid request data. Please check your input.';
    
    case 401:
      return 'Your session has expired. Please log in again.';
    
    case 403:
      return errorMessage || 'You do not have permission to perform this action.';
    
    case 404:
      return errorMessage || 'The requested resource was not found.';
    
    case 409:
      return errorMessage || 'This record already exists.';
    
    case 422:
      // Validation errors - try to extract field-specific errors
      if (data?.error?.validation) {
        const validationErrors = Object.entries(data.error.validation)
          .map(([field, message]) => `${field}: ${message}`)
          .join(', ');
        return `Validation failed: ${validationErrors}`;
      }
      return errorMessage || 'Validation failed. Please check your input.';
    
    case 429:
      return 'Too many requests. Please wait a moment before trying again.';
    
    case 500:
      return 'An internal server error occurred. Please try again or contact support.';
    
    case 503:
      return 'Service temporarily unavailable. Please try again in a few moments.';
    
    default:
      return errorMessage || 'An unexpected error occurred (' + status + '). Please try again.';
  }
}

/**
 * Check if error is a network error (no response from server)
 * @param {Error} error - Error object
 * @returns {boolean} True if network error
 */
export function isNetworkError(error) {
  return !error.response || error.message === 'Network Error' || error.code === 'ERR_NETWORK';
}

/**
 * Check if error is retryable
 * @param {Error} error - Error object
 * @returns {boolean} True if error can be retried
 */
export function isRetryableError(error) {
  if (isNetworkError(error)) {
    return true;
  }

  const status = error.response?.status;
  
  // Retry on server errors and rate limiting
  return status === 429 || status === 500 || status === 503;
}

/**
 * Check if error requires logout (authentication)
 * @param {Error} error - Error object
 * @returns {boolean} True if should logout
 */
export function shouldLogout(error) {
  return error.response?.status === 401;
}

/**
 * Extract validation errors from error response
 * @param {Error} error - Error object
 * @returns {Object|null} Validation errors object or null
 */
export function getValidationErrors(error) {
  const data = error.response?.data;
  
  if (data?.error?.validation) {
    return data.error.validation;
  }
  
  return null;
}

/**
 * Format validation errors for display
 * @param {Object} validationErrors - Validation errors object
 * @returns {string} Formatted error message
 */
export function formatValidationErrors(validationErrors) {
  if (!validationErrors || typeof validationErrors !== 'object') {
    return '';
  }

  return Object.entries(validationErrors)
    .map(([field, message]) => {
      // Convert field names to readable format (e.g., team_name -> Team Name)
      const readableField = field
        .split('_')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1))
        .join(' ');
      
      return readableField + ': ' + message;
    })
    .join('\n');
}

/**
 * Log error to console in development, to error service in production
 * @param {Error} error - Error object
 * @param {string} context - Context where error occurred
 */
export function logError(error, context = '') {
  const isDevelopment = process.env.NODE_ENV === 'development';

  if (isDevelopment) {
    console.error('Error in ' + context + ':', {
      message: error.message,
      status: error.response?.status,
      data: error.response?.data,
      stack: error.stack,
    });
  } else {
    // In production, send to error tracking service
    // Example: Sentry, LogRocket, etc.
    console.error('Error in ' + context + ':', error.message);
    
    // TODO: Integrate with error tracking service
    // if (window.Sentry) {
    //   window.Sentry.captureException(error, {
    //     tags: { context },
    //     extra: {
    //       status: error.response?.status,
    //       responseData: error.response?.data,
    //     },
    //   });
    // }
  }
}

/**
 * Global error handler for API responses
 * Use with axios interceptor
 */
export function setupGlobalErrorHandler(axiosInstance, onUnauthorized, onToast) {
  axiosInstance.interceptors.response.use(
    (response) => response,
    (error) => {
      // Log error
      logError(error, 'API Request');

      // Handle 401 - redirect to login
      if (shouldLogout(error)) {
        if (onUnauthorized) {
          onUnauthorized();
        }
      }

      // Show toast for user-facing errors
      if (onToast && !shouldLogout(error)) {
        const message = getErrorMessage(error);
        onToast(message, 'error');
      }

      // Always reject to allow specific handling
      return Promise.reject(error);
    }
  );
}

export default {
  getErrorMessage,
  isNetworkError,
  isRetryableError,
  shouldLogout,
  getValidationErrors,
  formatValidationErrors,
  logError,
  setupGlobalErrorHandler,
};
