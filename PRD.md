# Product Requirements Document (PRD)
## Cricket League Management Application

---

## 1. Product Overview

### 1.1 Executive Summary
The Cricket League Management Application is a comprehensive digital platform designed to facilitate the organization, management, and tracking of cricket tournaments and matches. The system enables registered users to become team owners, organize tournaments, manage live scoring, and track player statistics in real-time.

### 1.2 Product Vision
To become the go-to platform for amateur and semi-professional cricket leagues, providing an intuitive, mobile-first experience that digitizes the entire cricket tournament lifecycle from registration to match completion.

### 1.3 Target Audience
- **Primary Users:** Registered users who become team owners

-  Users:** Spectators and cricket enthusiasts

### 1.4 Platform
- **Frontend:** Flutter mobile application (iOS & Android)
- **Backend:** Node.js REST API with Express.js
- **Database:** MySQL (PlanetScale-compatible)
- **Architecture:** Client-server with JWT-based authentication

---

## 2. Business Objectives

### 2.1 Primary Goals
1. **Digitize Tournament Management:** Replace manual scorekeeping and tournament tracking with automated digital solutions
2. **Real-time Match Scoring:** Enable live ball-by-ball scoring accessible to players and spectators
3. **Player Statistics:** Automatically calculate and maintain comprehensive player performance metrics
4. **Team Management:** Provide tools for captains to manage their teams and players efficiently

### 2.2 Success Metrics
- **User Adoption:** 100+ registered teams within 6 months
- **Engagement:** 80% of registered teams actively participate in tournaments
- **Match Completion Rate:** 90% of started matches are completed with full scorecards
- **User Satisfaction:** 4.0+ star rating on app stores
- **API Performance:** < 500ms average response time for critical endpoints

---

## 3. User Personas

### 3.1 team registrar
**Age:** 28 | **Location:** Urban India | **Tech Savviness:** Medium

**Background:**
- Runs a local cricket team with 15 players
- Organizes weekend matches and participates in local tournaments
- Previously used WhatsApp groups and paper scorecards
- Registered user who automatically becomes team owner

**Goals:**
- Easy team registration and player management
- Track team performance across multiple tournaments
- Access match history and statistics
- Start tournaments and manage matches

**Pain Points:**
- Manual scorekeeping is error-prone
- Difficult to track player statistics over time
- Hard to coordinate tournament schedules

### 3.3 Arjun - Active Player
**Age:** 24 | **Location:** Suburban Area | **Tech Savviness:** High

**Background:**
- Plays for a local team
- Wants to track personal performance
- Follows multiple tournaments

**Goals:**
- View personal batting and bowling statistics
- Check upcoming match schedules
- Follow tournament standings

**Pain Points:**
- Can't easily access his performance history
- Doesn't know when/where next match is
- Limited visibility into team performance

---

## 4. Core Features & Requirements

### 4.1 User Authentication & Account Management

#### 4.1.1 User Registration
**Priority:** P0 (Must Have)

**Functional Requirements:**
- Users register using phone number (E.164 format)
- Password must be at least 8 characters
- Upon registration, a team is automatically created
- User becomes the team owner/captain
- System validates unique phone numbers
- Optional fields: captain name, team logo URL

**Technical Specifications:**
- Endpoint: `POST /api/auth/register`
- Password hashing: bcrypt with 12 salt rounds
- Phone validation: E.164 regex pattern
- Response: Success message (201) or error (400/409)

**Acceptance Criteria:**
- ✅ User can register with valid phone and password
- ✅ System rejects duplicate phone numbers
- ✅ System rejects passwords < 8 characters
- ✅ System rejects invalid phone number formats
- ✅ Team is automatically created upon registration

#### 4.1.2 User Login
**Priority:** P0 (Must Have)

**Functional Requirements:**
- Login with phone number and password
- Returns JWT access token (15-minute expiry)
- Returns refresh token (7-day expiry)
- Refresh token stored in httpOnly cookie for web
- Refresh token also returned in body for mobile clients
- Progressive throttling on failed login attempts:
  - 3 failures in 15 min → 1 minute lockout
  - 5 failures in 15 min → 5 minute lockout
  - 10+ failures in 15 min → 30 minute lockout
- Rate limiting: 10 requests per 15 minutes

**Technical Specifications:**
- Endpoint: `POST /api/auth/login`
- Access Token: JWT with aud, iss, sub claims
- Refresh Token: Stored in database with revocation tracking
- Auth failures tracked in `auth_failures` table
- Cookie settings: httpOnly, sameSite=none (production), secure flag

**Acceptance Criteria:**
- ✅ User can login with correct credentials
- ✅ System rejects incorrect passwords
- ✅ System implements progressive lockout after failures
- ✅ Tokens are properly formatted and verifiable
- ✅ Failed attempts are logged with IP and user agent

#### 4.1.3 Token Refresh
**Priority:** P0 (Must Have)

**Functional Requirements:**
- Accept refresh token from cookie or request body
- Validate token signature and expiration
- Check token not revoked in database
- Issue new access token (15-minute expiry)
- Optional token rotation on refresh (configurable)
- Clock tolerance: 5 seconds

**Technical Specifications:**
- Endpoint: `POST /api/auth/refresh`
- Environment variable: `ROTATE_REFRESH_ON_USE` (true/false)
- Refresh token validation against database

