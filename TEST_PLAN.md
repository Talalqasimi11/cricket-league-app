# Test Plan: Matches Feature and Live Scoring Completion

## Overview
This test plan validates all changes made to complete the matches feature and live scoring functionality.

## Test Environment Setup

### Prerequisites
- MySQL database with either:
  - Fresh installation using `complete_schema.sql`, OR
  - Existing installation with `add_legal_balls_migration.sql` applied
- Backend server running on port 5000
- Frontend app (Flutter) deployed
- At least 2 test users registered
- At least 2 teams created
- At least 1 tournament created with teams registered

### Test Data Required
- User 1: Tournament creator (phone: test_user_1)
- User 2: Team owner (phone: test_user_2)
- Team 1: Owned by User 1 (with 11 players)
- Team 2: Owned by User 2 (with 11 players)
- Tournament 1: Created by User 1, with Team 1 and Team 2 registered

## Test Cases

### 1. Database Schema Validation

#### TC-DB-001: Verify legal_balls field exists
**Objective**: Confirm match_innings table has legal_balls field

**Steps**:
1. Connect to MySQL database
2. Execute: `DESCRIBE match_innings;`
3. Check output includes `legal_balls INT DEFAULT 0`

**Expected Result**: Field exists with correct type and default value

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

#### TC-DB-002: Verify migration script for existing databases
**Objective**: Confirm migration script adds field correctly

**Steps**:
1. Create test database without legal_balls field
2. Run: `mysql -u root -p test_db < add_legal_balls_migration.sql`
3. Check field exists: `DESCRIBE match_innings;`
4. Verify existing data backfilled correctly

**Expected Result**: Field added, data migrated without errors

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

### 2. Tournament Match Creation

#### TC-TM-001: Create tournament with custom overs
**Objective**: Verify tournament overs configuration is used

**Steps**:
1. Login as User 1 (tournament creator)
2. Create new tournament with 15 overs
3. Register Team 1 and Team 2 to tournament
4. Create match between teams
5. Start the match
6. Query matches table: `SELECT overs FROM matches WHERE id = ?;`

**Expected Result**: Match created with 15 overs (from tournament config)

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

#### TC-TM-002: Default overs when tournament has no configuration
**Objective**: Verify default 20 overs used when tournament overs not set

**Steps**:
1. Create tournament without specifying overs (NULL)
2. Register teams and create match
3. Start the match
4. Query: `SELECT overs FROM matches WHERE id = ?;`

**Expected Result**: Match created with 20 overs (default)

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

### 3. Live Scoring - Ball by Ball

#### TC-LS-001: Record legal ball
**Objective**: Verify legal ball increments legal_balls counter

**Steps**:
1. Start a live match
2. Start innings for Team 1 batting
3. Record ball: over=0, ball=1, runs=1, no extras
4. Query: `SELECT legal_balls FROM match_innings WHERE id = ?;`

**Expected Result**: legal_balls = 1

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

#### TC-LS-002: Wide ball doesn't increment legal_balls
**Objective**: Verify wide balls are not counted as legal

**Steps**:
1. In ongoing match/innings
2. Check current legal_balls value
3. Record wide: over=0, ball=2, runs=1, extras='wide'
4. Query legal_balls again

**Expected Result**: legal_balls unchanged from step 2

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

#### TC-LS-003: No-ball doesn't increment legal_balls
**Objective**: Verify no-balls are not counted as legal

**Steps**:
1. In ongoing match/innings
2. Check current legal_balls value
3. Record no-ball: over=0, ball=3, runs=1, extras='no-ball'
4. Query legal_balls again

**Expected Result**: legal_balls unchanged from step 2

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

#### TC-LS-004: Auto-end innings on 10 wickets
**Objective**: Verify innings ends automatically at 10 wickets

**Steps**:
1. In ongoing innings with 9 wickets down
2. Record 10th wicket
3. Check innings status: `SELECT status FROM match_innings WHERE id = ?;`

**Expected Result**: status = 'completed'

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

