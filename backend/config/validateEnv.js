require('dotenv').config();

function validateEnv() {
  const required = [
    'DB_HOST', 'DB_USER', 'DB_PASS', 'DB_NAME',
    'JWT_SECRET', 'JWT_REFRESH_SECRET', 'JWT_AUD', 'JWT_ISS'
  ];
  const missing = required.filter((k) => !process.env[k] || String(process.env[k]).trim() === '');
  if (missing.length > 0) {
    throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
  }

  if ((process.env.JWT_SECRET || '').length < 32 || (process.env.JWT_REFRESH_SECRET || '').length < 32) {
    throw new Error('JWT secrets must be at least 32 characters');
  }
}

module.exports = validateEnv;