**Acceptance Criteria:**
- ✅ Valid refresh token returns new access token
- ✅ Revoked tokens are rejected
- ✅ Expired tokens are rejected
- ✅ Token rotation works when enabled

#### 4.1.4 Logout
**Priority:** P0 (Must Have)

**Functional Requirements:**
- Revoke refresh token(s)
- Accept token from cookie or body
- Clear refresh cookie
- Mark token as revoked in database

**Technical Specifications:**
- Endpoint: `POST /api/auth/logout`
- Sets `is_revoked = 1` and `revoked_at = NOW()`

**Acceptance Criteria:**
- ✅ Logout revokes refresh token
- ✅ Revoked token cannot be used for refresh
- ✅ Cookie is properly cleared

#### 4.1.5 Password Reset Flow
**Priority:** P1 (Should Have)

**Functional Requirements:**
- Request password reset by phone number
- Generate secure random token (48 bytes)
- Token valid for 15 minutes
- Rate limit: 1 request per 15 minutes per user
- Verify token before allowing password change
- Invalidate all existing tokens on successful reset
- Respond with success even if user not found (prevent enumeration)

**Technical Specifications:**
- Endpoints:
  - `POST /api/auth/forgot-password`
  - `POST /api/auth/verify-reset`
  - `POST /api/auth/reset-password`
- Token storage: bcrypt-hashed in `password_resets` table
- Single-active-token policy

**Acceptance Criteria:**
- ✅ User can request password reset
- ✅ Token expires after 15 minutes
- ✅ User can verify token validity
- ✅ User can set new password with valid token
- ✅ Old tokens invalidated after successful reset

#### 4.1.6 Account Management
**Priority:** P1 (Should Have)

**Functional Requirements:**
- Change password (requires authentication)
- Change phone number (requires authentication)
- Rate limiting: 10 requests per 15 minutes

**Technical Specifications:**
- Endpoints:
  - `PUT /api/auth/change-password`
  - `PUT /api/auth/change-phone`
- Requires valid access token

**Acceptance Criteria:**
- ✅ Authenticated user can change password
- ✅ Authenticated user can change phone number
- ✅ New phone number is validated for uniqueness

---

### 4.2 Team Management

#### 4.2.1 View Teams
**Priority:** P0 (Must Have)

**Functional Requirements:**
- Public endpoint to view all registered teams
- Returns team name, location, statistics
- Includes matches played, won, trophies
- No authentication required

**Technical Specifications:**
- Endpoint: `GET /api/teams`
- Returns array of team objects
- Fields: id, team_name, team_location, matches_played, matches_won, trophies, owner info

**Acceptance Criteria:**
- ✅ Any user can view all teams
- ✅ Team statistics are accurate
- ✅ Response is properly formatted

#### 4.2.2 View My Team
**Priority:** P0 (Must Have)

**Functional Requirements:**
- Authenticated endpoint for team owner
- Returns detailed team information
- Includes all players in the team
- Shows owner and captain details

**Technical Specifications:**
- Endpoint: `GET /api/teams/my-team`
- Requires authentication
- Returns team with nested players array

**Acceptance Criteria:**
- ✅ Authenticated user can view their team
- ✅ All team details are returned
- ✅ Player list is included
- ✅ Unauthenticated requests are rejected

#### 4.2.3 Update Team
**Priority:** P1 (Should Have)

**Functional Requirements:**
- Update team name, location, logo
- Only team owner can update
- Captain and vice-captain can be designated

**Technical Specifications:**
- Endpoint: `PUT /api/teams/update`
- Requires authentication
- Validates ownership (owner_id = user.id)

**Acceptance Criteria:**
- ✅ Team owner can update team details
- ✅ Non-owners cannot update
- ✅ Changes are persisted correctly

---

### 4.3 Player Management

#### 4.3.1 Add Player
**Priority:** P0 (Must Have)

**Functional Requirements:**
- Add player to authenticated user's team
- Required: player name, role
- Optional: player image URL
- Roles: Batsman, Bowler, All-rounder, Wicketkeeper
- Initialize statistics to zero

**Technical Specifications:**
- Endpoint: `POST /api/players`
- Requires authentication
- Validates user owns team (owner_id = user.id)

**Acceptance Criteria:**
- ✅ Team owner can add players to their team
- ✅ Player statistics initialized to zero
- ✅ Player roles are validated
- ✅ Non-owners cannot add players

#### 4.3.2 View Players
**Priority:** P0 (Must Have)

**Functional Requirements:**
- Get all players for a specific team
- Public endpoint
- Returns player details and statistics

**Technical Specifications:**
- Endpoint: `GET /api/players/team/:team_id`
- No authentication required

**Acceptance Criteria:**
- ✅ Any user can view team players
- ✅ Statistics are accurate
- ✅ Players sorted appropriately

#### 4.3.3 Update Player
**Priority:** P1 (Should Have)

**Functional Requirements:**
- Update player details (name, role, image)
- Only team owner can update
- Cannot change team assignment directly

**Technical Specifications:**
- Endpoint: `PUT /api/players/:id`
- Requires authentication and ownership (owner_id = user.id)

**Acceptance Criteria:**
- ✅ Team owner can update player details
- ✅ Non-owners cannot update
- ✅ Team assignment cannot be changed

