# Design Document: Complete Matches Feature and Live Scoring Section

## 1. Overview

### 1.1 Purpose
This design outlines the completion of the matches feature and live scoring functionality for the Cricket League Management Application. The system currently has partial implementation of live scoring, match management, and scorecard generation, but requires completion of missing features, bug fixes, and enhanced user experience improvements.

### 1.2 Scope
The design covers the following areas:
- Database schema updates to support missing fields
- Enhanced tournament match workflow completion
- Live scoring improvements and real-time updates
- Match finalization and scorecard generation enhancements
- Frontend UI improvements for live scoring and match viewing
- WebSocket integration for real-time score updates

### 1.3 Current State Analysis

**What's Already Implemented:**
- Basic tournament match creation with auto and manual modes
- Live scoring backend with ball-by-ball recording
- Match innings management
- WebSocket service for real-time updates
- Basic scorecard generation
- Match finalization logic
- Frontend screens for live match scoring and viewing

**What's Missing or Incomplete:**
- Database schema missing `legal_balls` field in `complete_schema.sql`
- Tournament match overs configuration not properly retrieved from tournament settings
- Scorecard frontend displays raw JSON instead of formatted data
- Missing match statistics aggregation and display
- Incomplete real-time update integration in frontend
- Missing match progression validation and state management
- No proper error handling for edge cases in live scoring

## 2. Database Schema Updates

### 2.1 Match Innings Table Enhancement

**Issue:** The `complete_schema.sql` is missing the `legal_balls` field that is referenced in the backend code but only exists in `schema.sql`.

**Required Change:**
The `match_innings` table in `complete_schema.sql` must include the `legal_balls` field to track legal deliveries separately from extras.

**Field Specification:**
- Field Name: `legal_balls`
- Data Type: `INT`
- Default Value: `0`
- Purpose: Track only legal deliveries excluding wides and no-balls for accurate over calculation

**Impact:**
- Enables accurate over calculation by tracking legal balls separately
- Required for current backend logic in `liveScoreController.js` that updates this field
- Prevents database errors when recording ball-by-ball data

### 2.2 Schema Validation

**Verification Points:**
- Ensure `legal_balls` field exists in `match_innings` table
- Verify foreign key constraints are properly defined
- Confirm indexes exist for performance optimization
- Validate unique constraints on ball_by_ball position

## 3. Tournament Match Workflow Completion

### 3.1 Tournament Overs Configuration

**Current Issue:**
When starting a tournament match, the system attempts to retrieve overs from the tournament configuration but the query logic is flawed. It queries `matches` table for overs when it should query the `tournaments` table directly.

**Required Logic:**
When a tournament match transitions from "upcoming" to "live" status, the system must:
1. Retrieve the tournament's default overs setting from `tournaments.overs` field
2. Use this value when creating the parent match record
3. Fall back to 20 overs if tournament overs is not configured
4. Validate that overs value is between 1 and 50

**Query Correction:**
Instead of:
```
SELECT t.id, m.overs 
FROM tournaments t
LEFT JOIN matches m ON m.tournament_id = t.id
WHERE t.id = ?
```

Should be:
```
SELECT id, overs 
FROM tournaments 
WHERE id = ?
```

### 3.2 Match State Transitions

**Valid State Transitions:**
- `upcoming` → `live`: When match starts (creates parent match record)
- `live` → `finished`: When match ends (requires winner declaration)
- No transitions allowed from `finished` state

**Validation Rules:**
- Only tournament creator or team owners can start a match
- Both teams must be registered (not temporary) to start live match
- Match date must not be before tournament start date
- Cannot modify teams after match has started
- Cannot delete match after it has started

### 3.3 Match Progression and Knockout Logic

**Current Behavior:**
When a tournament match finishes, the system automatically creates or updates the next round match with the winner.

**Enhancement Required:**
- Validate round naming convention (round_1, round_2, etc.)
- Handle bye rounds where odd team advances automatically
- Properly propagate both team_id and team_tt_id to next round
- Prevent manual modification of matches in future rounds if current round incomplete

