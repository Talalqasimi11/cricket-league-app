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
- **Admin Panel:** React.js web application for system administration
- **Backend:** Node.js REST API with Express.js and WebSocket support
- **Database:** MySQL (PlanetScale-compatible)
- **Architecture:** Client-server with JWT-based authentication and real-time WebSocket updates

---

## 2. Business Objectives

### 2.1 Primary Goals
1. **Digitize Tournament Management:** Replace manual scorekeeping and tournament tracking with automated digital solutions
2. **Real-time Match Scoring:** Enable live ball-by-ball scoring accessible to players and spectators
3. **Player Statistics:** Automatically calculate and maintain comprehensive player performance metrics
4. **Team Management:** Provide tools for captains to manage their teams and players efficiently
5. **Tournament Creator Controls:** Give tournament creators centralized control over tournament management and scoring

### 2.2 Success Metrics
- **User Adoption:** 500+ registered users within 6 months, with 100+ users creating teams and 50+ creating tournaments
- **Engagement:** 80% of registered teams actively participate in tournaments, 70% coordinator engagement
- **Match Completion Rate:** 90% of started matches are completed with full scorecards
- **User Satisfaction:** 4.0+ star rating on app stores
- **API Performance:** < 500ms average response time for critical endpoints
- **Tournament Creation:** 300+ tournaments created within 6 months

---

## 3. User Personas

### 3.1 team registrar
**Age:** 28 | **Location:** Urban India | **Tech Savviness:** Medium

**Background:**
- Runs a local cricket team with 15 players
- Organizes weekend matches and participates in local tournaments
- Previously used WhatsApp groups and paper scorecards
- Registered user who creates and owns a team after registration

**Goals:**
- Easy team creation and player management
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
- Users register using phone number (E.164 format) or email address
- Password must be at least 8 characters
- Email validation for proper format when provided
- System validates unique phone numbers and email addresses
- Users do not automatically create teams during registration
- Team creation happens as a separate step after registration
- Optional fields: full name

**Technical Specifications:**
- Endpoint: `POST /api/auth/register`
- Password hashing: bcrypt with 12 salt rounds
- Phone validation: E.164 regex pattern
- Email validation: RFC 5322 compliant format
- Response: Success message (201) or error (400/409)

**Acceptance Criteria:**
- ✅ User can register with valid phone/email and password
- ✅ System rejects duplicate phone numbers
- ✅ System rejects duplicate email addresses
- ✅ System rejects passwords < 8 characters
- ✅ System rejects invalid phone number formats
- ✅ System rejects invalid email formats
- ✅ No team is automatically created upon registration

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

#### 4.2.1 Create Team
**Priority:** P0 (Must Have)

**Functional Requirements:**
- Authenticated users can create teams after registration
- Required: team name, location
- Optional: team logo URL
- User becomes team owner upon creation
- One team per user (prevent duplicate team ownership)
- Team creation is separate from user registration

**Technical Specifications:**
- Endpoint: `POST /api/teams`
- Requires authentication
- Validates user doesn't already own a team
- Response: Success message (201) or error (400/409)

**Acceptance Criteria:**
- ✅ Authenticated user can create a team
- ✅ System rejects duplicate team ownership
- ✅ Required fields validated
- ✅ User becomes team owner
- ✅ Team creation separate from registration

#### 4.2.2 View Teams
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

#### 4.2.3 View My Team
**Priority:** P0 (Must Have)

**Functional Requirements:**
- Authenticated endpoint for team owner
- Returns detailed team information
- Includes all players in the team
- Shows owner and captain details
- Shows "Add Team" button when user has no team

**Technical Specifications:**
- Endpoint: `GET /api/teams/my-team`
- Requires authentication
- Returns team with nested players array or null if no team

**Acceptance Criteria:**
- ✅ Authenticated user can view their team
- ✅ All team details are returned when team exists
- ✅ Player list is included
- ✅ Returns appropriate response when no team exists
- ✅ Unauthenticated requests are rejected