#### 4.3.4 Delete Player
**Priority:** P1 (Should Have)

**Functional Requirements:**
- Remove player from team
- Only team owner can delete
- Cascade: removes player match stats

**Technical Specifications:**
- Endpoint: `DELETE /api/players/:id`
- Foreign key cascade delete
- Requires ownership (owner_id = user.id)

**Acceptance Criteria:**
- ✅ Team owner can delete players
- ✅ Associated stats are cleaned up
- ✅ Non-owners cannot delete

---

### 4.4 Tournament Management

#### 4.4.1 Create Tournament
**Priority:** P0 (Must Have)

**Functional Requirements:**
- Authenticated users can create tournaments
- Required: tournament name, location, start date
- Default status: 'not_started' or 'upcoming'
- Creator becomes tournament organizer

**Technical Specifications:**
- Endpoint: `POST /api/tournaments`
- Requires authentication
- Status ENUM: upcoming, not_started, live, completed, abandoned

**Acceptance Criteria:**
- ✅ User can create tournament
- ✅ Required fields validated
- ✅ Creator stored as `created_by`
- ✅ Status defaults to 'not_started'

#### 4.4.2 List Tournaments
**Priority:** P0 (Must Have)

**Functional Requirements:**
- Public endpoint to view all tournaments
- Filter by status (optional)
- Returns basic tournament info

**Technical Specifications:**
- Endpoint: `GET /api/tournaments`
- Optional query params: ?status=live

**Acceptance Criteria:**
- ✅ All tournaments are listed
- ✅ Filtering by status works
- ✅ Public access (no auth required)

#### 4.4.3 Update Tournament
**Priority:** P1 (Should Have)

**Functional Requirements:**
- Update tournament details
- Only creator can update
- Can change status (upcoming → live → completed)

**Technical Specifications:**
- Endpoint: `PUT /api/tournaments/:id`
- Validates creator ownership

**Acceptance Criteria:**
- ✅ Creator can update tournament
- ✅ Non-creators cannot update
- ✅ Status transitions are valid

#### 4.4.4 Delete Tournament
**Priority:** P1 (Should Have)

**Functional Requirements:**
- Delete tournament
- Only creator can delete
- Cascade deletes matches and stats

**Technical Specifications:**
- Endpoint: `DELETE /api/tournaments/:id`
- Cascade delete configured in database

**Acceptance Criteria:**
- ✅ Creator can delete tournament
- ✅ Associated data is cleaned up
- ✅ Non-creators cannot delete

---

### 4.5 Tournament Team Management

#### 4.5.1 Add Team to Tournament
**Priority:** P0 (Must Have)

**Functional Requirements:**
- Add registered team OR temporary team
- Registered team: provide team_id
- Temporary team: provide temp_team_name, temp_team_location
- Only tournament creator can add teams
- Cannot add teams once tournament started
- Prevent duplicate teams

**Technical Specifications:**
- Endpoint: `POST /api/tournament-teams`
- Validates tournament status = 'upcoming' or 'not_started'
- Checks ownership via `created_by`

**Acceptance Criteria:**
- ✅ Creator can add registered teams
- ✅ Creator can add temporary teams
- ✅ Duplicate teams are rejected
- ✅ Cannot add after tournament starts
- ✅ Non-creators cannot add teams

#### 4.5.2 List Tournament Teams
**Priority:** P0 (Must Have)

**Functional Requirements:**
- Get all teams in a tournament
- Returns registered and temporary teams
- Public endpoint

**Technical Specifications:**
- Endpoint: `GET /api/tournament-teams/:tournament_id`
- Joins with teams table for registered teams

**Acceptance Criteria:**
- ✅ All tournament teams are listed
- ✅ Both registered and temp teams shown
- ✅ Public access works

#### 4.5.3 Update Tournament Team
**Priority:** P2 (Nice to Have)

**Functional Requirements:**
- Update temporary team details only
- Cannot update registered teams
- Only creator can update

**Technical Specifications:**
- Endpoint: `PUT /api/tournament-teams`
- Validates team is temporary (team_id IS NULL)

**Acceptance Criteria:**
- ✅ Creator can update temp team names
- ✅ Cannot update registered teams
- ✅ Cannot update after tournament starts

#### 4.5.4 Remove Team from Tournament
**Priority:** P2 (Nice to Have)

**Functional Requirements:**
- Remove team from tournament
- Cannot remove if team has matches
- Only creator can remove
- Cannot remove after tournament starts

**Technical Specifications:**
- Endpoint: `DELETE /api/tournament-teams`
- Checks for existing matches

**Acceptance Criteria:**
- ✅ Creator can remove teams with no matches
- ✅ Cannot remove teams with matches
- ✅ Cannot remove after tournament starts

---

### 4.6 Match Management

#### 4.6.1 Create Match
**Priority:** P0 (Must Have)

**Functional Requirements:**
- Create match within a tournament
- Required: team1_id, team2_id, overs, match_datetime
- Teams can be tournament_teams IDs
- Default status: 'not_started'
- Only tournament creator can create

**Technical Specifications:**
- Endpoint: `POST /api/tournament-matches`
- Links to tournament_teams via team1_tournament_team_id, team2_tournament_team_id
- Overs default: 20