## 4. Live Scoring Enhancements

### 4.1 Ball-by-Ball Recording Improvements

**Current Functionality:**
The system records each ball with runs, extras, wickets, and updates innings totals automatically.

**Required Enhancements:**

**Authorization Model:**
- Tournament creator can score for any match in their tournament
- Team owner can score for matches involving their team
- Authorization checked via `canScoreForMatch` and `canScoreForInnings` helpers

**Validation Rules:**
- Ball number must be 1-6
- Over number must be non-negative
- Runs must be 0-6
- Batsman must belong to batting team
- Bowler must belong to bowling team
- No duplicate ball positions (innings + over + ball must be unique)
- Sequential ball validation: next ball must follow previous ball logically

**Legal Ball Tracking:**
- Wide and no-ball are extras and do not count as legal balls
- Only legal balls increment the `legal_balls` counter
- Overs calculated as: `FLOOR(legal_balls / 6)`
- Overs decimal shown as: `legal_balls / 6`

**Auto-End Innings Conditions:**
- 10 wickets have fallen
- Legal balls equals match overs multiplied by 6
- When either condition met, innings status set to 'completed'
- WebSocket event emitted to notify all clients

### 4.2 Player Statistics Update Logic

**Conditional Statistics Updates:**
The system only updates player statistics based on the scorer's authorization:

**Batting Team Owner Scoring:**
- When the scorer is the batting team owner
- Updates batsman stats: runs, balls_faced
- Uses UPSERT pattern: `INSERT ... ON DUPLICATE KEY UPDATE`

**Bowling Team Owner Scoring:**
- When the scorer is the bowling team owner  
- Updates bowler stats: balls_bowled, runs_conceded, wickets
- Uses UPSERT pattern with aggregation

**Rationale:**
This prevents double-counting of statistics and ensures each team manages their own player's performance data.

### 4.3 Real-Time Updates via WebSocket

**Event Types:**

**scoreUpdate Event:**
- Emitted after every ball is recorded
- Payload includes: matchId, inningId, updated inning data, ball details, all balls array
- Broadcast to all clients in room: `match:{matchId}`

**inningsEnded Event:**
- Emitted when innings completes (auto or manual)
- Payload includes: matchId, inningId, final inning data
- Triggers frontend to refresh and show innings summary

**Connection Management:**
- Namespace: `/live-score`
- Room pattern: `match:{matchId}`
- Clients join room when viewing live match
- Authentication via JWT token in socket handshake

### 4.4 Error Handling Improvements

**Required Error Scenarios:**
- Database connection failures: Return 500 with generic message
- Invalid ball sequence: Return 400 with expected sequence details
- Authorization failures: Return 403 with clear denial reason
- Innings not in progress: Return 400 explaining current status
- Player team mismatch: Return 400 specifying which team player must belong to
- Duplicate ball entry: Return 409 conflict error

**Logging Strategy:**
- Use `req.log` for structured logging when available
- Fall back to console.error for helper functions
- Log error message, code, and relevant IDs (matchId, inningId, etc.)
- Never expose database errors directly to client

## 5. Match Finalization Enhancements

### 5.1 Finalization Process

**Current Implementation:**
The `matchFinalizationController.js` handles match completion and winner determination.

**Process Flow:**
1. Validate match exists and is in 'live' status
2. Prevent re-finalization of already completed matches
3. Require at least 2 innings (one per team minimum)
4. Calculate total runs for each team across all their innings
5. Determine winner (or null for tie)
6. Update match status to 'completed' with winner
7. Update team tournament summary statistics
8. Update permanent player statistics from match stats
9. Use database transaction for atomicity

**Winner Determination Logic:**
- Compare total runs across all innings for each team
- Team with higher total wins
- If scores equal, winner_team_id remains NULL (tie)
- Tie handling is explicit and intentional

