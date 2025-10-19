// lib/utils/inputValidation.js

/**
 * Validates and normalizes numeric parameters from request params
 * @param {string} value - The parameter value to validate
 * @param {string} paramName - The name of the parameter for error messages
 * @returns {number} - The validated and normalized number
 * @throws {Error} - If the parameter is invalid
 */
const validateNumericParam = (value, paramName) => {
  if (!value) {
    throw new Error(`${paramName} is required`);
  }
  
  const num = Number(value);
  
  if (isNaN(num)) {
    throw new Error(`${paramName} must be a valid number`);
  }
  
  if (!Number.isInteger(num)) {
    throw new Error(`${paramName} must be an integer`);
  }
  
  if (num <= 0) {
    throw new Error(`${paramName} must be a positive number`);
  }
  
  return num;
};

/**
 * Validates and normalizes numeric parameters from request params (allows zero)
 * @param {string} value - The parameter value to validate
 * @param {string} paramName - The name of the parameter for error messages
 * @returns {number} - The validated and normalized number
 * @throws {Error} - If the parameter is invalid
 */
const validateNumericParamAllowZero = (value, paramName) => {
  if (!value && value !== 0) {
    throw new Error(`${paramName} is required`);
  }
  
  const num = Number(value);
  
  if (isNaN(num)) {
    throw new Error(`${paramName} must be a valid number`);
  }
  
  if (!Number.isInteger(num)) {
    throw new Error(`${paramName} must be an integer`);
  }
  
  if (num < 0) {
    throw new Error(`${paramName} must be a non-negative number`);
  }
  
  return num;
};

/**
 * Middleware to validate numeric parameters
 * @param {string[]} paramNames - Array of parameter names to validate
 * @param {boolean} allowZero - Whether to allow zero values (default: false)
 * @returns {Function} - Express middleware function
 */
const validateNumericParams = (paramNames, allowZero = false) => {
  return (req, res, next) => {
    try {
      for (const paramName of paramNames) {
        const value = req.params[paramName];
        if (allowZero) {
          req.params[`${paramName}_validated`] = validateNumericParamAllowZero(value, paramName);
        } else {
          req.params[`${paramName}_validated`] = validateNumericParam(value, paramName);
        }
      }
      next();
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }
  };
};

/**
 * Validates and normalizes a single numeric parameter from request params
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next function
 * @param {string} paramName - The name of the parameter to validate
 * @param {boolean} allowZero - Whether to allow zero values (default: false)
 */
const validateSingleNumericParam = (paramName, allowZero = false) => {
  return (req, res, next) => {
    try {
      const value = req.params[paramName];
      if (allowZero) {
        req.params[`${paramName}_validated`] = validateNumericParamAllowZero(value, paramName);
      } else {
        req.params[`${paramName}_validated`] = validateNumericParam(value, paramName);
      }
      next();
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }
  };
};

module.exports = {
  validateNumericParam,
  validateNumericParamAllowZero,
  validateNumericParams,
  validateSingleNumericParam,
};