**Acceptance Criteria:**
- ✅ Creator can create matches
- ✅ Teams must be in tournament
- ✅ Match datetime is validated
- ✅ Overs are configurable

#### 4.6.2 List Matches
**Priority:** P0 (Must Have)

**Functional Requirements:**
- Get all matches for a tournament
- Filter by status (optional)
- Public endpoint
- Returns team names and match details

**Technical Specifications:**
- Endpoint: `GET /api/tournament-matches/:tournament_id`
- Joins with teams/tournament_teams

**Acceptance Criteria:**
- ✅ All matches are listed
- ✅ Status filtering works
- ✅ Team names are resolved

#### 4.6.3 Update Match Status
**Priority:** P0 (Must Have)

**Functional Requirements:**
- Update match status
- Transitions: not_started → live → completed
- Can mark as abandoned
- Only team owners or creator can update

**Technical Specifications:**
- Endpoint: `PUT /api/tournament-matches/:id`
- Validates user authorization

**Acceptance Criteria:**
- ✅ Authorized users can update status
- ✅ Status transitions are valid
- ✅ Unauthorized users are rejected

---

### 4.7 Live Scoring

#### 4.7.1 Start Innings
**Priority:** P0 (Must Have)

**Functional Requirements:**
- Start a new innings for a match
- Required: match_id, batting_team_id, bowling_team_id, inning_number
- Match must be in 'live' status
- Initialize runs=0, wickets=0, overs=0
- Status: 'in_progress'

**Technical Specifications:**
- Endpoint: `POST /api/live/start-innings`
- Creates record in match_innings table

**Acceptance Criteria:**
- ✅ Team owner can start innings for live match
- ✅ Cannot start if match not live
- ✅ Statistics initialized correctly

#### 4.7.2 Add Ball (Ball-by-Ball Scoring)
**Priority:** P0 (Must Have)

**Functional Requirements:**
- Record each ball delivered
- Required: match_id, inning_id, over_number, ball_number, batsman_id, bowler_id, runs
- Optional: extras, wicket_type, out_player_id
- Update innings totals automatically
- Update player statistics automatically (if scorer is team owner)
- Auto-end innings if:
  - 10 wickets fall
  - Overs completed (match overs reached)
- Team owner authorization check (owner_id = user.id)

**Technical Specifications:**
- Endpoint: `POST /api/live/add-ball`
- Updates match_innings (runs, wickets, overs)
- Updates player_match_stats (runs, balls_faced, balls_bowled, runs_conceded, wickets)
- Uses owner_id for authorization

**Acceptance Criteria:**
- ✅ Authorized scorer can add balls
- ✅ Innings totals update correctly
- ✅ Player stats update correctly
- ✅ Auto-end works on 10 wickets
- ✅ Auto-end works on overs complete
- ✅ Ball number sequence validated (1-6)

#### 4.7.3 End Innings Manually
**Priority:** P1 (Should Have)

**Functional Requirements:**
- Manually end innings before all out/overs
- Set status to 'completed'
- Only team owner can end

**Technical Specifications:**
- Endpoint: `POST /api/live/end-innings`
- Updates match_innings.status
- Requires ownership (owner_id = user.id)

**Acceptance Criteria:**
- ✅ Team owner can end innings
- ✅ Status changes to completed
- ✅ Cannot end already completed innings

#### 4.7.4 Get Live Score
**Priority:** P0 (Must Have)

**Functional Requirements:**
- Get current match score
- Returns all innings data
- Returns ball-by-ball data
- Returns player statistics
- Public endpoint

**Technical Specifications:**
- Endpoint: `GET /api/live/:match_id`
- Returns innings, balls, players arrays

**Acceptance Criteria:**
- ✅ Current score is accurate
- ✅ All innings are returned
- ✅ Ball-by-ball data included
- ✅ Player stats included

---

### 4.8 Match Finalization

#### 4.8.1 Finalize Match
**Priority:** P0 (Must Have)

**Functional Requirements:**
- Mark match as completed
- Determine winner based on runs
- Update team statistics (matches_played, matches_won)
- Only team owner of participating team can finalize
- All innings should be completed

**Technical Specifications:**
- Endpoint: `POST /api/match-finalization/finalize`
- Compares innings runs to determine winner
- Updates teams table
- Sets match.status = 'completed', match.winner_team_id

**Acceptance Criteria:**
- ✅ Team owner can finalize match
- ✅ Winner determined correctly
- ✅ Team stats updated
- ✅ Match status set to completed

---

### 4.9 Scorecards & Statistics

#### 4.9.1 Get Match Scorecard
**Priority:** P0 (Must Have)

**Functional Requirements:**
- Get complete scorecard for completed match
- Organized by innings
- Shows batting and bowling statistics
- Public endpoint
- Proper integer parsing for match_id parameter

**Technical Specifications:**
- Endpoint: `GET /api/viewer/scorecard/:match_id`
- Parses match_id as Number with validation
- Returns match info + innings with batting/bowling arrays

**Acceptance Criteria:**
- ✅ Complete scorecard returned
- ✅ Organized by innings
- ✅ Batting stats accurate
- ✅ Bowling stats accurate
- ✅ Invalid match_id rejected

#### 4.9.2 Get Player Stats by Match
**Priority:** P1 (Should Have)