**Statistics Aggregation:**
- Team stats: matches_played +1, matches_won +1 if winner
- Player stats: runs, wickets, matches_played, batting_average, strike_rate
- Calculations performed using SQL UPDATE with formulas
- Transaction ensures all-or-nothing update

### 5.2 Tournament Summary Updates

**Team Tournament Summary:**
- UPSERT pattern used: `INSERT ... ON DUPLICATE KEY UPDATE`
- Tracks matches_played and matches_won per tournament per team
- Only updates if match belongs to a tournament

**Permanent Player Statistics:**
- Aggregate from `player_match_stats` table
- Update player records in `players` table
- Recalculate averages and rates based on cumulative data

### 5.3 Transaction Management

**Critical Requirements:**
- Use connection pooling: `db.getConnection()`
- Begin transaction before any updates
- Commit only if all operations succeed
- Rollback on any error
- Release connection in finally block
- Use `FOR UPDATE` row locking on match record

## 6. Scorecard Generation and Display

### 6.1 Backend Scorecard Structure

**Current Implementation:**
The `scorecardController.js` generates comprehensive match scorecards.

**Data Structure:**

**Match Information:**
- Match ID, team names, overs, status
- Winner team ID and name (null if tie or ongoing)

**Innings Details:**
- Inning number, batting team, bowling team
- Total runs, wickets, overs
- Batting statistics array per innings
- Bowling statistics array per innings

**Player Statistics Filtering:**
- Batting stats filtered by batting team for each innings
- Bowling stats filtered by bowling team for each innings
- Prevents showing opposition players in wrong section

### 6.2 Frontend Scorecard Improvements

**Current Issue:**
The `scorecard_screen.dart` displays raw JSON data instead of formatted scorecard.

**Required UI Components:**

**Match Summary Card:**
- Display match details: teams, overs, status
- Show winner or "Match Tied" message
- Visual indication of match completion status

**Innings Display:**
- Separate card for each innings
- Header showing: Innings number, batting team name
- Runs/Wickets display in large font
- Overs shown with decimal precision

**Batting Scorecard Table:**
- Columns: Player Name, Runs, Balls Faced, 4s, 6s, Strike Rate
- Strike rate calculated as: (runs / balls_faced) × 100
- Sorted by batting order or runs
- Highlight top scorer

**Bowling Scorecard Table:**
- Columns: Bowler Name, Overs, Runs, Wickets, Economy
- Economy calculated as: runs_conceded / (balls_bowled / 6)
- Overs shown as: FLOOR(balls_bowled / 6) . (balls_bowled % 6)
- Sorted by wickets then economy