#### 4.2.4 Update Team
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
- **Complete separation: Any registered user can create tournaments (independent of team ownership)**
- Guest/unauthenticated users cannot create tournaments
- **Team owners have NO automatic participation privileges in ANY tournaments**
- **Tournament creator = Tournament Director with complete administrative authority**
- Tournament creator has sole authority to invite/select ANY registered teams
- Required: tournament name, location, start date, overs (5-50 range)
- Optional: end date, description
- **Teams are explicitly invited by tournament creator AFTER tournament creation**
- Creator becomes tournament administrator with exclusive management and live scoring rights
- No team owner can participate in tournaments without tournament creator invitation
- Overs constraint: 5-50 overs per innings

**Technical Specifications:**
- Endpoint: `POST /api/tournaments`
- Requires authentication
- Status ENUM: upcoming, not_started, live, completed, aborted
- Overs validation: INTEGER(2) with CHECK constraint (overs >= 5 AND overs <= 50)
- **Team selection completely separate** - tournament creator uses `/api/tournament-teams` to invite teams
- **Team ownership provides ZERO tournament privileges** - participation by invitation only

**Acceptance Criteria:**
- ✅ Any authenticated user can create tournament (regardless of team ownership)
- ✅ Guest users blocked from tournament creation
- ✅ Team owners have no automatic tournament participation rights
- ✅ Tournament creator acts as tournament director with complete authority
- ✅ Tournament creator can invite ANY registered teams (by invitation, not automatic)
- ✅ Teams participate ONLY by tournament creator invitation
- ✅ Overs must be between 5-50
- ✅ Tournament creator has exclusive management and live scoring rights

#### 4.4.1.1 List Tournaments with "My Tournaments" Section
**Priority:** P1 (Should Have)

**Functional Requirements:**
- Tournament list divided into sections: "All Tournaments" and "My Tournaments"
- "My Tournaments" section shows tournaments created by the authenticated user
- "My Tournaments" provides direct access to tournament management functions
- Public "All Tournaments" section shows all publicly visible tournaments
- User must close and reopen app for changes to reflect properly

**Technical Specifications:**
- Endpoint: `GET /api/tournaments` with user context
- Response includes separate arrays: { allTournaments: [...], myTournaments: [...] }
- My tournaments filtered by `created_by = user.id`
- Frontend must persist and restore user session state

**Acceptance Criteria:**
- ✅ Authenticated users see "My Tournaments" section
- ✅ "My Tournaments" shows tournaments they created
- ✅ Direct access to manage tournaments from the list
- ✅ App reopen required for session state restoration
- ✅ Guest users only see "All Tournaments" section

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
- Only tournament creator can start innings (not team owners)

**Technical Specifications:**
- Endpoint: `POST /api/live/start-innings`
- Authorization: tournament.created_by = user.id
- Creates record in match_innings table

**Acceptance Criteria:**
- ✅ Tournament creator can start innings for live match
- ✅ Team owners cannot start innings (only view)
- ✅ Cannot start if match not live
- ✅ Statistics initialized correctly

#### 4.7.2 Add Ball (Ball-by-Ball Scoring)
**Priority:** P0 (Must Have)

**Functional Requirements:**
- Record each ball delivered
- Required: match_id, inning_id, over_number, ball_number, batsman_id, bowler_id, runs
- Optional: extras, wicket_type, out_player_id
- Update innings totals automatically
- Update player statistics automatically (only for tournament creator)
- Auto-end innings if:
  - 10 wickets fall
  - Overs completed (match overs reached)
- Tournament creator authorization check (tournament.created_by = user.id)

**Technical Specifications:**
- Endpoint: `POST /api/live/add-ball`
- Updates match_innings (runs, wickets, overs)
- Updates player_match_stats (runs, balls_faced, balls_bowled, runs_conceded, wickets)
- Uses tournament.created_by for authorization

**Acceptance Criteria:**
- ✅ Tournament creator can add balls (exclusive scoring rights)
- ✅ Team owners cannot add balls (view-only access)
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
| POST | / | Yes | Create new team |
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
   - Registration screen (phone/email, no team creation)
   - Password reset flow

