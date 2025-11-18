const Joi = require('joi');
const { getUserFriendlyMessage } = require('../utils/errorMessages');

// Schema definitions for validation
const schemas = {
  // Auth schemas
  register: Joi.object({
    phone_number: Joi.string()
      .pattern(/^\+?[1-9]\d{7,14}$/)
      .required()
      .messages({
        'string.pattern.base': getUserFriendlyMessage('AUTH_INVALID_PHONE')
      }),
    email: Joi.string()
      .email()
      .when('phone_number', {
        is: Joi.exist(),
        then: Joi.forbidden(),
        otherwise: Joi.optional()
      }),
    password: Joi.string()
      .min(8)
      .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
      .required()
      .messages({
        'string.min': getUserFriendlyMessage('AUTH_WEAK_PASSWORD'),
        'string.pattern.base': 'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character'
      })
  }).or('phone_number', 'email'),

  login: Joi.object({
    phone_number: Joi.string()
      .pattern(/^\+?[1-9]\d{7,14}$/)
      .optional(),
    email: Joi.string()
      .email()
      .optional(),
    password: Joi.string().required()
  }).xor('phone_number', 'email'),

  // Team schemas
  createTeam: Joi.object({
    team_name: Joi.string()
      .min(2)
      .max(100)
      .trim()
      .required()
      .messages({
        'string.min': 'Team name must be at least 2 characters long',
        'string.max': 'Team name cannot exceed 100 characters'
      }),
    team_location: Joi.string()
      .min(2)
      .max(100)
      .trim()
      .required(),
    team_logo_url: Joi.string()
      .uri()
      .optional()
      .allow('')
  }),

  addPlayer: Joi.object({
    player_name: Joi.string()
      .min(2)
      .max(100)
      .trim()
      .required(),
    player_role: Joi.string()
      .valid('Batsman', 'Bowler', 'All-rounder', 'Wicket-keeper')
      .required(),
    player_image_url: Joi.string()
      .uri()
      .optional()
      .allow('')
  }),

  // Tournament schemas
  createTournament: Joi.object({
    tournament_name: Joi.string()
      .min(3)
      .max(100)
      .trim()
      .required(),
    location: Joi.string()
      .min(2)
      .max(100)
      .trim()
      .required(),
    start_date: Joi.date()
      .min('now')
      .required(),
    overs: Joi.number()
      .integer()
      .min(1)
      .max(50)
      .required(),
    end_date: Joi.date()
      .min(Joi.ref('start_date'))
      .optional()
  }),

  createMatch: Joi.object({
    tournament_id: Joi.number().integer().positive().optional(),
    team1_id: Joi.number().integer().positive().required(),
    team2_id: Joi.number().integer().positive()
      .invalid(Joi.ref('team1_id'))
      .required()
      .messages({
        'any.invalid': 'Teams must be different'
      }),
    match_datetime: Joi.date()
      .min('now')
      .required(),
    venue: Joi.string()
      .min(2)
      .max(100)
      .trim()
      .required(),
    overs: Joi.number()
      .integer()
      .min(1)
      .max(50)
      .required()
  }),

  // Live scoring schemas
  addBall: Joi.object({
    match_id: Joi.number().integer().positive().required(),
    innings_id: Joi.number().integer().positive().required(),
    over_number: Joi.number().integer().min(0).required(),
    ball_number: Joi.number().integer().min(1).max(6).required(),
    batsman_id: Joi.number().integer().positive().required(),
    bowler_id: Joi.number().integer().positive()
      .invalid(Joi.ref('batsman_id'))
      .required(),
    runs: Joi.number().integer().min(0).max(6).required(),
    extras: Joi.string()
      .valid('', 'wide', 'no-ball', 'bye', 'leg-bye')
      .optional(),
    wicket_type: Joi.string()
      .valid('', 'bowled', 'caught', 'run-out', 'lbw', 'stumped')
      .optional(),
    out_player_id: Joi.number().integer().positive()
      .when('wicket_type', {
        is: Joi.string().valid('caught', 'run-out', 'stumped'),
        then: Joi.required(),
        otherwise: Joi.optional()
      })
  }),

  // Password reset schemas
  requestPasswordReset: Joi.object({
    phone_number: Joi.string()
      .pattern(/^\+?[1-9]\d{7,14}$/)
      .required()
  }),

  resetPassword: Joi.object({
    phone_number: Joi.string()
      .pattern(/^\+?[1-9]\d{7,14}$/)
      .required(),
    token: Joi.string().required(),
    new_password: Joi.string()
      .min(8)
      .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
      .required()
  }),

  changePassword: Joi.object({
    current_password: Joi.string().required(),
    new_password: Joi.string()
      .min(8)
      .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
      .required()
  }),

  // Statistics schemas
  getPlayerStats: Joi.object({
    player_id: Joi.number().integer().positive().optional(),
    tournament_id: Joi.number().integer().positive().optional(),
    limit: Joi.number().integer().min(1).max(100).default(10),
    offset: Joi.number().integer().min(0).default(0)
  }),

  // Feedback schemas
  submitFeedback: Joi.object({
    message: Joi.string()
      .min(10)
      .max(1000)
      .trim()
      .required()
      .messages({
        'string.min': 'Message must be at least 10 characters long',
        'string.max': 'Message cannot exceed 1000 characters'
      }),
    contact: Joi.string()
      .max(255)
      .optional()
      .allow('')
  })
};

// Validation middleware factory
const validate = (schemaName, property = 'body') => {
  return (req, res, next) => {
    const schema = schemas[schemaName];

    if (!schema) {
      return res.status(500).json({
        error: `Validation schema '${schemaName}' not found`,
        validation: { schema: schemaName }
      });
    }

    const { error, value } = schema.validate(
      req[property],
      {
        abortEarly: false,
        stripUnknown: true,
        convert: true
      }
    );

    if (error) {
      const validationErrors = {};
      error.details.forEach(detail => {
        // Use the path as the field name, joining nested paths with dots
        const field = detail.path.join('.');
        validationErrors[field] = detail.message;
      });

      return res.status(400).json({
        success: false,
        error: {
          message: 'Validation failed',
          code: 'VALIDATION_ERROR',
          type: 'validation',
          validation: validationErrors
        }
      });
    }

    // Store validated data back on request
    req.validated = value;
    next();
  };
};

// Specific parameter validation middleware
const validateParams = (paramName, joiSchema) => {
  return (req, res, next) => {
    const { error, value } = joiSchema.validate(req.params[paramName]);

    if (error) {
      return res.status(400).json({
        success: false,
        error: {
          message: `Invalid ${paramName} parameter`,
          code: 'INVALID_PARAM',
          type: 'validation',
          validation: { [paramName]: error.details[0].message }
        }
      });
    }

    req.params[paramName] = value;
    next();
  };
};

// Query parameter validation
const validateIdParam = validateParams('id', Joi.number().integer().positive().required());

// Export both the factory and specific middleware
module.exports = {
  validate,
  validateIdParam,
  schemas
};
