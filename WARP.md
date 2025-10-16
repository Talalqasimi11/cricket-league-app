# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Cricket League App is a full-stack application for managing cricket tournaments, teams, and match scoring. The project uses a trunk-based workflow with main/dev branches and feature branches.

**Technology Stack:**
- **Frontend**: Flutter with Provider state management, shared_preferences for local storage, and flutter_secure_storage for sensitive data
- **Backend**: Node.js with Express, JWT authentication, and MySQL2 for database connectivity  
- **Database**: MySQL (configured for PlanetScale hosting)
- **Real-time**: Socket.IO for live match updates
- **Additional**: Prisma mentioned in README but not currently implemented

## Development Commands

### Backend Commands (run from `backend/` directory)

```bash
# Install dependencies
npm install

# Start development server with hot reload
npm run dev

# Start production server
npm start
```

### Frontend Commands (run from `frontend/` directory)

```bash
# Install dependencies
flutter pub get

# Run the app on connected device/emulator
flutter run

# Build for Android
flutter build apk

# Build for iOS
flutter build ios

# Run tests
flutter test

# Analyze code
flutter analyze
```

### Database Setup

```bash
# Import the database schema (run from cricket-league-db/ directory)
mysql -u [username] -p [database_name] < schema.sql
```

## Architecture Overview

### Backend Architecture

The backend follows a layered MVC architecture:

- **Routes** (`routes/`): Define API endpoints and route handling
- **Controllers** (`controllers/`): Business logic and request/response handling  
- **Middleware** (`middleware/`): Authentication and request processing
- **Config** (`config/`): Database configuration and connection pooling

**Key API Modules:**
- **Authentication**: JWT-based auth with phone number login
- **Teams & Players**: Team management and player statistics
- **Tournaments**: Tournament creation, team registration, match scheduling
- **Live Scoring**: Ball-by-ball scoring with real-time updates
- **Statistics**: Player and team performance analytics

**Database Connection**: Uses MySQL2 connection pooling for efficient database access

### Frontend Architecture

Flutter app with feature-based architecture:

```
lib/
├── features/           # Feature-based modules
│   ├── auth/          # Authentication (login/register)
│   ├── matches/       # Match scoring, live view, statistics
│   ├── teams/         # Team and player management
│   └── tournaments/   # Tournament management
├── screens/           # Shared screens (home, splash)
└── widgets/           # Reusable UI components
```

**Key Features:**
- **Auth**: Phone-based authentication with secure storage
- **Live Scoring**: Ball-by-ball match scoring with real-time updates
- **Team Management**: Player registration and team statistics
- **Tournament System**: Multi-team tournament brackets and scheduling

### Database Schema

The MySQL schema supports:
- **User Management**: Phone-based authentication with team associations
- **Team Structure**: Teams with captains, players, and performance stats
- **Tournament System**: Flexible tournament with both registered and temporary teams
- **Match Management**: Detailed ball-by-ball scoring with innings tracking
- **Statistics**: Comprehensive player and team performance metrics

**Key Tables:**
- `users` - Captain authentication
- `teams` - Team information and stats
- `players` - Player details and performance
- `tournaments` - Tournament management
- `matches` - Match details and results
- `ball_by_ball` - Detailed ball-by-ball scoring

## Environment Configuration

### Backend Environment Variables (`backend/.env`)

```
DB_HOST=localhost
DB_USER=root
DB_PASS=your_password
DB_NAME=cricket_league
PORT=5000

JWT_SECRET=your_long_random_secret_at_least_32_chars
JWT_REFRESH_SECRET=your_long_random_refresh_secret_at_least_32_chars
JWT_AUD=cric-league-app
JWT_ISS=cric-league-auth

# Explicit CORS origins (comma-separated). No wildcard when credentials are used.
CORS_ORIGINS=http://localhost:3000,http://localhost:5000

# Cookie flags
NODE_ENV=development
COOKIE_SECURE=false
# Optional refresh rotation on /api/auth/refresh
ROTATE_REFRESH_ON_USE=false
```

Auth Notes:
- Mobile clients send `refresh_token` in the body to `/api/auth/refresh` because cookies are not used.
- Refresh tokens currently last 7 days; rotation is supported behind `ROTATE_REFRESH_ON_USE`.
- Cookies are `httpOnly`, `sameSite=lax`, and `secure` only in production.

### Frontend Configuration

The app is configured for development with localhost backend connection. Update API endpoints in the HTTP service files when deploying.

## Development Workflow

1. **Database First**: Import the schema from `cricket-league-db/schema.sql`
2. **Backend**: Start with `npm run dev` from the `backend/` directory
3. **Frontend**: Run with `flutter run` from the `frontend/` directory
4. **Testing**: Backend currently has placeholder tests; frontend uses standard Flutter testing

## Key Development Notes

- **Authentication**: Uses JWT tokens with phone number as primary identifier
- **Real-time Updates**: Socket.IO integration for live match scoring
- **State Management**: Frontend uses Provider pattern for state management
- **Database Relationships**: Complex foreign key relationships support both permanent teams and temporary tournament teams
- **Match Scoring**: Detailed ball-by-ball tracking with support for all cricket scenarios (wickets, extras, etc.)