2. **Dashboard**
   - My team overview (shows "Add Team" when no team exists)
   - Upcoming matches
   - Recent results

3. **Team Management**
   - Create team screen (separate from registration)
   - Team details
   - Player roster
   - Add/edit players

4. **Tournament**
   - Tournament list
   - Tournament details (with bracket view)
   - Standings
   - Fixtures

5. **Live Scoring**
   - Match scoring interface
   - Ball-by-ball entry
   - Live scorecard view

6. **Statistics**
   - Overview dashboard
   - Player rankings
   - Team rankings
   - Tournament statistics

### 7.3 State Management
- Provider pattern for state management
- Secure storage for tokens (flutter_secure_storage)
- API client with interceptors for auth

### 7.4 Offline Capability
- Cache team and player data locally using Hive database
- Queue operations when offline with conflict resolution
- Automatic sync when connection restored
- Periodic background sync every 5 minutes
- Manual sync option for immediate updates
- Conflict resolution strategies (server wins, client wins, manual merge)

---

## 8. Admin Panel Requirements (React.js)

### 8.1 Platform Support
- **Web Browsers:** Chrome 90+, Firefox 88+, Safari 14+, Edge 90+
- **Responsive Design:** Desktop and tablet optimized

### 8.2 Key Features

#### 8.2.1 Authentication & User Management
- Admin login with phone number and password
- User management dashboard
- Promote/demote users to admin status
- Delete users (with cascade deletion of teams and data)
- Search and filter users by phone number or team name

#### 8.2.2 Dashboard & Analytics
- System overview with key metrics
- Total users, admins, teams, tournaments, matches
- Real-time statistics display
- Quick access to management sections

#### 8.2.3 Team Management
- View all registered teams
- Edit team details (name, location, logo)
- Delete teams (admin only)
- Team statistics and performance overview

#### 8.2.4 Tournament Management
- View all tournaments
- Edit tournament details
- Change tournament status
- Delete tournaments (with cascade deletion)

#### 8.2.5 Match Management
- View all matches across tournaments
- Update match status
- Monitor live matches
- Match statistics and details

#### 8.2.6 System Health Monitoring
- API health checks
- Database connection status
- System performance metrics
- Error logging and monitoring

#### 8.2.7 Reporting Dashboard
- Tournament participation reports
- Match completion statistics
- User engagement metrics
- System usage analytics

### 8.3 Technical Implementation
- **Framework:** React.js with hooks
- **State Management:** React Context API
- **Styling:** Tailwind CSS
- **HTTP Client:** Axios with interceptors
- **Charts:** Chart.js or Recharts for analytics
- **Notifications:** Toast notifications for user feedback

### 8.4 Security Features
- JWT-based authentication for admin users
- Role-based access control (admin vs regular users)
- Secure API endpoints with admin middleware
- Audit logging for admin actions
- Session management with automatic logout

---

## 9. Real-time Features (WebSocket)

### 9.1 Live Score Updates
- **WebSocket Namespace:** `/live-score`
- **Authentication:** JWT token in connection handshake
- **Events:**
  - `subscribe`: Subscribe to match updates
  - `scoreUpdate`: Real-time score changes
  - `inningsEnded`: Innings completion notifications
  - `error`: Connection and subscription errors

### 9.2 Connection Management
- Automatic reconnection with exponential backoff
- Connection pooling for multiple matches
- Graceful degradation when offline
- Connection status indicators in UI

### 9.3 Performance Optimization
- Efficient payload structure for score updates
- Minimal data transfer for real-time updates
- Connection multiplexing for multiple matches
- Automatic cleanup of inactive connections

---

## 10. File Upload System

### 10.1 Supported File Types
- **Images:** Player photos, team logos (JPEG, PNG, WebP)
- **Maximum Size:** 5MB per file
- **Storage:** Local file system with organized directories