**Styling Specifications:**
- Background: Dark theme (#122118)
- Cards: Elevated containers (#1A2C22)
- Text: White primary, grey secondary
- Accent: Green (#36e27b) for highlights
- Rounded corners: 12px border radius

### 6.3 Data Parsing and Display Logic

**Parse Response:**
- Extract match object from JSON response
- Extract scorecard array containing innings
- Handle null/undefined data gracefully

**For Each Innings:**
- Display innings header with team name
- Render batting table from batting array
- Render bowling table from bowling array
- Show innings total: runs/wickets (overs)

**Empty State Handling:**
- Show message if no scorecard data available
- Handle incomplete matches gracefully
- Display loading state during fetch

## 7. Live Match Viewing Enhancements

### 7.1 Live Score Viewer Screen

**Current Implementation:**
The `live_match_view_screen.dart` provides real-time match viewing for spectators.

**Required Enhancements:**

**Auto-Refresh Mechanism:**
- Initial load fetches complete match data
- WebSocket connection for real-time updates
- Fallback polling every 10-15 seconds if WebSocket disconnected
- Prevent concurrent refresh requests

**Score Display Components:**
- Current innings score: Runs/Wickets (Overs)
- Team names displayed prominently
- Match format: Total overs
- Current run rate calculation
- Live status indicator (red dot animation)

**Ball-by-Ball Log:**
- Reverse chronological order (latest first)
- Each ball shows: Over number, Bowler, Batsman, Result, Runs/Wicket
- Visual differentiation for boundaries and wickets
- Color coding: Green for runs, Red for wickets
- Scrollable list with smooth updates

### 7.2 WebSocket Integration

**Connection Setup:**
- Connect to namespace: `/live-score`
- Join room: `match:{matchId}`
- Authenticate with JWT token

**Event Handlers:**

**onScoreUpdate:**
- Receive updated innings data
- Receive new ball details
- Update UI state reactively
- Append to ball-by-ball log
- Update score display

**onInningsEnded:**
- Show innings completion notification
- Refresh complete match data
- Display innings summary
- Auto-scroll to show new innings if started

**Error Handling:**
- Handle connection failures gracefully
- Show offline indicator
- Retry connection with exponential backoff
- Fall back to HTTP polling

### 7.3 Current Over Visualization

**Required Component:**
- Display last 6 balls of current over
- Visual representation: circles with run values
- Color coding: 0=grey, 1-3=blue, 4=green, 6=gold, W=red
- Updates in real-time as balls are added
- Shows current over number

## 8. Live Match Scoring Screen (Scorer Interface)

### 8.1 Scorer Authorization and Access

**Access Control:**
- Only team owners and tournament creators can access
- Verify authorization before allowing score entry
- Show error if unauthorized

**Pre-Match Setup:**
- Select batsmen (2 on strike and non-strike)
- Select bowler
- Confirm innings details before starting

### 8.2 Scoring Interface Design

**Score Entry Controls:**

**Run Buttons:**
- 0, 1, 2, 3, 4, 6 runs
- Large, touch-friendly buttons
- Immediate visual feedback

**Extras Buttons:**
- Wide, No Ball, Bye, Leg Bye
- Distinguish between types clearly
- Show count of extras in current innings

**Wicket Entry:**
- Wicket button opens dismissal type selector
- Options: Bowled, Caught, LBW, Run Out, Stumped, etc.
- Select dismissed batsman
- Optional: Select fielder for catches/run-outs

**Undo Last Ball:**
- Allow correction of last ball entry
- Require confirmation to prevent accidents
- Properly reverse all statistics updates

### 8.3 Live Statistics Display

**Current Innings Summary:**
- Runs/Wickets (Overs)
- Current run rate
- Required run rate (if chasing)
- Projected score

**Batsmen on Crease:**
- Name, Runs, Balls Faced, 4s, 6s, Strike Rate
- Indicate striker with visual marker
- Update in real-time

**Current Bowler:**
- Name, Overs, Maidens, Runs, Wickets, Economy
- Update after each ball

**Recent Overs:**
- Last 3-4 overs shown
- Ball-by-ball breakdown
- Run rate for each over

### 8.4 Ball Entry Validation

**Frontend Validation:**
- Ensure batsman selected
- Ensure bowler selected
- Validate run value (0-6)
- Check if innings is in progress

**Backend Validation:**
- All frontend validations repeated
- Sequential ball numbering enforced
- Team membership verified
- Authorization confirmed

**Optimistic Updates:**
- Update UI immediately on button press
- Show loading indicator
- Revert if backend returns error
- Display error message clearly

## 9. Data Flow Diagrams

### 9.1 Match Start Flow

```
User Action: Start Tournament Match
    ↓
Verify Authorization (Creator or Team Owner)
    ↓
Validate Match State (must be 'upcoming')
    ↓
Validate Match Date (not before tournament start)
    ↓
Verify Both Teams Registered
    ↓
Retrieve Tournament Overs Configuration
    ↓
Create Match Record (status: 'live')
    ↓
Update Tournament Match (status: 'live', link parent_match_id)
    ↓
Return Success with match_id
```

### 9.2 Ball Recording Flow

```
User Action: Record Ball
    ↓
Frontend Validation (batsman, bowler, runs selected)
    ↓
Send to Backend: POST /api/live/add-ball
    ↓
Verify Authorization (team owner or tournament creator)
    ↓
Validate Innings Status (must be 'in_progress')
    ↓
Validate Ball Sequence (must follow previous ball)
    ↓
Validate Player Teams (batsman in batting, bowler in bowling)
    ↓
Check for Duplicate Ball Position
    ↓
Insert Ball Record into ball_by_ball
    ↓
Update Innings Totals (runs, wickets)
    ↓
Update Legal Balls (if not wide/no-ball)
    ↓
Update Player Match Stats (based on scorer authorization)
    ↓
Check Auto-End Conditions (10 wickets or overs complete)
    ↓
If Auto-End: Update Innings Status to 'completed'
    ↓
Fetch Updated Innings and All Balls
    ↓
Emit WebSocket Event: scoreUpdate
    ↓
Return Success Response
    ↓
Frontend Updates UI Optimistically
```

### 9.3 Match Finalization Flow

```
User Action: Finalize Match
    ↓
Verify Authorization (team owner or tournament creator)
    ↓
Start Database Transaction
    ↓
Lock Match Record (FOR UPDATE)
    ↓
Validate Match Status (must be 'live')
    ↓
Prevent Re-finalization (not already 'completed')
    ↓
Fetch All Innings for Match
    ↓
Validate Minimum Innings (at least 2)
    ↓
Calculate Total Runs per Team
    ↓
Determine Winner (higher total or null for tie)
    ↓
Update Match (status: 'completed', winner_team_id)
    ↓
Update Tournament Summary (matches_played, matches_won)
    ↓
Update Player Permanent Stats (from player_match_stats)
    ↓
Commit Transaction
    ↓
Return Success with Winner Details
    ↓
Release Database Connection
```

### 9.4 Real-Time Score Update Flow

```
Ball Recorded on Backend
    ↓
WebSocket Server Emits Event: scoreUpdate
    ↓
Payload: {matchId, inningId, inning, ballAdded, allBalls}
    ↓
Broadcast to Room: match:{matchId}
    ↓
All Connected Clients in Room Receive Event
    ↓
Frontend WebSocket Handler: onScoreUpdate
    ↓
Parse Event Data
    ↓
Update State: innings, balls, score
    ↓
Trigger UI Re-render
    ↓
Update Score Display
    ↓
Append Ball to Ball-by-Ball Log
    ↓
Update Current Batsmen/Bowler Stats
    ↓
Check for Innings End
    ↓
If Innings Ended: Show Summary, Prepare for Next Innings
```

## 10. Edge Cases and Error Scenarios

### 10.1 Database Schema Mismatch

**Scenario:** Backend code references `legal_balls` field but field doesn't exist in database.

**Impact:** Runtime error when recording balls, application crash.

**Resolution:**
- Update `complete_schema.sql` to include `legal_balls` field
- Run database migration to add field to existing installations
- Default value: 0 for all existing records

### 10.2 Tournament Without Overs Configuration

**Scenario:** Tournament created without specifying overs value.

**Impact:** Match creation may fail or use incorrect overs.

**Resolution:**
- Set default value of 20 overs at tournament creation
- Validate overs field is between 1-50
- Use fallback value if query returns null

### 10.3 Ball Sequence Violation

**Scenario:** User attempts to record ball 3 when last ball was ball 1 (skipping ball 2).

**Impact:** Data integrity issue, invalid scorecard.

**Resolution:**
- Validate ball sequence on backend
- Return 400 error with expected ball details
- Show clear error message on frontend
- Prevent submission until corrected

### 10.4 Concurrent Ball Entry

**Scenario:** Two scorers attempt to record balls simultaneously.

**Impact:** Duplicate balls or sequence violations.

**Resolution:**
- Use unique constraint on (inning_id, over_number, ball_number)
- Return 409 Conflict if duplicate detected
- Frontend should disable submit during processing
- Show error and allow retry with next ball

### 10.5 WebSocket Connection Failure

**Scenario:** Network interruption or server restart disconnects WebSocket.

**Impact:** Live updates stop, users see stale data.

**Resolution:**
- Implement automatic reconnection with exponential backoff
- Fall back to HTTP polling every 10-15 seconds
- Show connection status indicator
- Sync data on reconnection

### 10.6 Match Finalization Without Complete Innings

**Scenario:** User attempts to finalize match with only 1 innings.

**Impact:** Invalid result, incomplete match data.

**Resolution:**
- Validate at least 2 innings exist
- Return 400 error with clear message
- Frontend should disable finalize button until conditions met
- Show progress indicator (1/2 innings complete)

### 10.7 Scorecard for Ongoing Match

**Scenario:** User requests scorecard for match still in progress.

**Impact:** Incomplete or confusing data display.

**Resolution:**
- Allow scorecard viewing for any match status
- Show "Match in Progress" indicator for live matches
- Display current innings data with disclaimer
- Hide finalization details until match completed

### 10.8 Tie Match Handling

**Scenario:** Both teams score identical total runs.

**Impact:** System must handle no winner scenario.

**Resolution:**
- Set winner_team_id to NULL for ties
- Display "Match Tied" in UI
- Update team stats appropriately (neither gets win)
- Support tie-breaker rounds if tournament rules require

## 11. Performance Considerations

### 11.1 Database Query Optimization

**Critical Queries:**
- Ball-by-ball queries should use index on (inning_id, over_number, ball_number)
- Player stats queries use composite index on (match_id, player_id)
- Match innings queries use index on match_id
- Tournament matches use indexes on tournament_id and status

**Connection Pooling:**
- Use connection pool for transaction management
- Release connections promptly
- Set appropriate pool size based on load

### 11.2 WebSocket Scalability

**Considerations:**
- Limit broadcast payload size (send only changed data)
- Use rooms to segment clients by match
- Implement connection limits per user
- Monitor socket memory usage

**Optimization Strategies:**
- Compress WebSocket messages
- Batch rapid updates (debounce within 100ms)
- Disconnect idle clients after timeout
- Implement heartbeat/ping-pong

### 11.3 Frontend Performance

**Rendering Optimization:**
- Use virtual scrolling for long ball-by-ball logs
- Implement pagination for historical matches
- Cache scorecard data locally
- Debounce rapid state updates

**Network Optimization:**
- Compress HTTP responses
- Use CDN for static assets
- Implement request caching with appropriate TTL
- Minimize payload sizes

## 12. Testing Strategy

### 12.1 Backend Unit Tests

**Test Coverage:**
- Live scoring ball validation logic
- Authorization helper functions
- Match finalization calculations
- Winner determination logic
- Statistics aggregation formulas

**Test Scenarios:**
- Valid ball entry
- Invalid ball sequence
- Auto-end on 10 wickets
- Auto-end on overs complete
- Tie match scenario
- Transaction rollback on error

### 12.2 Integration Tests

**API Endpoint Tests:**
- Start innings with valid/invalid data
- Add ball with various scenarios
- End innings manually
- Finalize match with different outcomes
- Retrieve scorecard for various match states

**WebSocket Tests:**
- Connection establishment
- Event emission and receipt
- Room joining and leaving
- Reconnection handling

### 12.3 Frontend Widget Tests

**UI Component Tests:**
- Scorecard rendering with mock data
- Ball-by-ball log updates
- Score display formatting
- Error message display

**State Management Tests:**
- WebSocket event handling
- State updates on score changes
- Navigation and routing

### 12.4 End-to-End Tests

**User Flows:**
- Complete match from start to finish
- Score entry and real-time updates
- Multiple viewers watching same match
- Match finalization and scorecard view

**Error Scenarios:**
- Network failures and recovery
- Invalid data entry and validation
- Authorization failures
- Concurrent operations

## 13. Deployment and Migration

### 13.1 Database Migration

**Migration Script Required:**
```
ALTER TABLE match_innings ADD COLUMN legal_balls INT DEFAULT 0;
UPDATE match_innings SET legal_balls = FLOOR(overs_decimal * 6) WHERE legal_balls = 0;
```

**Verification:**
- Confirm field exists in all environments
- Verify data migrated correctly
- Test queries using legal_balls field

### 13.2 Backend Deployment

**Deployment Steps:**
1. Run database migration script
2. Deploy updated backend code
3. Restart server gracefully (wait for active requests)
4. Verify WebSocket connections re-establish
5. Monitor error logs for issues

**Rollback Plan:**
- Revert to previous code version
- Database rollback not required (new field has default)
- Clear application cache if needed

### 13.3 Frontend Deployment

**Flutter App Updates:**
- Build new APK/IPA with updated screens
- Test on multiple devices and OS versions
- Prepare release notes for app store
- Enable staged rollout for monitoring

**Web Admin Panel:**
- Deploy updated React code
- Clear browser cache
- Verify admin functionality

## 14. Future Enhancements

### 14.1 Advanced Statistics

**Potential Additions:**
- Strike rate progression graphs
- Manhattan charts for run distribution
- Wagon wheels for boundary analysis
- Player comparison tools
- Tournament leaderboards

### 14.2 Enhanced Live Scoring

**Features:**
- Voice commentary recording
- Live photos/videos during match
- Automated highlights generation
- AI-powered insights and predictions
- Real-time analytics dashboard

### 14.3 Scorecard Enhancements

**Improvements:**
- PDF export of scorecards
- Share scorecard on social media
- Partnership analysis
- Fall of wickets timeline
- Over-by-over run rate graph

### 14.4 Mobile App Features

**Native Capabilities:**
- Offline mode for scoring (sync when online)
- Push notifications for match events
- Home screen widgets for live scores
- Dark/light theme toggle
- Localization support

## 15. Success Criteria

### 15.1 Functional Completeness

**Must Achieve:**
- All matches can be scored ball-by-ball without errors
- Real-time updates work reliably for all viewers
- Scorecards display correctly for all match states
- Match finalization calculates winners accurately
- Tournament progression works without manual intervention

### 15.2 Performance Targets

**Metrics:**
- Ball recording API response: < 400ms (p95)
- Scorecard generation: < 1000ms (p95)
- WebSocket event delivery: < 100ms latency
- Frontend render time: < 500ms for score updates
- Database query time: < 200ms (p95)

### 15.3 Reliability Goals

**Targets:**
- 99.5% uptime for live scoring service
- Zero data loss during ball recording
- Transaction success rate: > 99.9%
- WebSocket connection stability: > 95%
- Error rate: < 0.1% of requests

### 15.4 User Experience

**Quality Standards:**
- Intuitive scoring interface (< 5 clicks per ball)
- Clear error messages with actionable guidance
- Responsive UI (< 100ms interaction feedback)
- Smooth animations and transitions
- Accessible design (WCAG 2.1 AA compliance)

## 16. Dependencies and Constraints

### 16.1 Technical Dependencies

**Backend:**
- Node.js 16+
- Express.js framework
- Socket.IO for WebSocket
- MySQL database with InnoDB engine
- JWT for authentication

**Frontend:**
- Flutter SDK (latest stable)
- Dart language
- Provider for state management
- Socket.IO client library

### 16.2 External Services

**Optional Integrations:**
- Cloud storage for match photos/videos
- Analytics service for usage tracking
- Error monitoring (Sentry, LogRocket)
- Performance monitoring

### 16.3 Constraints

**Technical Limitations:**
- Database transaction timeout: 30 seconds
- WebSocket message size limit: 1MB
- API rate limiting: 100 requests/minute per user
- Ball entry rate: Max 1 ball per 5 seconds

**Business Constraints:**
- Only registered teams can participate in live matches
- Maximum 11 players per team in playing XI
- Maximum 50 overs per innings
- Single scorer per team at a time