**Functional Requirements:**
- Get all player statistics for a specific match
- Includes player names and team info
- Sorted by runs DESC, wickets DESC

**Technical Specifications:**
- Endpoint: `GET /api/player-match-stats/match/:match_id`
- Joins with players and teams tables

**Acceptance Criteria:**
- ✅ All player stats returned
- ✅ Sorted correctly
- ✅ Team info included

#### 4.9.3 Get Player Stats by Tournament
**Priority:** P1 (Should Have)

**Functional Requirements:**
- Aggregate player statistics across tournament
- Includes: total runs, balls faced, fours, sixes, balls bowled, runs conceded, wickets, catches, runouts
- Calculate strike rate and economy rate
- Group by player

**Technical Specifications:**
- Endpoint: `GET /api/player-match-stats/tournament/:tournament_id`
- Aggregates from player_match_stats
- Calculates derived metrics (strike rate, economy)

**Acceptance Criteria:**
- ✅ Aggregated stats are accurate
- ✅ Strike rate calculated correctly
- ✅ Economy rate calculated correctly
- ✅ Sorted by performance

#### 4.9.4 Get Team Tournament Summary
**Priority:** P1 (Should Have)

**Functional Requirements:**
- Get team performance in a tournament
- Win/loss record
- Total runs scored/conceded
- Top performers

**Technical Specifications:**
- Endpoint: `GET /api/tournament-summary/:tournament_id/:team_id`

**Acceptance Criteria:**
- ✅ Team stats accurate
- ✅ Top performers identified
- ✅ Win/loss calculated correctly

---

### 4.10 Feedback System

#### 4.10.1 Submit Feedback
**Priority:** P2 (Nice to Have)

**Functional Requirements:**
- Users can submit feedback (authenticated or anonymous)
- Required: message (5-2000 characters)
- Optional: contact information
- Profanity filter with word boundaries
- Whitespace normalization
- Configurable profanity list via PROFANITY_FILTER env var
- IP and user agent logging for abuse monitoring

**Technical Specifications:**
- Endpoint: `POST /api/feedback`
- Optional authentication
- Length validation: min 5, max 2000 characters
- Word boundary regex for profanity detection
- Stores in feedback table

**Acceptance Criteria:**
- ✅ Valid feedback accepted
- ✅ Too short feedback rejected (< 5 chars)
- ✅ Too long feedback rejected (> 2000 chars)
- ✅ Profanity detected and rejected
- ✅ Whitespace normalized
- ✅ False positives avoided (word boundaries)

---

### 4.11 Ball-by-Ball Delivery Management

#### 4.11.1 Get Deliveries by Match
**Priority:** P1 (Should Have)

**Functional Requirements:**
- Get all deliveries for a match
- Includes batsman, bowler, fielder names
- Ordered by innings, over, ball
- Backward compatible with inning_id/innings_id columns
- Backward compatible with out_player_id/fielder_id columns

**Technical Specifications:**
- Endpoint: `GET /api/deliveries/match/:match_id`
- Uses COALESCE for column compatibility
- Joins with players table

**Acceptance Criteria:**
- ✅ All deliveries returned
- ✅ Properly ordered
- ✅ Player names resolved
- ✅ Works with legacy column names

#### 4.11.2 Get Deliveries by Innings
**Priority:** P1 (Should Have)

**Functional Requirements:**
- Get all deliveries for specific innings
- Same features as match deliveries

**Technical Specifications:**
- Endpoint: `GET /api/deliveries/innings/:innings_id`
- Uses COALESCE for backward compatibility

**Acceptance Criteria:**
- ✅ Innings deliveries returned
- ✅ Ordered correctly
- ✅ Player names included

---

## 5. Technical Requirements

### 5.1 Backend Architecture

#### 5.1.1 Technology Stack
- **Runtime:** Node.js >= 18.18.0
- **Framework:** Express.js 5.1.0
- **Database:** MySQL 2 with connection pooling
- **Authentication:** JWT (jsonwebtoken 9.0.2)
- **Password Hashing:** bcryptjs 2.4.3
- **Rate Limiting:** express-rate-limit 7.4.0
- **Logging:** pino-http 10.3.0
- **CORS:** cors 2.8.5

#### 5.1.2 Environment Variables

**Required:**
- `DB_HOST`: Database host
- `DB_USER`: Database username
- `DB_PASS`: Database password
- `DB_NAME`: Database name
- `JWT_SECRET`: Access token secret (min 32 chars)
- `JWT_REFRESH_SECRET`: Refresh token secret (min 32 chars)
- `JWT_AUD`: JWT audience identifier
- `JWT_ISS`: JWT issuer identifier

**Optional:**
- `PORT`: Server port (default: 5000)
- `NODE_ENV`: Environment (development/production/test)
- `CORS_ORIGINS`: Comma-separated allowed origins
- `COOKIE_SECURE`: Force secure cookies (true/false)
- `ROTATE_REFRESH_ON_USE`: Rotate refresh tokens (true/false)
- `PROFANITY_FILTER`: Comma-separated banned words

**Validation:**
- Development mode (`NODE_ENV=development`): Warnings only
- Production mode: Fatal errors with process.exit(1)
- Localhost origins auto-added in development

#### 5.1.3 Database Schema