#### TC-LS-005: Auto-end innings on overs complete
**Objective**: Verify innings ends when legal_balls reaches max

**Steps**:
1. Start match with 2 overs (12 legal balls)
2. Record 11 legal balls
3. Record 12th legal ball
4. Check innings status

**Expected Result**: status = 'completed' after 12th legal ball

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

#### TC-LS-006: Overs calculation from legal_balls
**Objective**: Verify overs calculated correctly

**Steps**:
1. Record 7 legal balls (1 over + 1 ball)
2. Query: `SELECT overs, overs_decimal, legal_balls FROM match_innings WHERE id = ?;`

**Expected Result**: 
- overs = 1
- overs_decimal = 1.1 or 1.17
- legal_balls = 7

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

### 4. Scorecard Display

#### TC-SC-001: View completed match scorecard
**Objective**: Verify scorecard displays formatted data

**Steps**:
1. Complete a match (2 innings, finalized)
2. Navigate to match scorecard screen
3. Verify display shows:
   - Match summary (teams, overs, winner)
   - Each innings card
   - Batting table with columns: Player, R, B, 4s, 6s, SR
   - Bowling table with columns: Bowler, O, R, W, Econ

**Expected Result**: Formatted scorecard, not raw JSON

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

#### TC-SC-002: Winner display for completed match
**Objective**: Verify winner shown correctly

**Steps**:
1. View scorecard for match with clear winner
2. Check winner display section

**Expected Result**: 
- Trophy icon displayed
- "[Winner Team] won the match" text
- Green color scheme

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

#### TC-SC-003: Tie match display
**Objective**: Verify tie status shown correctly

**Steps**:
1. Create tied match (both teams same total)
2. Finalize match (winner_team_id should be NULL)
3. View scorecard

**Expected Result**:
- Handshake icon displayed
- "Match Tied" text
- Orange color scheme

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

#### TC-SC-004: Batting statistics accuracy
**Objective**: Verify batting stats calculated correctly

**Steps**:
1. View scorecard with known player stats
2. For a player with 50 runs off 30 balls:
3. Check Strike Rate = (50/30) * 100 = 166.7

**Expected Result**: Strike rate displayed as 166.7

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

#### TC-SC-005: Bowling statistics accuracy
**Objective**: Verify bowling stats calculated correctly

**Steps**:
1. View scorecard with known bowler stats
2. For bowler with 36 balls bowled, 30 runs conceded:
3. Check Overs = 6.0
4. Check Economy = 30 / (36/6) = 5.00

**Expected Result**: 
- Overs: 6.0
- Economy: 5.00

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

#### TC-SC-006: Pull to refresh
**Objective**: Verify refresh functionality works

**Steps**:
1. Open scorecard screen
2. Pull down to trigger refresh
3. Observe loading indicator
4. Verify data reloads

**Expected Result**: Screen refreshes with latest data

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

### 5. Live Match View (WebSocket)

#### TC-LV-001: Real-time score updates
**Objective**: Verify WebSocket updates work

**Steps**:
1. User A scores a ball in live match
2. User B views same match (live view screen)
3. Observe if User B's screen updates automatically

**Expected Result**: Score updates without manual refresh

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

#### TC-LV-002: WebSocket connection indicator
**Objective**: Verify connection status shown to user

**Steps**:
1. Open live match view
2. Check for connection indicator (if implemented)
3. Disconnect network
4. Check indicator changes

**Expected Result**: User informed of connection status

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

#### TC-LV-003: Innings ended notification
**Objective**: Verify user notified when innings ends

**Steps**:
1. User viewing live match
2. Innings reaches completion (10 wickets or overs)
3. Check for notification/snackbar

**Expected Result**: "Innings ended" message displayed

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

### 6. Error Handling

#### TC-ERR-001: Invalid ball sequence
**Objective**: Verify validation prevents out-of-sequence balls

**Steps**:
1. Record ball at position 0.1
2. Attempt to record ball at position 0.3 (skipping 0.2)
3. Check API response

**Expected Result**: 
- HTTP 400 error
- Error message: "Invalid ball sequence. Expected over 0, ball 2"

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

