# Cricket League Management Application

A comprehensive digital platform for organizing, managing, and tracking cricket tournaments and matches.

## 📚 Documentation

- **[Quick Start Guide](QUICK_START.md)** - Get up and running in 5 minutes
- **[Complete Documentation](DOCUMENTATION.md)** - Full system documentation
- **[API Reference](API_REFERENCE.md)** - Complete API endpoint documentation
- **[Developer Guide](DEVELOPER_GUIDE.md)** - Development best practices and guidelines
- **[Product Requirements](PRD.md)** - Product requirements document

## Stack
- Flutter for app (Provider, flutter_secure_storage)
- Node.js + Express + JWT + Socket.IO for backend
- MySQL (PlanetScale-compatible)

This repo follows a trunk-based workflow with main/dev branches and feature branches.

## Environment Variables (Backend)

Set these in `backend/.env`:

```env
# Database Configuration (REQUIRED)
DB_HOST=localhost
DB_USER=root
DB_PASS=your_password
DB_NAME=cricket_league

# Server Configuration
PORT=5000
NODE_ENV=development

# JWT Configuration (REQUIRED - minimum 32 characters each)
JWT_SECRET=your_long_random_secret_at_least_32_chars
JWT_REFRESH_SECRET=your_long_random_refresh_secret_at_least_32_chars
JWT_AUD=cric-league-app
JWT_ISS=cric-league-auth

# CORS Configuration (REQUIRED for production, comma-separated origins)
# For development, localhost origins are auto-added if empty
CORS_ORIGINS=http://localhost:3000,http://localhost:5000,http://127.0.0.1:5000,http://10.0.2.2:5000

# Cookie flags (OPTIONAL)
COOKIE_SECURE=false
# Set to true to rotate refresh tokens on each use (enabled by default in production)
ROTATE_REFRESH_ON_USE=false
# Set to true to return password reset tokens in response body (DEVELOPMENT ONLY - NEVER enable in production)
RETURN_RESET_TOKEN_IN_BODY=false
```

### Required Environment Variables

The following variables **must** be set for the application to run:

- `DB_HOST`, `DB_USER`, `DB_PASS`, `DB_NAME`: Database configuration
- `JWT_SECRET`, `JWT_REFRESH_SECRET`: Must be at least 32 characters each (generate with: `openssl rand -base64 48`)
- `JWT_AUD`, `JWT_ISS`: JWT audience and issuer identifiers
- `CORS_ORIGINS`: Comma-separated list of allowed origins (optional in development mode)

### Optional Environment Variables

- `COOKIE_SECURE`: Set to `true` in production to enforce HTTPS-only cookies (default: `false`)
- `ROTATE_REFRESH_ON_USE`: Set to `true` to rotate refresh tokens on each use (enabled by default in production)
- `RETURN_RESET_TOKEN_IN_BODY`: Set to `true` to return password reset tokens in response body (DEVELOPMENT ONLY - NEVER enable in production)
- `PORT`: Server port (default: `5000`)
- `NODE_ENV`: Set to `development` to bypass env validation errors (warnings only)

### Authorization Scopes

The application uses role-based access control with the following scopes:

- `team:read` - Read team information
- `team:manage` - Create, update, delete teams
- `player:manage` - Manage players (add, update, delete)
- `match:score` - Score matches and manage innings
- `tournament:manage` - Create, update, delete tournaments

**Default Role Mapping:**
- `captain` role includes all scopes above
- All registered users are assigned the `captain` role by default

### Important Notes

- **Development Mode**: When `NODE_ENV=development`, missing or short secrets will produce warnings instead of fatal errors
- **Production Mode**: Missing required variables or short secrets will cause the server to exit immediately with error code 1
- Refresh flow accepts `refresh_token` in the request body (mobile-friendly)
- Cookies use `sameSite=none` with `secure=true` for cross-site flows (e.g., mobile apps)
- Configure `CORS_ORIGINS` explicitly when `credentials: true` in production
- For Android emulator, Flutter uses `http://10.0.2.2:5000` as base URL
- To override API URL at build time: `flutter run --dart-define=API_BASE_URL=http://your-custom-url:5000`

## Database Setup

The application uses a schema-based approach for database setup:

1. **Schema Setup**: Run the complete schema from `cricket-league-db/schema.sql` to create all tables and constraints
2. **No Migrations**: The current setup does not use a migration system - the schema file contains the complete database structure
3. **Manual Setup**: You need to manually run the schema file to set up the database

### Database Setup Steps

1. Create the database:
```sql
CREATE DATABASE cricket_league;
```

2. Run the complete schema:
```bash
mysql -u root -p cricket_league < cricket-league-db/schema.sql
```

Or if using the backend's database connection:
```bash
cd backend
node -e "
const db = require('./config/db');
const fs = require('fs');
const schema = fs.readFileSync('../cricket-league-db/schema.sql', 'utf8');
db.query(schema).then(() => {
  console.log('Schema applied successfully');
  process.exit(0);
}).catch(err => {
  console.error('Schema application failed:', err);
  process.exit(1);
});
"
```

### Running the Application

**Recommended**: Always start the backend with `npm start` from the `backend/` directory. This ensures:
- Environment variables are validated
- Database connection is established
- Application is ready to serve requests

```bash
cd backend
npm install
npm start
```

### Manual Migration Management

If you need to run migrations manually:

```bash
cd backend
node scripts/runMigrations.js
```

### Important Notes

- **Never run `schema.sql` manually** unless starting fresh. The schema file is minimal; migrations add required columns and indexes
- The unified schema migration (`2025-10-16_db_unification.sql`) is critical for controller compatibility
- Migrations run in lexicographic order based on filename (YYYY-MM-DD format)
- Failed migration statements log warnings but don't halt the process (for idempotency)

## Health Check

Backend exposes `GET /health` returning status and DB connectivity.
