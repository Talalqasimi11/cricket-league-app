require('dotenv').config();

function validateEnv() {
  const isDevelopment = process.env.NODE_ENV === 'development';
  
  const required = [
    'DB_HOST', 'DB_USER', 'DB_PASS', 'DB_NAME',
    'JWT_SECRET', 'JWT_REFRESH_SECRET', 'JWT_AUD', 'JWT_ISS'
  ];
  
  const missing = required.filter((k) => !process.env[k] || String(process.env[k]).trim() === '');
  
  if (missing.length > 0) {
    const errorMsg = `❌ FATAL: Missing required environment variables: ${missing.join(', ')}`;
    
    if (isDevelopment) {
      console.warn('⚠️  WARNING (Development Mode): ' + errorMsg);
      console.warn('⚠️  The application may not function correctly without these variables.');
      console.warn('⚠️  Please set them in your .env file or environment.');
    } else {
      console.error(errorMsg);
      console.error('Required environment variables:');
      console.error('  - DB_HOST, DB_USER, DB_PASS, DB_NAME: Database configuration');
      console.error('  - JWT_SECRET, JWT_REFRESH_SECRET: Must be at least 32 characters');
      console.error('  - JWT_AUD, JWT_ISS: JWT audience and issuer');
      console.error('  - CORS_ORIGINS (optional): Comma-separated allowed origins');
      console.error('  - COOKIE_SECURE (optional): Set to "true" for production');
      console.error('  - ROTATE_REFRESH_ON_USE (optional): Set to "true" to enable token rotation');
      process.exit(1);
    }
  }

  const secretMinLength = 32;
  const jwtSecretLen = (process.env.JWT_SECRET || '').length;
  const refreshSecretLen = (process.env.JWT_REFRESH_SECRET || '').length;
  
  // Check if weak secrets are explicitly allowed
  const allowWeakSecrets = process.env.ALLOW_WEAK_SECRETS === 'true';
  
  if (jwtSecretLen < secretMinLength || refreshSecretLen < secretMinLength) {
    const errorMsg = `❌ FATAL: JWT secrets must be at least ${secretMinLength} characters (JWT_SECRET: ${jwtSecretLen}, JWT_REFRESH_SECRET: ${refreshSecretLen})`;
    
    if (isDevelopment && allowWeakSecrets) {
      console.warn('⚠️  WARNING (Development Mode): ' + errorMsg);
      console.warn('⚠️  Using short secrets in development is insecure.');
      console.warn('⚠️  Set ALLOW_WEAK_SECRETS=true to suppress this warning.');
    } else if (isDevelopment) {
      console.warn('⚠️  WARNING (Development Mode): ' + errorMsg);
      console.warn('⚠️  Using short secrets in development is insecure.');
      console.warn('⚠️  Set ALLOW_WEAK_SECRETS=true to suppress this warning.');
    } else {
      console.error(errorMsg);
      console.error('Generate secure secrets using: openssl rand -base64 48');
      process.exit(1);
    }
  }
  
  // Log a prominent banner if weak secrets are detected even in development
  if (isDevelopment && (jwtSecretLen < secretMinLength || refreshSecretLen < secretMinLength)) {
    console.log('\n' + '='.repeat(80));
    console.log('🚨 WEAK SECRETS DETECTED IN DEVELOPMENT 🚨');
    console.log('='.repeat(80));
    console.log('Your JWT secrets are shorter than recommended for security.');
    console.log('This is acceptable for development but NEVER use in production.');
    console.log('='.repeat(80) + '\n');
  }
  
  console.log('✅ Environment validation passed' + (isDevelopment ? ' (development mode)' : ''));
}

module.exports = validateEnv;