#### TC-ERR-002: Duplicate ball entry
**Objective**: Verify duplicate balls are rejected

**Steps**:
1. Record ball at position 0.1
2. Attempt to record another ball at 0.1
3. Check API response

**Expected Result**:
- HTTP 409 conflict error
- Error message about duplicate ball

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

#### TC-ERR-003: Scorecard for non-existent match
**Objective**: Verify error handling for invalid match ID

**Steps**:
1. Navigate to scorecard with invalid match_id (e.g., 99999)
2. Observe behavior

**Expected Result**: 
- "No scorecard data available" message
- No crashes or exceptions

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

### 7. Integration Tests

#### TC-INT-001: Complete match workflow
**Objective**: Verify entire match lifecycle works

**Steps**:
1. Create tournament with 10 overs
2. Register 2 teams
3. Create and start match
4. Record first innings (10 overs)
5. Verify innings auto-ended
6. Record second innings
7. Finalize match
8. View scorecard

**Expected Result**: All steps complete without errors

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

#### TC-INT-002: Concurrent viewing and scoring
**Objective**: Verify multiple users can interact simultaneously

**Steps**:
1. User A scores balls in live match
2. User B views live match (viewer)
3. User C views scorecard of different completed match
4. All actions happen concurrently

**Expected Result**: All users experience smooth operation, no crashes

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

### 8. Performance Tests

#### TC-PERF-001: Scorecard load time
**Objective**: Verify scorecard loads within acceptable time

**Steps**:
1. Create match with full 20 overs data (120 balls)
2. Open scorecard screen
3. Measure time to full display

**Expected Result**: < 2 seconds

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

#### TC-PERF-002: WebSocket latency
**Objective**: Verify real-time updates are timely

**Steps**:
1. User A scores ball
2. Measure time until User B sees update

**Expected Result**: < 500ms latency

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________________

---

## Test Summary

### Results
- Total Test Cases: 28
- Passed: ___
- Failed: ___
- Skipped: ___
- Pass Rate: ___%

### Critical Issues Found
1. _______________________
2. _______________________
3. _______________________

### Non-Critical Issues
1. _______________________
2. _______________________

### Recommendations
1. _______________________
2. _______________________

### Sign-off
- Tester: _______________________
- Date: _______________________
- Version Tested: _______________________
- Environment: _______________________

---

## Regression Testing Checklist

Verify existing functionality still works:

- [ ] User registration and login
- [ ] Team creation and management
- [ ] Player addition and editing
- [ ] Tournament creation
- [ ] Team registration to tournament
- [ ] Non-tournament friendly matches (if supported)
- [ ] User authentication and authorization
- [ ] Admin panel functionality
- [ ] Feedback submission

---

## Appendix: SQL Queries for Validation

### Check legal_balls field exists
```sql
DESCRIBE match_innings;
```

### Verify legal_balls increments correctly
```sql
SELECT id, legal_balls, overs, overs_decimal, status 
FROM match_innings 
WHERE match_id = ?;
```

### Check match overs from tournament
```sql
SELECT m.id, m.overs as match_overs, t.overs as tournament_overs
FROM matches m
JOIN tournaments t ON m.tournament_id = t.id
WHERE m.id = ?;
```

### View complete scorecard data
```sql
-- Innings
SELECT * FROM match_innings WHERE match_id = ?;

-- Batting stats
SELECT pms.*, p.player_name, p.team_id
FROM player_match_stats pms
JOIN players p ON pms.player_id = p.id
WHERE pms.match_id = ?;

-- Ball by ball
SELECT * FROM ball_by_ball 
WHERE match_id = ? 
ORDER BY over_number, ball_number;
```

### Count legal vs total balls
```sql
SELECT 
  COUNT(*) as total_balls,
  SUM(CASE WHEN extras NOT IN ('wide', 'no-ball') OR extras IS NULL THEN 1 ELSE 0 END) as legal_balls
FROM ball_by_ball
WHERE inning_id = ?;
```