**Core Tables:**
- `users`: User accounts (phone_number, password_hash, captain_name)
- `teams`: Cricket teams (team_name, location, owner_id, captain_id, stats)
- `players`: Team players (player_name, role, team_id, statistics)
- `tournaments`: Tournament definitions (name, location, start_date, status, created_by)
- `tournament_teams`: Teams in tournaments (tournament_id, team_id, temp team info)
- `matches`: Match records (tournament_id, teams, overs, datetime, status, winner)
- `match_innings`: Innings data (match_id, batting/bowling teams, runs, wickets, overs)
- `ball_by_ball`: Ball-by-ball records (match_id, inning_id, over, ball, batsman, bowler, runs, extras, wicket)
- `player_match_stats`: Player performance per match (runs, balls, wickets, etc.)

**Supporting Tables:**
- `refresh_tokens`: Token management (user_id, token, is_revoked)
- `password_resets`: Reset tokens (user_id, token_hash, expires_at)
- `auth_failures`: Failed login tracking (phone_number, failed_at, ip_address)
- `feedback`: User feedback (user_id, message, contact)
- `migrations`: Migration tracking (filename, executed_at)

#### 5.1.4 Migrations System
- Auto-runs on server startup
- Tracked in `migrations` table
- Executes in lexicographic order (YYYY-MM-DD_description.sql)
- Idempotent design with IF NOT EXISTS clauses
- Key migrations:
  - Schema bootstrap
  - Tournament matches structure
  - Owner and captain fields
  - Refresh tokens
  - Database unification
  - Indexes for performance
  - Auth failures tracking
  - Test user seeding

### 5.2 Security Requirements

#### 5.2.1 Authentication & Authorization
- JWT-based authentication with short-lived access tokens (15 min)
- Refresh tokens with 7-day expiry
- httpOnly cookies with secure flag in production
- sameSite: none for cross-site flows, lax for local dev
- Token revocation via database blacklist
- Progressive throttling on failed logins
- IP and user agent logging for security monitoring

#### 5.2.2 Password Security
- Minimum 8 characters
- bcrypt hashing with 12 salt rounds
- Password reset tokens: 48 random bytes, 15-minute expiry
- bcrypt-hashed reset tokens in database
- Single-active reset token per user

#### 5.2.3 Rate Limiting
- Register: 20 requests per hour
- Login: 10 requests per 15 minutes
- Password reset: 5 requests per 15 minutes
- Change password/phone: 10 requests per 15 minutes
- Applied per route, not duplicated

#### 5.2.4 CORS Configuration
- Explicit origin allowlist (no wildcards with credentials)
- Auto-add localhost origins in development
- Credentials: true for cookie support
- Log allowed origins on startup

#### 5.2.5 Input Validation
- Phone number: E.164 format validation
- SQL injection prevention: parameterized queries
- Profanity filter with word boundaries
- Length constraints on all text inputs
- Integer parsing for numeric IDs

#### 5.2.6 Data Privacy
- Password never returned in responses
- Logging redacts sensitive headers (authorization, cookies)
- Failed login reasons not specific (prevent enumeration)
- Audit trail for auth failures

### 5.3 Performance Requirements

#### 5.3.1 Response Time Targets
- Authentication endpoints: < 300ms (p95)
- List endpoints: < 500ms (p95)
- Live scoring: < 400ms (p95)
- Scorecard generation: < 1000ms (p95)

#### 5.3.2 Database Optimization
- Indexes on foreign keys
- Indexes on frequently queried fields:
  - `users.phone_number` (UNIQUE)
  - `teams.owner_id`
  - `players.team_id`
  - `matches.tournament_id`, `matches.status`
  - `refresh_tokens.user_id`
  - `auth_failures.phone_number`, `auth_failures.failed_at`
- Connection pooling: 10 connections
- Prepared statement caching

#### 5.3.3 API Performance
- Request logging with pino (high-performance logger)
- Request ID tracking (UUID v4)
- Response compression (future enhancement)
- Pagination for list endpoints (future enhancement)

### 5.4 Error Handling

#### 5.4.1 HTTP Status Codes
- 200: Success
- 201: Created
- 400: Bad request / validation error
- 401: Unauthorized / invalid token
- 403: Forbidden / insufficient permissions
- 404: Resource not found
- 409: Conflict (duplicate resource)
- 429: Too many requests
- 500: Internal server error

#### 5.4.2 Error Response Format
```json
{
  "error": "Human-readable error message",
  "details": "Additional context (dev mode only)"
}
```

#### 5.4.3 Logging
- Error-level: All 500 errors, database failures
- Warn-level: Profanity attempts, suspicious activity
- Info-level: Server startup, migration status
- Debug-level: Request details (development only)

### 5.5 Database Connection Management
- Fail-fast on connection errors
- Process exit on startup failure
- Health check endpoint: `GET /health`
- Returns: `{ status: 'ok', version: string, db: 'up'|'down' }`
- Schema bootstrap before migrations
- Migration tracking to prevent re-runs

---

## 6. API Specification Summary

### 6.1 Authentication Routes (`/api/auth`)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | /register | No | Register new captain |
| POST | /login | No | Login (rate-limited) |
| POST | /refresh | No | Refresh access token |
| POST | /logout | No | Logout and revoke token |
| POST | /forgot-password | No | Request password reset |
| POST | /verify-reset | No | Verify reset token |
| POST | /reset-password | No | Complete password reset |
| PUT | /change-password | Yes | Change password |
| PUT | /change-phone | Yes | Change phone number |

