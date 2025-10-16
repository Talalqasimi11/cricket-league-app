# Cricket League App - TestSprite Testing Guide

This guide explains how to test the Cricket League App using TestSprite and custom test scripts.

## Overview

The Cricket League App is a full-stack application with:
- **Frontend**: Flutter app with Provider state management
- **Backend**: Node.js/Express API with JWT authentication
- **Database**: MySQL with comprehensive cricket data schema

## Test Suite Components

### 1. TestSprite Configuration (`testsprite-config.json`)
Comprehensive API testing configuration covering:
- Authentication (registration, login, password reset)
- Team management (teams, players)
- Tournament management (creation, matches)
- Live scoring (ball-by-ball recording)
- Statistics and analytics
- Error handling and edge cases

### 2. Custom Test Runner (`test-cricket-app.js`)
Node.js-based test runner that:
- Verifies backend health
- Tests all major API endpoints
- Handles authentication flow
- Provides detailed test results

### 3. Test Setup (`test-setup.js`)
Environment preparation script that:
- Checks prerequisites (Node.js, Flutter, MySQL)
- Installs dependencies
- Starts backend server
- Verifies database connection

### 4. Test Cleanup (`test-cleanup.js`)
Cleanup script that:
- Stops background processes
- Removes test data
- Resets database state
- Cleans temporary files

## Prerequisites

Before running tests, ensure you have:

1. **Node.js** (v16 or higher)
2. **npm** (comes with Node.js)
3. **Flutter** (for frontend testing)
4. **MySQL** (for database)
5. **Git** (for cloning the repository)

## Quick Start

### 1. Install Dependencies
```bash
# Install all dependencies (root, backend, frontend)
npm run install:all
```

### 2. Set Up Database
```bash
# Create database
mysql -u root -p -e "CREATE DATABASE cricket_league;"

# Import schema
mysql -u root -p cricket_league < cricket-league-db/schema.sql
```

### 3. Configure Backend
Create `backend/.env` file:
```env
DB_HOST=localhost
DB_USER=root
DB_PASS=your_password
DB_NAME=cricket_league
PORT=5000

JWT_SECRET=your_long_random_secret_at_least_32_chars
JWT_REFRESH_SECRET=your_long_random_refresh_secret_at_least_32_chars
JWT_AUD=cric-league-app
JWT_ISS=cric-league-auth

CORS_ORIGINS=http://localhost:3000,http://localhost:5000,http://127.0.0.1:5000,http://10.0.2.2:5000

NODE_ENV=development
COOKIE_SECURE=false
ROTATE_REFRESH_ON_USE=false
```

### 4. Run Tests

#### Option A: Full Test Suite (Recommended)
```bash
# Complete setup, test, and cleanup
npm run test:full
```

#### Option B: Step by Step
```bash
# 1. Set up test environment
npm run test:setup

# 2. Run tests
npm test

# 3. Clean up
npm run test:cleanup
```

#### Option C: Individual Test Suites
```bash
# Backend API tests only
npm run test:backend

# Frontend Flutter tests only
npm run test:frontend

# Custom test runner
node test-cricket-app.js
```

## Test Coverage

### Authentication Tests
- ✅ User registration with valid/invalid data
- ✅ User login with valid/invalid credentials
- ✅ Token refresh functionality
- ✅ Password reset flow
- ✅ Account management (change password, phone)

### Team Management Tests
- ✅ Get all teams (public endpoint)
- ✅ Get my team (authenticated)
- ✅ Update team information
- ✅ Add/update/delete players
- ✅ Player statistics

### Tournament Management Tests
- ✅ Create tournaments
- ✅ Get tournament list
- ✅ Create tournament matches
- ✅ Start/end matches
- ✅ Tournament team registration

### Live Scoring Tests
- ✅ Start innings
- ✅ Record ball-by-ball deliveries
- ✅ Handle different ball types (regular, wide, no-ball)
- ✅ Record wickets and dismissals
- ✅ Get live score updates
- ✅ End innings

### Statistics Tests
- ✅ Player performance statistics
- ✅ Team tournament summaries
- ✅ Match statistics
- ✅ Ball-by-ball delivery history

### Error Handling Tests
- ✅ Rate limiting
- ✅ Invalid endpoints (404)
- ✅ Malformed requests (400)
- ✅ Authentication failures (401)
- ✅ Missing required fields

## Test Data

The test suite uses the following test data patterns:
- **Phone numbers**: `+123456789*` (where * is 0-9)
- **Team names**: `Test Team*`
- **Tournament names**: `Test Tournament*`
- **Player names**: `Test Player*`

