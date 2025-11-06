/**
 * Enhanced Validation Middleware
 * Provides comprehensive input validation for API requests
 */

const { getUserFriendlyMessage } = require('./errorMessages');

/**
 * Validate string field
 * @param {string} value - Value to validate
 * @param {Object} rules - Validation rules
 * @returns {Object} {isValid: boolean, error: string|null}
 */
function validateString(value, rules = {}) {
  const {
    required = false,
    minLength = null,
    maxLength = null,
    pattern = null,
    trim = true,
    allowEmpty = false,
  } = rules;

  // Handle required check
  if (required && (value === undefined || value === null)) {
    return { isValid: false, error: getUserFriendlyMessage('VALIDATION_REQUIRED_FIELD') };
  }

  // If not required and value is null/undefined, it's valid
  if (!required && (value === undefined || value === null)) {
    return { isValid: true, error: null };
  }

  // Convert to string and trim if requested
  let strValue = String(value);
  if (trim) {
    strValue = strValue.trim();
  }

  // Check if empty string is allowed
  if (!allowEmpty && strValue.length === 0) {
    return { isValid: false, error: 'Value cannot be empty' };
  }

  // Minimum length validation
  if (minLength !== null && strValue.length < minLength) {
    return {
      isValid: false,
      error: getUserFriendlyMessage('VALIDATION_STRING_TOO_SHORT', { min: minLength }),
    };
  }

  // Maximum length validation
  if (maxLength !== null && strValue.length > maxLength) {
    return {
      isValid: false,
      error: getUserFriendlyMessage('VALIDATION_STRING_TOO_LONG', { max: maxLength }),
    };
  }

  // Pattern validation (regex)
  if (pattern && !pattern.test(strValue)) {
    return { isValid: false, error: 'Value does not match required format' };
  }

  return { isValid: true, error: null, value: strValue };
}

/**
 * Validate numeric field
 * @param {any} value - Value to validate
 * @param {Object} rules - Validation rules
 * @returns {Object} {isValid: boolean, error: string|null, value: number|null}
 */
function validateNumber(value, rules = {}) {
  const {
    required = false,
    min = null,
    max = null,
    integer = false,
    positive = false,
    allowZero = true,
  } = rules;

  // Handle required check
  if (required && (value === undefined || value === null || value === '')) {
    return { isValid: false, error: getUserFriendlyMessage('VALIDATION_REQUIRED_FIELD') };
  }

  // If not required and value is null/undefined, it's valid
  if (!required && (value === undefined || value === null || value === '')) {
    return { isValid: true, error: null, value: null };
  }

  // Convert to number
  const numValue = Number(value);

  // Check if valid number
  if (isNaN(numValue)) {
    return { isValid: false, error: getUserFriendlyMessage('VALIDATION_INVALID_NUMBER') };
  }

  // Integer validation
  if (integer && !Number.isInteger(numValue)) {
    return { isValid: false, error: 'Value must be an integer' };
  }

  // Positive validation
  if (positive && numValue < 0) {
    return { isValid: false, error: 'Value must be positive' };
  }

  // Zero validation
  if (!allowZero && numValue === 0) {
    return { isValid: false, error: 'Value cannot be zero' };
  }

  // Minimum value validation
  if (min !== null && numValue < min) {
    return {
      isValid: false,
      error: getUserFriendlyMessage('VALIDATION_NUMBER_TOO_SMALL', { min }),
    };
  }

  // Maximum value validation
  if (max !== null && numValue > max) {
    return {
      isValid: false,
      error: getUserFriendlyMessage('VALIDATION_NUMBER_TOO_LARGE', { max }),
    };
  }

  return { isValid: true, error: null, value: numValue };
}

/**
 * Validate date field
 * @param {any} value - Value to validate
 * @param {Object} rules - Validation rules
 * @returns {Object} {isValid: boolean, error: string|null, value: Date|null}
 */
function validateDate(value, rules = {}) {
  const {
    required = false,
    minDate = null,
    maxDate = null,
    futureOnly = false,
    pastOnly = false,
  } = rules;

  // Handle required check
  if (required && (value === undefined || value === null || value === '')) {
    return { isValid: false, error: getUserFriendlyMessage('VALIDATION_REQUIRED_FIELD') };
  }

  // If not required and value is null/undefined, it's valid
  if (!required && (value === undefined || value === null || value === '')) {
    return { isValid: true, error: null, value: null };
  }

  // Parse date
  const dateValue = new Date(value);

  // Check if valid date
  if (isNaN(dateValue.getTime())) {
    return { isValid: false, error: getUserFriendlyMessage('VALIDATION_INVALID_DATE') };
  }

  const now = new Date();

  // Future only validation
  if (futureOnly && dateValue <= now) {
    return { isValid: false, error: 'Date must be in the future' };
  }

  // Past only validation
  if (pastOnly && dateValue >= now) {
    return { isValid: false, error: 'Date must be in the past' };
  }

  // Minimum date validation
  if (minDate && dateValue < new Date(minDate)) {
    return { isValid: false, error: `Date must be after ${minDate}` };
  }

  // Maximum date validation
  if (maxDate && dateValue > new Date(maxDate)) {
    return { isValid: false, error: `Date must be before ${maxDate}` };
  }

  return { isValid: true, error: null, value: dateValue };
}

