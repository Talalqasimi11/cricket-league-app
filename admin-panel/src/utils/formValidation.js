/**
 * Form Validation Utilities for Admin Panel
 * Provides client-side validation before API calls
 */

/**
 * Validate phone number (E.164 format)
 * @param {string} phone - Phone number to validate
 * @returns {Object} {isValid: boolean, error: string}
 */
export function validatePhone(phone) {
  if (!phone || phone.trim() === '') {
    return { isValid: false, error: 'Phone number is required' };
  }

  // E.164 format: +[country code][number]
  const phoneRegex = /^\+?[1-9]\d{7,14}$/;
  
  if (!phoneRegex.test(phone.trim())) {
    return { 
      isValid: false, 
      error: 'Invalid phone number format. Use E.164 format (e.g., +1234567890)' 
    };
  }

  return { isValid: true, error: null };
}

/**
 * Validate email address
 * @param {string} email - Email to validate
 * @returns {Object} {isValid: boolean, error: string}
 */
export function validateEmail(email) {
  if (!email || email.trim() === '') {
    return { isValid: false, error: 'Email is required' };
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  
  if (!emailRegex.test(email.trim())) {
    return { isValid: false, error: 'Invalid email address' };
  }

  return { isValid: true, error: null };
}

/**
 * Validate required field
 * @param {any} value - Value to validate
 * @param {string} fieldName - Name of the field for error message
 * @returns {Object} {isValid: boolean, error: string}
 */
export function validateRequired(value, fieldName = 'This field') {
  if (value === null || value === undefined || value === '') {
    return { isValid: false, error: fieldName + ' is required' };
  }

  if (typeof value === 'string' && value.trim() === '') {
    return { isValid: false, error: fieldName + ' cannot be empty' };
  }

  return { isValid: true, error: null };
}

/**
 * Validate string length
 * @param {string} value - String to validate
 * @param {number} min - Minimum length
 * @param {number} max - Maximum length
 * @param {string} fieldName - Name of the field
 * @returns {Object} {isValid: boolean, error: string}
 */
export function validateLength(value, min, max, fieldName = 'Field') {
  if (!value) {
    return { isValid: true, error: null }; // Allow empty if not required
  }

  const length = value.trim().length;

  if (min && length < min) {
    return { 
      isValid: false, 
      error: fieldName + ' must be at least ' + min + ' characters' 
    };
  }

  if (max && length > max) {
    return { 
      isValid: false, 
      error: fieldName + ' cannot exceed ' + max + ' characters' 
    };
  }

  return { isValid: true, error: null };
}

/**
 * Validate number range
 * @param {number} value - Number to validate
 * @param {number} min - Minimum value
 * @param {number} max - Maximum value
 * @param {string} fieldName - Name of the field
 * @returns {Object} {isValid: boolean, error: string}
 */
export function validateRange(value, min, max, fieldName = 'Value') {
  if (value === null || value === undefined || value === '') {
    return { isValid: true, error: null }; // Allow empty if not required
  }

  const num = Number(value);

  if (isNaN(num)) {
    return { isValid: false, error: fieldName + ' must be a number' };
  }

  if (min !== null && num < min) {
    return { 
      isValid: false, 
      error: fieldName + ' must be at least ' + min 
    };
  }

  if (max !== null && num > max) {
    return { 
      isValid: false, 
      error: fieldName + ' cannot exceed ' + max 
    };
  }

  return { isValid: true, error: null };
}

/**
 * Validate date
 * @param {string} date - Date string to validate
 * @param {boolean} futureOnly - Must be future date
 * @param {string} fieldName - Name of the field
 * @returns {Object} {isValid: boolean, error: string}
 */
export function validateDate(date, futureOnly = false, fieldName = 'Date') {
  if (!date) {
    return { isValid: true, error: null }; // Allow empty if not required
  }

  const dateObj = new Date(date);

  if (isNaN(dateObj.getTime())) {
    return { isValid: false, error: 'Invalid date format' };
  }

  if (futureOnly && dateObj <= new Date()) {
    return { isValid: false, error: fieldName + ' must be in the future' };
  }

  return { isValid: true, error: null };
}

/**
 * Validate date range (end after start)
 * @param {string} startDate - Start date
 * @param {string} endDate - End date
 * @returns {Object} {isValid: boolean, error: string}
 */
export function validateDateRange(startDate, endDate) {
  if (!startDate || !endDate) {
    return { isValid: true, error: null };
  }

  const start = new Date(startDate);
  const end = new Date(endDate);

  if (isNaN(start.getTime()) || isNaN(end.getTime())) {
    return { isValid: false, error: 'Invalid date format' };
  }

  if (end <= start) {
    return { isValid: false, error: 'End date must be after start date' };
  }

  return { isValid: true, error: null };
}

/**
 * Validate team form data
 * @param {Object} formData - Form data to validate
 * @returns {Object} {isValid: boolean, errors: Object}
 */
export function validateTeamForm(formData) {
  const errors = {};

  // Team name validation
  const nameValidation = validateRequired(formData.team_name, 'Team name');
  if (!nameValidation.isValid) {
    errors.team_name = nameValidation.error;
  } else {
    const lengthValidation = validateLength(formData.team_name, 2, 50, 'Team name');
    if (!lengthValidation.isValid) {
      errors.team_name = lengthValidation.error;
    }
  }

  // Team location validation
  const locationValidation = validateRequired(formData.team_location, 'Team location');
  if (!locationValidation.isValid) {
    errors.team_location = locationValidation.error;
  } else {
    const lengthValidation = validateLength(formData.team_location, 2, 100, 'Team location');
    if (!lengthValidation.isValid) {
      errors.team_location = lengthValidation.error;
    }
  }

  return {
    isValid: Object.keys(errors).length === 0,
    errors
  };
}

/**
 * Validate tournament form data
 * @param {Object} formData - Form data to validate
 * @returns {Object} {isValid: boolean, errors: Object}
 */
export function validateTournamentForm(formData) {
  const errors = {};

  // Tournament name validation
  const nameValidation = validateRequired(formData.tournament_name, 'Tournament name');
  if (!nameValidation.isValid) {
    errors.tournament_name = nameValidation.error;
  }

  // Location validation
  const locationValidation = validateRequired(formData.location, 'Location');
  if (!locationValidation.isValid) {
    errors.location = locationValidation.error;
  }

  // Start date validation
  const startDateValidation = validateRequired(formData.start_date, 'Start date');
  if (!startDateValidation.isValid) {
    errors.start_date = startDateValidation.error;
  } else {
    const dateValidation = validateDate(formData.start_date, true, 'Start date');
    if (!dateValidation.isValid) {
      errors.start_date = dateValidation.error;
    }
  }

  // Overs validation
  if (formData.overs) {
    const oversValidation = validateRange(formData.overs, 1, 50, 'Overs');
    if (!oversValidation.isValid) {
      errors.overs = oversValidation.error;
    }
  }

  // Date range validation if both dates provided
  if (formData.start_date && formData.end_date) {
    const rangeValidation = validateDateRange(formData.start_date, formData.end_date);
    if (!rangeValidation.isValid) {
      errors.end_date = rangeValidation.error;
    }
  }

  return {
    isValid: Object.keys(errors).length === 0,
    errors
  };
}

/**
 * Validate user form data
 * @param {Object} formData - Form data to validate
 * @returns {Object} {isValid: boolean, errors: Object}
 */
export function validateUserForm(formData) {
  const errors = {};

  // Phone number validation
  const phoneValidation = validatePhone(formData.phone_number);
  if (!phoneValidation.isValid) {
    errors.phone_number = phoneValidation.error;
  }

  // Password validation (if creating new user)
  if (formData.password !== undefined) {
    const passwordValidation = validateLength(formData.password, 8, 128, 'Password');
    if (!passwordValidation.isValid) {
      errors.password = passwordValidation.error;
    }
  }

  return {
    isValid: Object.keys(errors).length === 0,
    errors
  };
}

/**
 * Display validation errors in form
 * @param {Object} errors - Validation errors object
 * @param {Function} setFieldError - Function to set field error (e.g., from formik)
 */
export function displayValidationErrors(errors, setFieldError) {
  Object.keys(errors).forEach(field => {
    if (setFieldError) {
      setFieldError(field, errors[field]);
    }
  });
}

export default {
  validatePhone,
  validateEmail,
  validateRequired,
  validateLength,
  validateRange,
  validateDate,
  validateDateRange,
  validateTeamForm,
  validateTournamentForm,
  validateUserForm,
  displayValidationErrors,
};