### 6.2 Team Routes (`/api/teams`)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | / | No | Get all teams |
| GET | /my-team | Yes | Get authenticated user's team |

### 6.3 Player Routes (`/api/players`)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | / | Yes | Add player to team |
| GET | /team/:team_id | No | Get team players |

### 6.4 Tournament Routes (`/api/tournaments`)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | / | Yes | Create tournament |
| GET | / | No | List all tournaments |

### 6.5 Tournament Team Routes (`/api/tournament-teams`)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | / | Yes | Add team to tournament |
| GET | /:tournament_id | No | Get tournament teams |

### 6.6 Match Routes (`/api/tournament-matches`)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | / | Yes | Create match |
| GET | /:tournament_id | No | Get tournament matches |

### 6.7 Live Scoring Routes (`/api/live`)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | /start-innings | Yes | Start new innings |
| POST | /add-ball | Yes | Record ball delivery |
| POST | /end-innings | Yes | End innings manually |
| GET | /:match_id | No | Get live score |

### 6.8 Scorecard Routes (`/api/viewer/scorecard`)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | /:match_id | No | Get match scorecard |

### 6.9 Player Stats Routes (`/api/player-match-stats`)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | /match/:match_id | No | Get stats by match |
| GET | /tournament/:tournament_id | No | Get stats by tournament |

### 6.10 Deliveries Routes (`/api/deliveries`)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | /match/:match_id | No | Get all deliveries for match |
| GET | /innings/:innings_id | No | Get deliveries for innings |

### 6.11 Feedback Routes (`/api/feedback`)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | / | Optional | Submit feedback |

---

## 7. Frontend Requirements (Flutter)

### 7.1 Platform Support
- iOS: 12.0+
- Android: API level 21+ (Android 5.0)

### 7.2 Key Screens
1. **Authentication**
   - Login screen
   - Registration screen
   - Password reset flow

2. **Dashboard**
   - My team overview
   - Upcoming matches
   - Recent results

3. **Team Management**
   - Team details
   - Player roster
   - Add/edit players

4. **Tournament**
   - Tournament list
   - Tournament details
   - Standings
   - Fixtures

5. **Live Scoring**
   - Match scoring interface
   - Ball-by-ball entry
   - Live scorecard view

6. **Statistics**
   - Player stats
   - Team stats
   - Tournament leaders

### 7.3 State Management
- Provider pattern for state management
- Secure storage for tokens (flutter_secure_storage)
- API client with interceptors for auth

### 7.4 Offline Capability
- Cache team and player data
- Queue scoring actions when offline
- Sync when connection restored

---

## 8. Testing Requirements

### 8.1 Backend Testing

#### 8.1.1 Unit Tests
- Controller logic testing
- Input validation testing
- Business rule verification

#### 8.1.2 Integration Tests
- API endpoint testing with supertest
- Database operations
- Auth flow end-to-end
- Test structure in `backend/__tests__/`:
  - auth.test.js
  - teams.test.js
  - tournaments.test.js
  - feedback.test.js

#### 8.1.3 Test Configuration
- Jest test framework
- Test database isolation
- Mock data seeding
- Test credentials: phone 12345678, password 12345678

### 8.2 Frontend Testing
- Widget tests for UI components
- Integration tests for user flows
- Golden tests for UI consistency

### 8.3 Test Coverage Targets
- Backend: 70% code coverage minimum
- Frontend: 60% code coverage minimum
- Critical paths: 90%+ coverage

---

## 9. Deployment & DevOps

### 9.1 Environment Setup

#### 9.1.1 Development
- Local MySQL instance or Docker
- Node.js 18+
- Environment file with test credentials
- Auto-seed test data on startup

#### 9.1.2 Staging
- Cloud database (PlanetScale or similar)
- NODE_ENV=production for validation
- SSL/TLS required
- CORS configured for staging domains

#### 9.1.3 Production
- Database replication for high availability
- Connection pooling tuned for load
- All env validation enforced
- Secure cookies enabled
- Rate limiting strictly enforced

### 9.2 Monitoring & Logging
- Request/response logging with pino
- Error tracking and alerting
- Performance metrics (response times)
- Database query performance monitoring
- Health check endpoint monitoring

### 9.3 Backup & Recovery
- Daily database backups
- Point-in-time recovery capability
- Migration rollback procedures
- Disaster recovery plan

---

## 10. Future Enhancements

### 10.1 Phase 2 Features (3-6 months)

#### 10.1.1 Advanced Statistics
- Career statistics across all tournaments
- Head-to-head team comparisons
- Player rankings (batsmen, bowlers)
- Team performance analytics
- Match predictions based on historical data

#### 10.1.2 Media & Social
- Match photos and videos
- Team galleries
- Social sharing of scores
- Match highlights

#### 10.1.3 Scheduling & Notifications
- Automated fixture generation
- Push notifications for match reminders
- Score update notifications
- Tournament announcements

#### 10.1.4 Advanced Tournament Formats
- Knockout stages
- League+playoffs format
- Points table calculation
- Net run rate calculations

### 10.2 Phase 3 Features (6-12 months)