/**
 * Validate phone number
 * @param {string} value - Phone number to validate
 * @param {Object} rules - Validation rules
 * @returns {Object} {isValid: boolean, error: string|null}
 */
function validatePhoneNumber(value, rules = {}) {
  const { required = false } = rules;

  if (required && !value) {
    return { isValid: false, error: getUserFriendlyMessage('VALIDATION_REQUIRED_FIELD') };
  }

  if (!required && !value) {
    return { isValid: true, error: null };
  }

  // E.164 format: +[country code][number]
  // Length: 10-15 digits after country code
  const phoneRegex = /^\+?[1-9]\d{7,14}$/;

  if (!phoneRegex.test(String(value).trim())) {
    return { isValid: false, error: getUserFriendlyMessage('AUTH_INVALID_PHONE') };
  }

  return { isValid: true, error: null, value: String(value).trim() };
}

/**
 * Validate email address
 * @param {string} value - Email to validate
 * @param {Object} rules - Validation rules
 * @returns {Object} {isValid: boolean, error: string|null}
 */
function validateEmail(value, rules = {}) {
  const { required = false } = rules;

  if (required && !value) {
    return { isValid: false, error: getUserFriendlyMessage('VALIDATION_REQUIRED_FIELD') };
  }

  if (!required && !value) {
    return { isValid: true, error: null };
  }

  // Basic email regex
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  if (!emailRegex.test(String(value).trim())) {
    return { isValid: false, error: getUserFriendlyMessage('VALIDATION_INVALID_EMAIL') };
  }

  return { isValid: true, error: null, value: String(value).trim().toLowerCase() };
}

/**
 * Express middleware factory for body validation
 * @param {Object} schema - Validation schema
 * @returns {Function} Express middleware
 */
function validateBody(schema) {
  return (req, res, next) => {
    const errors = {};
    const validated = {};

    for (const [field, rules] of Object.entries(schema)) {
      const value = req.body[field];
      let result;

      switch (rules.type) {
        case 'string':
          result = validateString(value, rules);
          break;
        case 'number':
          result = validateNumber(value, rules);
          break;
        case 'date':
          result = validateDate(value, rules);
          break;
        case 'phone':
          result = validatePhoneNumber(value, rules);
          break;
        case 'email':
          result = validateEmail(value, rules);
          break;
        default:
          result = { isValid: true, value: value };
      }

      if (!result.isValid) {
        errors[field] = result.error;
      } else if (result.value !== undefined) {
        validated[field] = result.value;
      }
    }

    if (Object.keys(errors).length > 0) {
      return res.status(400).json({
        success: false,
        error: {
          message: 'Validation failed',
          type: 'validation',
          validation: errors,
          timestamp: new Date().toISOString(),
        },
      });
    }

    // Add validated values to request
    req.validated = validated;
    next();
  };
}

/**
 * Express middleware factory for query parameter validation
 * @param {Object} schema - Validation schema
 * @returns {Function} Express middleware
 */
function validateQuery(schema) {
  return (req, res, next) => {
    const errors = {};
    const validated = {};

    for (const [field, rules] of Object.entries(schema)) {
      const value = req.query[field];
      let result;

      switch (rules.type) {
        case 'string':
          result = validateString(value, rules);
          break;
        case 'number':
          result = validateNumber(value, rules);
          break;
        case 'date':
          result = validateDate(value, rules);
          break;
        default:
          result = { isValid: true, value: value };
      }

      if (!result.isValid) {
        errors[field] = result.error;
      } else if (result.value !== undefined) {
        validated[field] = result.value;
      }
    }

    if (Object.keys(errors).length > 0) {
      return res.status(400).json({
        success: false,
        error: {
          message: 'Validation failed',
          type: 'validation',
          validation: errors,
          timestamp: new Date().toISOString(),
        },
      });
    }

    // Add validated values to request
    req.validatedQuery = validated;
    next();
  };
}

/**
 * Validate pagination parameters
 * @returns {Function} Express middleware
 */
function validatePagination() {
  return (req, res, next) => {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;

    // Validate page number
    if (page < 1) {
      return res.status(400).json({
        success: false,
        error: {
          message: 'Page number must be at least 1',
          type: 'validation',
          timestamp: new Date().toISOString(),
        },
      });
    }

    // Validate and cap limit
    const cappedLimit = Math.min(Math.max(1, limit), 100); // Min 1, Max 100

    req.pagination = {
      page,
      limit: cappedLimit,
      offset: (page - 1) * cappedLimit,
    };

    next();
  };
}

module.exports = {
  validateString,
  validateNumber,
  validateDate,
  validatePhoneNumber,
  validateEmail,
  validateBody,
  validateQuery,
  validatePagination,
};
