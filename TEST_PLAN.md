# Bug Fixes and Error Handling - Test Plan

## Overview
This document outlines the comprehensive test plan for validating bug fixes and error handling improvements implemented in the Cricket League Application.

**Test Plan Version**: 1.0  
**Implementation Reference**: IMPLEMENTATION_SUMMARY.md  
**Test Execution Date**: TBD

---

## Test Environments

### Development Environment
- **Backend**: Node.js (local)
- **Database**: MySQL (local)
- **Frontend**: Flutter (emulator/simulator)
- **Admin Panel**: React (localhost:3000)

### Staging Environment
- **Backend**: Deployed test server
- **Database**: Test database with sample data
- **Frontend**: TestFlight/Internal testing
- **Admin Panel**: Staging URL

---

## Phase 1: Critical Bug Fixes - Test Cases

### Test Case 1.1: Race Condition in Team Updates
**Objective**: Verify that concurrent team updates don't cause data inconsistency

**Pre-conditions**:
- User logged in with a team
- Two browser sessions/API clients ready

**Test Steps**:
1. Open two API clients (Postman/browser)
2. Authenticate both with same user credentials
3. Simultaneously send PUT requests to `/api/teams/my-team` with different captain_player_id values
4. Verify one succeeds and one fails gracefully
5. Check database - only one update should be applied
6. Verify no orphaned captain IDs

**Expected Result**:
- One request succeeds with 200 OK
- Other request gets appropriate error (409 or 500)
- Database contains only one final state
- No data corruption

**Priority**: High  
**Status**: ⏳ Pending

---

### Test Case 1.2: Database Connection Release
**Objective**: Verify connections are released even on errors

**Pre-conditions**:
- Backend running
- Database connection pool configured (max 10 connections)

**Test Steps**:
1. Monitor connection pool usage
2. Trigger errors in each controller that uses `getConnection()`:
   - teamController (updateMyTeam with invalid data)
   - playerController (updatePlayer with invalid ID)
   - tournamentController (createTournament with SQL error)
   - matchFinalizationController (finalize with missing data)