All test data is automatically cleaned up after tests complete.

## TestSprite Configuration

The `testsprite-config.json` file contains:

### Test Suites
1. **Authentication Tests** - User registration, login, password management
2. **Team Management Tests** - Team and player operations
3. **Tournament Management Tests** - Tournament and match creation
4. **Live Scoring Tests** - Ball-by-ball scoring functionality
5. **Statistics Tests** - Performance analytics
6. **Error Handling Tests** - Edge cases and error scenarios

### Configuration Options
- **Base URL**: `http://localhost:5000` (configurable for different environments)
- **Timeout**: 30 seconds per test
- **Retries**: 2 attempts for failed tests
- **Parallel**: Tests run in parallel for faster execution
- **Max Concurrency**: 5 concurrent tests

### Environment Support
- **Development**: `http://localhost:5000`
- **Android Emulator**: `http://10.0.2.2:5000`

## Custom Test Runner Features

The custom test runner (`test-cricket-app.js`) provides:

### Health Checks
- Backend server availability
- Database connectivity
- API endpoint responsiveness

### Authentication Flow
- Automatic token management
- Token refresh handling
- Session persistence across tests

### Test Results
- Detailed pass/fail reporting
- Error message logging
- Test execution timing
- Summary statistics

## Troubleshooting

### Common Issues

#### 1. Backend Server Not Starting
```bash
# Check if port 5000 is in use
lsof -ti:5000

# Kill processes on port 5000
lsof -ti:5000 | xargs kill -9

# Check backend logs
cd backend && npm start
```

#### 2. Database Connection Issues
```bash
# Verify MySQL is running
mysql -u root -p -e "SELECT 1;"

# Check database exists
mysql -u root -p -e "SHOW DATABASES;"

# Test database connection
mysql -u root -p cricket_league -e "SELECT 1;"
```

#### 3. Flutter Dependencies
```bash
# Clean and reinstall Flutter dependencies
cd frontend
flutter clean
flutter pub get
```

#### 4. Test Data Cleanup
```bash
# Manual cleanup if needed
mysql -u root -p cricket_league -e "DELETE FROM users WHERE phone_number LIKE '+123456789%';"
```

### Debug Mode

Run tests with debug output:
```bash
# Enable debug logging
DEBUG=* npm test

# Or with custom test runner
DEBUG=* node test-cricket-app.js
```

## Continuous Integration

### GitHub Actions Example
```yaml
name: Test Cricket League App
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - uses: actions/setup-java@v3
        with:
          distribution: 'temurin'
          java-version: '11'
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - name: Setup MySQL
        uses: actions/setup-mysql@v1
        with:
          mysql-version: '8.0'
          mysql-root-password: 'password'
      - name: Install dependencies
        run: npm run install:all
      - name: Setup database
        run: mysql -u root -ppassword -e "CREATE DATABASE cricket_league;"
      - name: Run tests
        run: npm run test:full
```

## Performance Testing

### Load Testing
```bash
# Install artillery for load testing
npm install -g artillery

# Run load tests
artillery run load-test-config.yml
```

### Stress Testing
```bash
# Test with high concurrency
npm test -- --maxConcurrency=20

# Test with longer timeouts
npm test -- --timeout=60000
```

## Security Testing

### Authentication Security
- JWT token validation
- Password strength requirements
- Rate limiting verification
- Session management

### API Security
- CORS configuration
- Input validation
- SQL injection prevention
- XSS protection

## Monitoring and Reporting

### Test Reports
- HTML reports with screenshots
- JSON reports for CI/CD
- Performance metrics
- Error categorization

### Logging
- Request/response logging
- Error stack traces
- Performance timing
- Database query logs

## Best Practices

1. **Always run cleanup** after tests to avoid data pollution
2. **Use unique test data** to avoid conflicts
3. **Test both success and failure scenarios**
4. **Verify database state** after critical operations
5. **Test with different user roles** and permissions
6. **Monitor test performance** and optimize slow tests
7. **Keep tests independent** and runnable in any order

## Contributing

When adding new tests:

1. Follow the existing test structure
2. Add appropriate test data cleanup
3. Include both positive and negative test cases
4. Update this documentation
5. Test your changes thoroughly

## Support

For issues with testing:
1. Check the troubleshooting section
2. Review test logs and error messages
3. Verify all prerequisites are installed
4. Check database and server status
5. Create an issue with detailed error information