### 10.2 Upload Features
- **Multer Integration:** Server-side file handling
- **Sharp Processing:** Image resizing and optimization
- **Validation:** File type and size verification
- **Directory Structure:** Organized by entity type (players/, teams/)

### 10.3 API Endpoints
- `POST /api/upload/player/:playerId`: Upload player image
- `POST /api/upload/team/:teamId`: Upload team logo
- `DELETE /api/upload/:fileId`: Delete uploaded file

### 10.4 Security Considerations
- File type validation (MIME type checking)
- Path traversal protection
- Upload rate limiting
- Automatic cleanup of orphaned files

---

## 11. Offline Capabilities (Advanced)

### 11.1 Local Data Storage
- **Database:** Hive (NoSQL key-value store for Flutter)
- **Entities:** Teams, players, tournaments, matches, pending operations
- **Synchronization:** Bidirectional sync with conflict resolution

### 11.2 Operation Queuing
- **Queue Management:** FIFO queue for offline operations
- **Operation Types:** Create, update, delete for all entities
- **Retry Logic:** Exponential backoff for failed operations
- **Priority System:** Critical operations prioritized

### 11.3 Conflict Resolution
- **Strategies:**
  - Server Wins: Server data takes precedence
  - Client Wins: Local changes override server
  - Manual Resolution: User chooses which version to keep
  - Merge: Attempt automatic data merging
- **Detection:** Timestamp and version-based conflict detection

### 11.4 Sync Management
- **Triggers:** Network restoration, manual sync, periodic sync
- **Progress Tracking:** Visual progress indicators
- **Error Handling:** Detailed error reporting and recovery options
- **Background Sync:** Automatic sync when app is in background

---

## 12. Technical Requirements Update

### 12.1 Backend Architecture Update

#### 12.1.1 Technology Stack Update
- **Runtime:** Node.js >= 18.18.0
- **Framework:** Express.js 5.1.0
- **Database:** MySQL 2 with connection pooling
- **Real-time:** Socket.IO 4.8.1 with Redis adapter
- **Caching:** Redis 5.9.0 for session management
- **File Upload:** Multer 1.4.5-lts.1 with Sharp 0.33.0
- **Authentication:** JWT (jsonwebtoken 9.0.2)
- **Password Hashing:** bcryptjs 2.4.3
- **Rate Limiting:** express-rate-limit 7.4.0
- **Logging:** pino-http 10.3.0
- **CORS:** cors 2.8.5
- **Security:** Helmet 8.0.0

#### 12.1.2 Environment Variables Update

**Required:**
- `DB_HOST`: Database host
- `DB_USER`: Database username
- `DB_PASS`: Database password
- `DB_NAME`: Database name
- `JWT_SECRET`: Access token secret (min 32 chars)
- `JWT_REFRESH_SECRET`: Refresh token secret (min 32 chars)
- `JWT_AUD`: JWT audience identifier
- `JWT_ISS`: JWT issuer identifier
- `REDIS_URL`: Redis connection URL for WebSocket adapter

**Optional:**
- `PORT`: Server port (default: 5000)
- `NODE_ENV`: Environment (development/production/test)
- `CORS_ORIGINS`: Comma-separated allowed origins
- `COOKIE_SECURE`: Force secure cookies (true/false)
- `ROTATE_REFRESH_ON_USE`: Rotate refresh tokens (true/false)
- `PROFANITY_FILTER`: Comma-separated banned words
- `UPLOAD_PATH`: File upload directory (default: ./uploads)
- `MAX_FILE_SIZE`: Maximum upload size in bytes (default: 5242880)

---

## 13. Testing Requirements Update

### 13.1 Backend Testing Update

#### 13.1.1 Unit Tests
- Controller logic testing
- Input validation testing
- Business rule verification
- WebSocket event handling
- File upload validation

#### 13.1.2 Integration Tests
- API endpoint testing with supertest
- Database operations
- Auth flow end-to-end
- WebSocket connection and messaging
- File upload and processing
- Test structure in `backend/__tests__/`:
  - auth.test.js
  - teams.test.js
  - tournaments.test.js
  - feedback.test.js
  - websocket.test.js
  - upload.test.js

