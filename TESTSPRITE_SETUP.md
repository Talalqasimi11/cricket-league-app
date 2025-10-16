# TestSprite Setup for Cricket League App

## 🎯 Overview

I've created a comprehensive TestSprite testing setup for your Cricket League App that covers all major functionality including authentication, team management, tournaments, live scoring, and more.

## 📁 Files Created

### 1. **TestSprite Configuration**
- `testsprite-config.json` - Complete TestSprite configuration with 6 test suites covering all API endpoints

### 2. **Custom Test Runner**
- `test-cricket-app.js` - Node.js-based test runner with detailed reporting
- `package.json` - Dependencies and npm scripts for testing

### 3. **Test Environment Management**
- `test-setup.js` - Environment setup and dependency installation
- `test-cleanup.js` - Cleanup and database reset after tests
- `run-tests.bat` - Windows batch file for easy test execution
- `run-tests.sh` - Linux/Mac shell script for easy test execution

### 4. **Documentation**
- `TESTING.md` - Comprehensive testing guide
- `TESTSPRITE_SETUP.md` - This setup summary

## 🚀 Quick Start

### Option 1: Using the Batch File (Windows)
```cmd
# Set up test environment
run-tests.bat setup

# Run all tests
run-tests.bat test

# Run full test suite (setup + test + cleanup)
run-tests.bat full

# Clean up after tests
run-tests.bat cleanup
```

### Option 2: Using npm Scripts
```cmd
# Install all dependencies
npm run install:all

# Run full test suite
npm run test:full

# Run individual test suites
npm run test:backend
npm run test:frontend
```

### Option 3: Using TestSprite Directly
```cmd
# Install TestSprite globally
npm install -g testsprite

# Run TestSprite tests
testsprite run testsprite-config.json
```

## 🧪 Test Coverage

### Authentication Tests (8 tests)
- ✅ User registration with valid/invalid data
- ✅ User login with valid/invalid credentials  
- ✅ Token refresh functionality
- ✅ Logout functionality
- ✅ Password reset flow
- ✅ Account management

### Team Management Tests (6 tests)
- ✅ Get all teams (public)
- ✅ Get my team (authenticated)
- ✅ Update team information
- ✅ Add/update players
- ✅ Player management

### Tournament Management Tests (5 tests)
- ✅ Create tournaments
- ✅ Get tournament list
- ✅ Create tournament matches
- ✅ Start/end matches
- ✅ Tournament operations

### Live Scoring Tests (6 tests)
- ✅ Start innings
- ✅ Record ball-by-ball deliveries
- ✅ Handle different ball types (wide, no-ball, wicket)
- ✅ Get live score updates
- ✅ End innings

### Statistics Tests (3 tests)
- ✅ Player performance statistics
- ✅ Team tournament summaries
- ✅ Ball-by-ball delivery history

### Error Handling Tests (4 tests)
- ✅ Rate limiting
- ✅ Invalid endpoints (404)
- ✅ Malformed requests (400)
- ✅ Missing required fields

## 🔧 Configuration

### Backend Environment Setup
Create `backend/.env`:
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

### Database Setup
```sql
-- Create database
CREATE DATABASE cricket_league;

-- Import schema
mysql -u root -p cricket_league < cricket-league-db/schema.sql
```

## 📊 Test Features

### TestSprite Configuration Features
- **32 comprehensive test cases** covering all API endpoints
- **Platform-aware base URLs** (localhost for development, 10.0.2.2 for Android emulator)
- **Authentication flow testing** with token management
- **Data validation** for all request/response formats
- **Error handling** for edge cases and failures
- **Rate limiting** verification
- **Parallel execution** for faster test runs

### Custom Test Runner Features
- **Health checks** for backend and database
- **Automatic token management** across test sessions
- **Detailed reporting** with pass/fail statistics
- **Error logging** with stack traces
- **Test data cleanup** after completion
- **Environment verification** before running tests

## 🎯 Test Scenarios

### 1. **Happy Path Testing**
- Complete user registration and login flow
- Team creation and player management
- Tournament creation and match scheduling
- Live scoring with various ball types
- Statistics retrieval and display

### 2. **Error Handling Testing**
- Invalid input validation
- Authentication failures
- Database connection issues
- Rate limiting enforcement
- Malformed request handling

### 3. **Edge Case Testing**
- Duplicate user registration
- Non-existent resource access
- Boundary value testing
- Concurrent request handling
- Session timeout scenarios

## 🔍 Monitoring and Reporting

### Test Reports Generated
- **HTML reports** with detailed test results
- **JSON reports** for CI/CD integration
- **Console output** with colored status indicators
- **Error logs** with stack traces
- **Performance metrics** for each test

### Test Data Management
- **Automatic cleanup** of test data after completion
- **Unique test data** to avoid conflicts
- **Database state reset** between test runs
- **Temporary file cleanup**

## 🚀 Running Tests

### Prerequisites
1. **Node.js** (v16 or higher)
2. **npm** (comes with Node.js)
3. **MySQL** (for database)
4. **Flutter** (for frontend testing)

### Quick Commands
```cmd
# Full test suite
run-tests.bat full

# Individual components
run-tests.bat setup    # Set up environment
run-tests.bat test     # Run tests
run-tests.bat cleanup  # Clean up

# Using npm
npm run test:full      # Complete test suite
npm test              # Custom test runner
```

## 📈 Benefits

### For Development
- **Early bug detection** before production
- **API contract validation** ensuring consistency
- **Performance monitoring** for slow endpoints
- **Regression testing** for new features

### For CI/CD
- **Automated testing** in deployment pipelines
- **Quality gates** before releases
- **Test result reporting** for stakeholders
- **Environment validation** across deployments

### For Maintenance
- **Documentation** of API behavior
- **Test coverage** metrics
- **Error pattern** identification
- **Performance baseline** establishment

## 🎉 Next Steps

1. **Install dependencies**: `npm run install:all`
2. **Set up database**: Create MySQL database and import schema
3. **Configure backend**: Update `backend/.env` with your credentials
4. **Run tests**: `run-tests.bat full` or `npm run test:full`
5. **Review results**: Check test reports and fix any failures
6. **Integrate with CI/CD**: Add to your deployment pipeline

## 📞 Support

If you encounter any issues:
1. Check the troubleshooting section in `TESTING.md`
2. Verify all prerequisites are installed
3. Ensure database and backend server are running
4. Review test logs for specific error messages

The test suite is designed to be comprehensive yet easy to use, providing confidence in your Cricket League App's functionality and reliability! 🏏