#### 10.2.1 Live Streaming
- Match live streaming integration
- Commentary system
- Real-time viewer count

#### 10.2.2 Sponsorship & Monetization
- Team sponsorship management
- Tournament sponsorships
- Digital scoreboard with ads

#### 10.2.3 Umpire & Scorer Tools
- Dedicated umpire app
- Third umpire decision review
- Automated scoring via ML (ball tracking)

#### 10.2.4 Fan Engagement
- Fan voting (man of the match)
- Fantasy cricket within tournaments
- Prediction games

### 10.3 Technical Improvements

#### 10.3.1 Performance
- Redis caching layer
- CDN for static assets
- Database query optimization
- Pagination for large result sets
- Response compression

#### 10.3.2 Scalability
- Microservices architecture
- Horizontal scaling with load balancers
- Database sharding for large datasets
- Event-driven architecture for real-time updates

#### 10.3.3 Security
- Two-factor authentication
- OAuth integration (Google, Facebook)
- Advanced fraud detection
- DDoS protection

---

## 11. Success Metrics & KPIs

### 11.1 User Metrics
- **Monthly Active Users (MAU):** Target 500+ after 6 months
- **Daily Active Users (DAU):** Target 200+ after 6 months
- **User Retention Rate:** 60%+ after 30 days
- **Average Session Duration:** 15+ minutes

### 11.2 Engagement Metrics
- **Matches Created per Month:** 100+ matches
- **Live Scoring Adoption:** 80% of matches use live scoring
- **Player Profiles Created:** 2000+ players
- **Tournaments Created:** 20+ per month

### 11.3 Technical Metrics
- **API Uptime:** 99.5%+
- **Average Response Time:** < 500ms (p95)
- **Error Rate:** < 1% of requests
- **Database Query Performance:** < 100ms (p90)

### 11.4 Business Metrics
- **User Acquisition Cost:** Track marketing spend vs signups
- **Feature Adoption Rate:** Track usage of new features
- **Customer Satisfaction Score (CSAT):** Target 4.0+/5.0
- **Net Promoter Score (NPS):** Target 40+

---

## 12. Compliance & Legal

### 12.1 Data Protection
- GDPR compliance for EU users
- Data retention policies
- Right to deletion
- Data export capability

### 12.2 Privacy
- Privacy policy documentation
- Terms of service
- Cookie policy
- User consent management

### 12.3 Content Moderation
- Profanity filtering in feedback
- Abuse reporting system
- Content moderation guidelines

---

## 13. Support & Documentation

### 13.1 User Documentation
- Getting started guide
- Captain's handbook
- Tournament organizer guide
- FAQs

### 13.2 Technical Documentation
- API documentation (OpenAPI/Swagger)
- Database schema documentation
- Architecture diagrams
- Deployment guides

### 13.3 Support Channels
- In-app feedback system
- Email support
- FAQ/Help center
- Community forums

---

## 14. Risk Assessment

### 14.1 Technical Risks
| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Database downtime | High | Medium | Replication, backups, monitoring |
| API performance issues | High | Medium | Caching, optimization, load testing |
| Security breach | Critical | Low | Security audits, penetration testing |
| Data loss | Critical | Low | Regular backups, point-in-time recovery |

### 14.2 Business Risks
| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Low user adoption | High | Medium | Marketing, user testing, referrals |
| Competing products | Medium | High | Unique features, community building |
| Scalability issues | High | Medium | Cloud infrastructure, monitoring |
| Funding constraints | Medium | Low | MVP-first approach, phased rollout |

---

## 15. Timeline & Milestones

### 15.1 Phase 1: MVP (Current - Complete)
- ✅ User authentication system
- ✅ Team and player management
- ✅ Tournament creation and management
- ✅ Match scheduling
- ✅ Live ball-by-ball scoring
- ✅ Basic statistics and scorecards
- ✅ Feedback system
- ✅ Backend API complete
- ✅ Database schema and migrations
- ✅ Security hardening
- ✅ Test infrastructure

### 15.2 Phase 1.5: Testing & Polish (Next 1 month)
- Frontend implementation completion
- End-to-end testing
- Performance optimization
- Beta user testing
- Bug fixes and refinements

### 15.3 Phase 2: Enhanced Features (Months 2-4)
- Advanced statistics dashboard
- Push notifications
- Tournament bracket/knockout system
- Media uploads
- Social features

### 15.4 Phase 3: Scale & Monetize (Months 5-8)
- Sponsorship system
- Premium features
- Live streaming integration
- Analytics and insights
- Mobile app optimization

---

## 16. Conclusion

The Cricket League Management Application provides a comprehensive digital solution for organizing and managing cricket tournaments at the amateur and semi-professional level. The MVP delivers core functionality for team registration, tournament management, live scoring, and statistics tracking.

With a robust backend architecture, comprehensive security measures, and a mobile-first approach, the platform is positioned to scale and evolve based on user feedback and market demands.

**Next Steps:**
1. Complete frontend Flutter implementation
2. Conduct beta testing with select user groups
3. Gather feedback and iterate
4. Launch publicly with marketing campaign
5. Monitor metrics and optimize based on user behavior

---

**Document Version:** 1.0  
**Last Updated:** October 17, 2025  
**Status:** Living Document - Updated as requirements evolve