#### 13.1.3 Test Configuration
- Jest test framework
- Test database isolation
- Mock data seeding
- Test credentials: phone 12345678, password 12345678
- Mock file uploads for testing

### 13.2 Frontend Testing Update
- Widget tests for UI components
- Integration tests for user flows
- Offline functionality testing
- WebSocket connection testing
- File upload testing
- Golden tests for UI consistency

### 13.3 Admin Panel Testing
- Component testing with React Testing Library
- E2E testing with Cypress or Playwright
- API integration testing
- Authentication flow testing

### 13.4 Test Coverage Targets Update
- Backend: 75% code coverage minimum
- Frontend: 65% code coverage minimum
- Admin Panel: 70% code coverage minimum
- Critical paths: 90%+ coverage

---

## 14. API Specification Summary Update

### 14.1 Admin Routes (`/api/admin`)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | /dashboard | Admin | Get dashboard statistics |
| GET | /users | Admin | Get all users |
| PUT | /users/:userId/admin | Admin | Toggle admin status |
| DELETE | /users/:userId | Admin | Delete user |
| GET | /teams | Admin | Get all teams |
| GET | /teams/:teamId | Admin | Get team details |
| PUT | /teams/:teamId | Admin | Update team |
| DELETE | /teams/:teamId | Admin | Delete team |

### 14.2 Upload Routes (`/api/upload`)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | /player/:playerId | Yes | Upload player image |
| POST | /team/:teamId | Yes | Upload team logo |
| DELETE | /:fileId | Yes | Delete uploaded file |

### 14.3 WebSocket Events
| Event | Direction | Description |
|-------|-----------|-------------|
| subscribe | Client→Server | Subscribe to match updates |
| subscribed | Server→Client | Subscription confirmation |
| scoreUpdate | Server→Client | Real-time score update |
| inningsEnded | Server→Client | Innings completion |
| error | Server→Client | Error notification |

---

## 15. Timeline & Milestones Update

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
- ✅ Admin panel (dashboard, user/team management)
- ✅ Real-time WebSocket updates
- ✅ File upload system
- ✅ Offline capabilities with conflict resolution

### 15.2 Phase 1.5: Testing & Polish (Next 1 month)
- Frontend implementation completion
- Admin panel feature completion
- WebSocket integration testing
- Offline functionality testing
- File upload testing
- End-to-end testing
- Performance optimization
- Beta user testing
- Bug fixes and refinements

### 15.3 Phase 2: Enhanced Features (Months 2-4)
- Advanced statistics dashboard
- Push notifications
- Tournament bracket/knockout system
- Media uploads and galleries
- Social sharing features
- Advanced reporting and analytics
- Mobile app store deployment

### 15.4 Phase 3: Scale & Monetize (Months 5-8)
- Sponsorship system
- Premium features
- Live streaming integration
- Advanced analytics and insights
- Multi-language support
- Mobile app optimization and marketing

---

## 16. Conclusion Update

The Cricket League Management Application provides a comprehensive digital solution for organizing and managing cricket tournaments at the amateur and semi-professional level. The MVP delivers core functionality for team registration, tournament management, live scoring, statistics tracking, and system administration.

**Key Differentiators:**
- Real-time score updates via WebSocket
- Comprehensive offline capabilities
- Full-featured admin panel for system management
- File upload support for player photos and team logos
- Advanced conflict resolution for offline operations

With a robust backend architecture, comprehensive security measures, real-time capabilities, and offline support, the platform is positioned to scale and evolve based on user feedback and market demands.

**Next Steps:**
1. Complete frontend Flutter implementation with offline and WebSocket integration
2. Finalize admin panel features and testing
3. Conduct comprehensive beta testing with real users
4. Deploy mobile apps to app stores
5. Launch marketing campaign targeting cricket communities
6. Monitor metrics and iterate based on user behavior

---

**Document Version:** 1.2
**Last Updated:** November 14, 2025
**Status:** Living Document - Updated as requirements evolve