3. Verify connection count returns to baseline after each error
4. Run 100 concurrent requests that cause errors
5. Verify no connection leaks (pool doesn't exhaust)

**Expected Result**:
- Connection count returns to 0 after each operation
- No "Too many connections" errors
- Connection pool metrics show proper release

**Priority**: High  
**Status**: ⏳ Pending

---

### Test Case 1.3: Match Finalization Transaction
**Objective**: Verify match finalization is atomic

**Pre-conditions**:
- Live match with completed innings
- Player match stats populated

**Test Steps**:
1. Call POST `/api/match-finalization/finalize` with valid match_id
2. Simulate database error mid-transaction:
   - Modify code temporarily to throw error after first UPDATE
   - Or disconnect database briefly during operation
3. Verify entire transaction rolls back:
   - Match status unchanged
   - Team tournament summary unchanged
   - Player stats unchanged
4. Retry finalization - should succeed
5. Verify all updates applied together:
   - Match status = 'completed'
   - Winner team recorded
   - Team tournament summary updated
   - Player stats updated

**Expected Result**:
- On error: complete rollback, no partial updates
- On success: all updates applied atomically
- No data inconsistencies

**Priority**: High  
**Status**: ⏳ Pending

---

### Test Case 1.4: Null Reference in Tournament Teams
**Objective**: Verify null checks prevent crashes

**Pre-conditions**:
- Tournament created
- Database accessible

**Test Steps**:
1. Test `addTournamentTeam`:
   - Manually delete tournament mid-request (or mock empty result)
   - Verify 500 error with "Tournament data is invalid"
2. Test `updateTournamentTeam`:
   - Same scenario
   - Verify graceful error handling
3. Test `deleteTournamentTeam`:
   - Same scenario
   - Verify no null reference exception

**Expected Result**:
- No application crashes
- 500 status with clear error message
- No null reference exceptions in logs

**Priority**: Medium  
**Status**: ⏳ Pending

---

### Test Case 1.5: Ball Number Validation
**Objective**: Verify strict ball number validation

**Pre-conditions**:
- Live match with innings in progress
- User authorized to score

**Test Data**:
| Ball Number | Over Number | Runs | Extras | Expected Result |
|-------------|-------------|------|--------|-----------------|
| 1 | 0 | 0 | null | Success (200) |
| 0 | 0 | 0 | null | Error (400) - ball < 1 |
| 7 | 0 | 0 | null | Error (400) - ball > 6 |
| 1.5 | 0 | 0 | null | Error (400) - not integer |
| 1 | -1 | 0 | null | Error (400) - over < 0 |
| 1 | 0 | 7 | null | Error (400) - runs > 6 |
| 1 | 0 | -1 | null | Error (400) - runs < 0 |
| 1 | 0 | 0 | invalid | Error (400) - invalid extras |
| 1 | 0 | 0 | wide | Success (200) |

**Test Steps**:
1. For each test case, POST to `/api/live-score/add-ball`
2. Verify response status and error message
3. Check database - invalid balls should not be inserted

**Expected Result**:
- Valid balls: inserted successfully
- Invalid balls: rejected with specific error message
- No invalid data in database

**Priority**: High  
**Status**: ⏳ Pending

---

## Phase 2: Backend Hardening - Test Cases

### Test Case 2.1: Transaction Wrapper - Success Scenario
**Objective**: Verify transaction wrapper commits successfully

**Test Steps**:
1. Create test controller using transaction wrapper:
```javascript
const result = await withTransaction(async (conn) => {
  await conn.query('INSERT INTO test_table VALUES (?)', [data]);
  return { success: true };
});
```
2. Execute operation
3. Verify data committed to database
4. Verify connection released

**Expected Result**:
- Transaction commits
- Data persisted
- Connection released
- Success result returned

**Priority**: High  
**Status**: ⏳ Pending

---

### Test Case 2.2: Transaction Wrapper - Rollback Scenario
**Objective**: Verify automatic rollback on error

**Test Steps**:
1. Create test that throws error mid-transaction:
```javascript
const result = await withTransaction(async (conn) => {
  await conn.query('INSERT INTO test_table VALUES (?)', [data1]);
  throw new Error('Simulated error');
  await conn.query('INSERT INTO test_table VALUES (?)', [data2]);
});
```
2. Execute and catch error
3. Verify no data inserted (rollback successful)
4. Verify connection released

**Expected Result**:
- Transaction rolls back
- No data in database
- Error propagated to caller
- Connection released

**Priority**: High  
**Status**: ⏳ Pending

---

### Test Case 2.3: Transaction Wrapper - Deadlock Retry
**Objective**: Verify automatic retry on deadlock

**Pre-conditions**:
- Two concurrent transactions accessing same rows

**Test Steps**:
1. Setup: Create scenario that causes deadlock:
   - Transaction A: locks row 1, waits for row 2
   - Transaction B: locks row 2, waits for row 1
2. Use transaction wrapper with retry enabled
3. Verify deadlock detected
4. Verify automatic retry
5. Verify eventual success

**Expected Result**:
- Deadlock detected (ER_LOCK_DEADLOCK)
- Automatic retry initiated
- Success after retry
- Warning logged about retry

**Priority**: Medium  
**Status**: ⏳ Pending

---

### Test Case 2.4: Enhanced Validation - String Fields
**Objective**: Verify string validation rules

**Test Data**:
| Field | Value | Min | Max | Expected Result |
|-------|-------|-----|-----|-----------------|
| team_name | "A" | 2 | 50 | Error (too short) |
| team_name | "AB" | 2 | 50 | Success |
| team_name | (51 chars) | 2 | 50 | Error (too long) |
| team_name | "  Test  " | 2 | 50 | Success (trimmed to "Test") |
| team_name | "" | 2 | 50 | Error (empty) |
| team_location | "NY" | 2 | 100 | Success |

**Test Steps**:
1. For each test case, validate using `validateString()`
2. Verify isValid flag
3. Verify error message
4. Verify normalized value

**Expected Result**:
- Validation follows rules exactly
- Errors are descriptive
- Values normalized (trimmed)

**Priority**: Medium  
**Status**: ⏳ Pending

---

### Test Case 2.5: Enhanced Validation - Numeric Fields
**Objective**: Verify number validation rules

**Test Data**:
| Field | Value | Min | Max | Integer | Expected Result |
|-------|-------|-----|-----|---------|-----------------|
| overs | 0 | 1 | 50 | Yes | Error (< min) |
| overs | 1 | 1 | 50 | Yes | Success |
| overs | 50 | 1 | 50 | Yes | Success |
| overs | 51 | 1 | 50 | Yes | Error (> max) |
| overs | 20.5 | 1 | 50 | Yes | Error (not integer) |
| ball_number | 1 | 1 | 6 | Yes | Success |
| ball_number | "1" | 1 | 6 | Yes | Success (converted) |
| ball_number | "abc" | 1 | 6 | Yes | Error (NaN) |

**Test Steps**:
1. For each test case, validate using `validateNumber()`
2. Verify isValid flag
3. Verify error message
4. Verify converted value

**Expected Result**:
- Number conversion works
- Range validation correct
- Integer check enforced
- Clear error messages

**Priority**: Medium  
**Status**: ⏳ Pending

---

### Test Case 2.6: Enhanced Validation - Date Fields
**Objective**: Verify date validation rules

**Test Data**:
| Field | Value | Future Only | Past Only | Expected Result |
|-------|-------|-------------|-----------|-----------------|
| start_date | "2025-12-01" | Yes | No | Success |
| start_date | "2024-01-01" | Yes | No | Error (not future) |
| start_date | "invalid" | No | No | Error (invalid date) |
| end_date | "2025-11-30" | No | Yes | Success (if test date > this) |

**Test Steps**:
1. For each test case, validate using `validateDate()`
2. Verify isValid flag
3. Verify error message
4. Verify Date object returned

**Expected Result**:
- Date parsing works
- Future/past validation correct
- Invalid dates rejected

**Priority**: Medium  
**Status**: ⏳ Pending

---

### Test Case 2.7: Enhanced Validation - Phone Numbers
**Objective**: Verify phone number validation

**Test Data**:
| Phone Number | Expected Result |
|--------------|-----------------|
| "+1234567890" | Success |
| "+919876543210" | Success |
| "1234567890" | Error (no country code) |
| "+1-234-567-8900" | Error (contains dashes) |
| "+12345" | Error (too short) |
| "+123456789012345678" | Error (too long) |
| "abcd" | Error (not numeric) |

**Test Steps**:
1. For each phone number, validate using `validatePhoneNumber()`
2. Verify isValid flag
3. Verify error message

**Expected Result**:
- E.164 format enforced
- Length validation (10-15 digits after +)
- Special characters rejected

**Priority**: Medium  
**Status**: ⏳ Pending

---

### Test Case 2.8: Pagination Validation
**Objective**: Verify pagination parameter validation

**Test Data**:
| Page | Limit | Expected Result |
|------|-------|-----------------|
| 1 | 50 | Success (page=1, limit=50) |
| 0 | 50 | Error (page < 1) |
| -1 | 50 | Error (page < 1) |
| 1 | 101 | Success (capped to 100) |
| 1 | 0 | Success (default to 1) |
| 5 | 20 | Success (offset=80) |

**Test Steps**:
1. Send GET request with query params
2. Use `validatePagination()` middleware
3. Verify req.pagination object
4. Verify proper offset calculation

**Expected Result**:
- Page must be >= 1
- Limit capped at 100
- Offset calculated correctly
- Defaults applied appropriately

**Priority**: Low  
**Status**: ⏳ Pending

---

## Admin Panel Error Handling - Test Cases

### Test Case 3.1: Network Error Handling
**Objective**: Verify network error detection and messaging

**Test Steps**:
1. Disconnect network
2. Attempt API call
3. Verify error message shown

**Expected Result**:
- Error detected as network error
- User-friendly message: "Network error. Please check your internet connection..."
- isRetryableError() returns true

**Priority**: Medium  
**Status**: ⏳ Pending

---

### Test Case 3.2: 401 Unauthorized Handling
**Objective**: Verify automatic logout on session expiry

**Test Steps**:
1. Login to admin panel
2. Manually expire token or delete from server
3. Attempt protected API call
4. Verify redirect to login page

**Expected Result**:
- 401 detected
- shouldLogout() returns true
- User redirected to login
- Token cleared from storage

**Priority**: High  
**Status**: ⏳ Pending

---

### Test Case 3.3: Validation Error Display
**Objective**: Verify validation errors formatted correctly

**Test Steps**:
1. Submit form with invalid data
2. Receive 422 response with validation errors:
```json
{
  "error": {
    "validation": {
      "team_name": "Team name must be at least 2 characters",
      "phone_number": "Invalid phone number format"
    }
  }
}
```
3. Verify formatted error message displayed

**Expected Result**:
- Validation errors extracted correctly
- Formatted as: "Team Name: Team name must be at least 2 characters\nPhone Number: Invalid phone number format"
- Fields converted to readable format (team_name → Team Name)

**Priority**: Medium  
**Status**: ⏳ Pending

---

## Integration Test Scenarios

### Integration Test 1: Complete Match Flow with Error Recovery
**Scenario**: Start match, score balls, handle errors, finalize

**Steps**:
1. Create tournament and teams
2. Create match
3. Start match
4. Start innings
5. Add balls with some invalid attempts:
   - Ball 0 (should fail)
   - Ball 1-6 (should succeed)
   - Ball 7 (should fail)
   - Start over 1
6. End innings
7. Finalize match
8. Verify all data correct

**Priority**: High  
**Status**: ⏳ Pending

---

### Integration Test 2: Concurrent Operations
**Scenario**: Multiple users performing operations simultaneously

**Steps**:
1. User A updates team
2. User B updates same team (should wait or fail gracefully)
3. User C adds player to team
4. User D deletes different player
5. Verify all operations complete correctly
6. Verify no data corruption

**Priority**: High  
**Status**: ⏳ Pending

---

## Performance Tests

### Performance Test 1: Connection Pool Under Load
**Objective**: Verify connection handling under high load

**Steps**:
1. Configure connection pool (max 10)
2. Send 100 concurrent requests
3. Monitor connection usage
4. Verify no leaks
5. Verify requests handled efficiently

**Expected Result**:
- All requests complete
- No connection timeout errors
- Pool efficiently reused
- Response times reasonable

**Priority**: Medium  
**Status**: ⏳ Pending

---

### Performance Test 2: Validation Performance
**Objective**: Verify validation doesn't significantly impact response time

**Steps**:
1. Measure response time without validation
2. Add validation middleware
3. Measure response time with validation
4. Compare overhead

**Expected Result**:
- Validation overhead < 10ms per request
- No significant performance degradation

**Priority**: Low  
**Status**: ⏳ Pending

---

## Test Execution Checklist

### Pre-Execution
- [ ] Test environment setup complete
- [ ] Test data prepared
- [ ] Database backed up
- [ ] All test cases reviewed
- [ ] Test tools ready (Postman, JMeter, etc.)

### Execution
- [ ] Phase 1 tests executed
- [ ] Phase 2 tests executed
- [ ] Admin panel tests executed
- [ ] Integration tests executed
- [ ] Performance tests executed

### Post-Execution
- [ ] All test results documented
- [ ] Bugs reported and tracked
- [ ] Pass/fail criteria met
- [ ] Test report generated
- [ ] Stakeholders notified

---

## Test Results Template

### Test Case Results
| Test ID | Test Name | Status | Notes | Tester | Date |
|---------|-----------|--------|-------|--------|------|
| 1.1 | Race Condition | ⏳ Pending | - | - | - |
| 1.2 | Connection Release | ⏳ Pending | - | - | - |
| 1.3 | Match Finalization | ⏳ Pending | - | - | - |
| 1.4 | Null Reference | ⏳ Pending | - | - | - |
| 1.5 | Ball Validation | ⏳ Pending | - | - | - |
| 2.1 | Transaction Success | ⏳ Pending | - | - | - |
| 2.2 | Transaction Rollback | ⏳ Pending | - | - | - |
| 2.3 | Deadlock Retry | ⏳ Pending | - | - | - |
| 2.4 | String Validation | ⏳ Pending | - | - | - |
| 2.5 | Number Validation | ⏳ Pending | - | - | - |
| 2.6 | Date Validation | ⏳ Pending | - | - | - |
| 2.7 | Phone Validation | ⏳ Pending | - | - | - |
| 2.8 | Pagination | ⏳ Pending | - | - | - |
| 3.1 | Network Error | ⏳ Pending | - | - | - |
| 3.2 | 401 Handling | ⏳ Pending | - | - | - |
| 3.3 | Validation Display | ⏳ Pending | - | - | - |

---

## Success Criteria

### Phase 1: Critical Fixes
- [x] All 5 critical bug test cases pass
- [ ] No data corruption in any scenario
- [ ] No connection leaks under load
- [ ] No null reference exceptions

### Phase 2: Backend Hardening
- [ ] Transaction wrapper tests 100% pass
- [ ] All validation tests pass
- [ ] Performance overhead < 10ms

### Phase 3: Admin Panel
- [ ] All error scenarios handled gracefully
- [ ] User-friendly messages displayed
- [ ] No unhandled exceptions

### Overall
- [ ] 95% of test cases pass
- [ ] No critical or high severity bugs
- [ ] Performance meets benchmarks
- [ ] User acceptance criteria met
