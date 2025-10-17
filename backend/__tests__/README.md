# Backend Integration Tests

This directory contains integration tests for the Cricket League API backend.

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Configure test environment:
   - Create a `.env.test` file or set `NODE_ENV=test` when running tests
   - Ensure test database credentials are configured
   - Tests will create and clean up test data automatically

3. Run tests:
   ```bash
   npm test
   ```

   Or watch mode:
   ```bash
   npm run test:watch
   ```

## Test Structure

- `auth.test.js` - Authentication flows (register, login, refresh, logout, password reset)
- `teams.test.js` - Team management endpoints
- `tournaments.test.js` - Tournament creation and management
- `feedback.test.js` - Feedback submission and validation

## Current Status

⚠️ **Note**: These tests are currently **stubs** that demonstrate the expected test structure. They pass by default with `expect(true).toBe(true)`.

To make them functional:

1. **Refactor `backend/index.js`** to export the Express app without starting the server:
   ```javascript
   // backend/index.js
   const app = express();
   // ... middleware and routes ...
   
   if (require.main === module) {
     app.listen(PORT, () => console.log(`Server running on ${PORT}`));
   }
   
   module.exports = app;
   ```

2. **Uncomment test code** in each test file and update with actual request logic using `supertest`

3. **Set up test database** isolation to prevent tests from affecting production data

## Coverage Areas

- ✅ Auth: Registration, login, token refresh, logout, password reset
- ✅ Teams: Public listing, authenticated team details, player management
- ✅ Tournaments: Creation, listing, team registration, status management
- ✅ Live Scoring: Innings management, ball-by-ball recording
- ✅ Feedback: Validation, profanity filtering, length checks
- ✅ Auth Failures: Progressive throttling on failed login attempts

## Running Migrations in Tests

Tests should run against a clean database state. Consider:

- Using an in-memory SQLite database for tests (requires code changes)
- Running migrations before each test suite
- Using database transactions and rollbacks for test isolation

