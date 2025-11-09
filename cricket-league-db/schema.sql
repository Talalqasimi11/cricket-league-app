
-- Create the new database
-- Note: Prefer using backend migrations to manage schema. This file is kept minimal.
-- NOTE: Prefer using backend migrations to manage schema. This schema file is
-- provided for local bootstrap only and reflects the current migrations.

-- 1. Users (Team Owners/Captains)
-- This table stores login information. The user who creates a team is its owner.
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL
) ENGINE=InnoDB;

-- Refresh Tokens table (auth)
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  token VARCHAR(512) NOT NULL,
  is_revoked TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  revoked_at TIMESTAMP NULL DEFAULT NULL,
  CONSTRAINT fk_refresh_tokens_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY uq_refresh_token (token),
  KEY idx_refresh_user (user_id)
);

-- Password reset tokens table
CREATE TABLE IF NOT EXISTS password_resets (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  token_hash VARCHAR(255) NOT NULL,
  expires_at DATETIME NOT NULL,
  used_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_password_resets_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  KEY idx_password_resets_user (user_id)
);

-- Feedback table
CREATE TABLE IF NOT EXISTS feedback (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NULL,
  message TEXT NOT NULL,
  contact VARCHAR(255) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_feedback_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  KEY idx_feedback_user (user_id)
);

-- 2. Teams
-- Each team is owned by one user. The `owner_id` links to the users table.
-- Only one player can be captain per team, assigned by the user.
CREATE TABLE IF NOT EXISTS teams (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner_id INT NOT NULL,
    team_name VARCHAR(100) NOT NULL,
    team_location VARCHAR(100) NOT NULL,
    team_logo_url VARCHAR(255) NULL,
    matches_played INT DEFAULT 0,
    matches_won INT DEFAULT 0,
    trophies INT DEFAULT 0,
    captain_player_id INT NULL,
    vice_captain_player_id INT NULL,
    -- Foreign key to the user who owns the team
    CONSTRAINT fk_team_owner FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE,
    -- Foreign key constraints for captain and vice-captain will be added after players table is created
    -- Ensure captain and vice-captain are different
    CONSTRAINT teams_captain_vice_distinct CHECK (captain_player_id IS NULL OR vice_captain_player_id IS NULL OR captain_player_id <> vice_captain_player_id),
    -- Ensure only one team per captain
    CONSTRAINT uq_teams_captain_player_id UNIQUE (captain_player_id)
) ENGINE=InnoDB;

-- 3. Players
-- Players belong to a team. If a team is deleted, its players are also deleted.
CREATE TABLE IF NOT EXISTS players (
    id INT AUTO_INCREMENT PRIMARY KEY,
    team_id INT NOT NULL,
    player_name VARCHAR(100) NOT NULL,
    player_role ENUM('Batsman','Bowler','All-rounder','Wicket-keeper') NOT NULL,
    player_image_url VARCHAR(255) NULL,
    runs INT DEFAULT 0,
    matches_played INT DEFAULT 0,
    hundreds INT DEFAULT 0,
    fifties INT DEFAULT 0,
    batting_average DECIMAL(5,2) DEFAULT 0.00,
    strike_rate DECIMAL(5,2) DEFAULT 0.00,
    wickets INT DEFAULT 0,
    CONSTRAINT fk_player_team FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Add foreign key constraints for team captain and vice-captain after players table is created
ALTER TABLE teams ADD CONSTRAINT fk_team_captain FOREIGN KEY (captain_player_id) REFERENCES players(id) ON DELETE SET NULL;
ALTER TABLE teams ADD CONSTRAINT fk_team_vice_captain FOREIGN KEY (vice_captain_player_id) REFERENCES players(id) ON DELETE SET NULL;

-- 4. Tournaments
-- Tournaments are created by a user.
-- Status values: 'upcoming' (default), 'live', 'completed', 'abandoned'
CREATE TABLE IF NOT EXISTS tournaments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_name VARCHAR(100) NOT NULL,
    location VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    status ENUM('upcoming','live','completed','abandoned') NOT NULL DEFAULT 'upcoming',
    created_by INT NOT NULL,
    CONSTRAINT fk_tournament_creator FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 5. Tournament Teams
-- This table links teams to tournaments. It can include registered teams or temporary teams.
CREATE TABLE IF NOT EXISTS tournament_teams (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_id INT NOT NULL,
    team_id INT NULL, -- Link to a registered team
    temp_team_name VARCHAR(100), -- For teams not registered in the system
    temp_team_location VARCHAR(100),
    CONSTRAINT fk_tt_tournament FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE,
    CONSTRAINT fk_tt_team FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 6. Matches
-- This table holds records of individual matches, usually within a tournament.
CREATE TABLE IF NOT EXISTS matches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_id INT NULL,
    team1_id INT NOT NULL,
    team2_id INT NOT NULL,
    match_datetime DATETIME NOT NULL,
    venue VARCHAR(100) NOT NULL,
    status ENUM('not_started','live','completed','abandoned') DEFAULT 'not_started',
    overs INT NOT NULL DEFAULT 20,
    winner_team_id INT NULL,
    CONSTRAINT fk_match_tournament FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE SET NULL,
    CONSTRAINT fk_match_team1 FOREIGN KEY (team1_id) REFERENCES teams(id) ON DELETE CASCADE,
    CONSTRAINT fk_match_team2 FOREIGN KEY (team2_id) REFERENCES teams(id) ON DELETE CASCADE,
    CONSTRAINT fk_match_winner FOREIGN KEY (winner_team_id) REFERENCES teams(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 6b. Tournament Matches
-- This table holds tournament-specific match records with both direct team and tournament team references
CREATE TABLE IF NOT EXISTS tournament_matches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_id INT NOT NULL,
    team1_id INT NULL, -- Direct team reference
    team2_id INT NULL, -- Direct team reference
    team1_tt_id INT NULL, -- Tournament team reference
    team2_tt_id INT NULL, -- Tournament team reference
    round VARCHAR(50) NOT NULL DEFAULT 'round_1',
    match_date DATETIME NULL,
    location VARCHAR(255) NULL,
    status ENUM('upcoming','live','finished') NOT NULL DEFAULT 'upcoming',
    winner_id INT NULL,
    parent_match_id INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_tournament_match_tournament FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE,
    CONSTRAINT fk_tournament_match_team1 FOREIGN KEY (team1_id) REFERENCES teams(id) ON DELETE SET NULL,
    CONSTRAINT fk_tournament_match_team2 FOREIGN KEY (team2_id) REFERENCES teams(id) ON DELETE SET NULL,
    CONSTRAINT fk_tournament_match_team1_tt FOREIGN KEY (team1_tt_id) REFERENCES tournament_teams(id) ON DELETE SET NULL,
    CONSTRAINT fk_tournament_match_team2_tt FOREIGN KEY (team2_tt_id) REFERENCES tournament_teams(id) ON DELETE SET NULL,
    CONSTRAINT fk_tournament_match_winner FOREIGN KEY (winner_id) REFERENCES teams(id) ON DELETE SET NULL,
    CONSTRAINT fk_tournament_match_parent FOREIGN KEY (parent_match_id) REFERENCES tournament_matches(id) ON DELETE SET NULL,
    INDEX idx_tournament_matches_tournament_id (tournament_id),
    INDEX idx_tournament_matches_team1_id (team1_id),
    INDEX idx_tournament_matches_team2_id (team2_id),
    INDEX idx_tournament_matches_team1_tt_id (team1_tt_id),
    INDEX idx_tournament_matches_team2_tt_id (team2_tt_id),
    INDEX idx_tournament_matches_parent_match_id (parent_match_id)
) ENGINE=InnoDB;

-- 7. Match Innings
-- Stores the summary for each innings of a match.
CREATE TABLE IF NOT EXISTS match_innings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    match_id INT NOT NULL,
    team_id INT NOT NULL,
    inning_number INT NOT NULL DEFAULT 1,
    overs INT NOT NULL DEFAULT 0,
    status ENUM('in_progress','completed') NOT NULL DEFAULT 'in_progress',
    batting_team_id INT NULL,
    bowling_team_id INT NULL,
    runs INT DEFAULT 0,
    wickets INT DEFAULT 0,
    overs_decimal DECIMAL(4,1) DEFAULT 0.0,
    legal_balls INT DEFAULT 0,
    CONSTRAINT fk_innings_match FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE,
    CONSTRAINT fk_innings_team FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE,
    CONSTRAINT fk_innings_batting FOREIGN KEY (batting_team_id) REFERENCES teams(id) ON DELETE SET NULL,
    CONSTRAINT fk_innings_bowling FOREIGN KEY (bowling_team_id) REFERENCES teams(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 8. Player Match Stats
-- Records the performance of each player in a specific match.
CREATE TABLE IF NOT EXISTS player_match_stats (
    id INT AUTO_INCREMENT PRIMARY KEY,
    player_id INT NOT NULL,
    match_id INT NOT NULL,
    runs INT DEFAULT 0,
    balls_faced INT DEFAULT 0,
    balls_bowled INT DEFAULT 0,
    runs_conceded INT DEFAULT 0,
    wickets INT DEFAULT 0,
    fours INT DEFAULT 0,
    sixes INT DEFAULT 0,
    overs_bowled DECIMAL(4,1) DEFAULT 0.0,
    catches INT DEFAULT 0,
    stumpings INT DEFAULT 0,
    CONSTRAINT fk_stats_player FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE,
    CONSTRAINT fk_stats_match FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE,
    -- Add unique constraint for player_match_stats upsert semantics
    CONSTRAINT uq_player_match_stats UNIQUE (match_id, player_id)
) ENGINE=InnoDB;

-- 9. Ball-by-Ball
-- Stores the detailed record of every ball bowled in a match.
-- 
-- Scoring Data Model:
-- The 'runs' field represents TOTAL runs for the delivery:
--   - Legal balls (extras=NULL): runs off bat, 0-6
--   - Wides/No-balls (extras='wide'|'no-ball'): penalty/extra runs, 0+
--   - Byes/Leg-byes (extras='bye'|'leg-bye'): unearned runs, 1+
--
-- Extras types indicate the nature of the delivery and constraints on 'runs':
--   - NULL: legal delivery, 0-6 runs
--   - 'wide': wide ball, 0+ runs (typically 1+ for penalty runs)
--   - 'no-ball': no-ball (illegal), 0+ runs (typically 1+ for penalty runs)
--   - 'bye': runs without bat contact, 1+ runs (must have runs)
--   - 'leg-bye': leg-bye, 1+ runs (must have runs)
--
-- Over/Ball Numbering:
--   - over_number: 0-based (0 = first over)
--   - ball_number: 1-based (1-6 per over)
--   - sequence: 0-based (0 = first event, 1+ = additional events like wides/no-balls)
-- Updated schema to support multiple entries per delivery (e.g., wide, no-ball)
-- sequence column allows tracking multiple events for same over_number.ball_number
CREATE TABLE IF NOT EXISTS ball_by_ball (
    id INT AUTO_INCREMENT PRIMARY KEY,
    match_id INT NOT NULL,
    inning_id INT NOT NULL,
    over_number INT NOT NULL,
    ball_number INT NOT NULL,
    sequence INT DEFAULT 0 COMMENT 'Sequence for multiple events on same delivery (0=legal, 1+=extras)',
    batsman_id INT NOT NULL,
    bowler_id INT NOT NULL,
    runs INT DEFAULT 0,
    extras VARCHAR(32) NULL COMMENT 'wide, no-ball, bye, leg-bye',
    wicket_type VARCHAR(32) NULL,
    out_player_id INT NULL,
    CONSTRAINT fk_ball_match FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE,
    CONSTRAINT fk_ball_innings FOREIGN KEY (inning_id) REFERENCES match_innings(id) ON DELETE CASCADE,
    CONSTRAINT fk_ball_batsman FOREIGN KEY (batsman_id) REFERENCES players(id) ON DELETE RESTRICT,
    CONSTRAINT fk_ball_bowler FOREIGN KEY (bowler_id) REFERENCES players(id) ON DELETE RESTRICT,
    CONSTRAINT fk_ball_out_player FOREIGN KEY (out_player_id) REFERENCES players(id) ON DELETE SET NULL,
    CONSTRAINT uq_ball_pos UNIQUE (inning_id, over_number, ball_number, sequence)
) ENGINE=InnoDB;
-- 10. Team Tournament Summary table
CREATE TABLE IF NOT EXISTS team_tournament_summary (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_id INT NOT NULL,
    team_id INT NOT NULL,
    matches_played INT DEFAULT 0,
    matches_won INT DEFAULT 0,
    CONSTRAINT fk_tts_tournament FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE,
    CONSTRAINT fk_tts_team FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE,
    CONSTRAINT uq_team_tournament_summary UNIQUE (tournament_id, team_id)
) ENGINE=InnoDB;

-- 11. Auth failures table (for rate limiting)
CREATE TABLE IF NOT EXISTS auth_failures (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    failed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(64) NULL,
    user_agent VARCHAR(255) NULL,
    resolved_at TIMESTAMP NULL,
    KEY idx_auth_failures_phone (phone_number),
    KEY idx_auth_failures_time (failed_at),
    KEY idx_auth_failures_phone_time (phone_number, failed_at),
    KEY idx_auth_failures_phone_ip_time (phone_number, ip_address, failed_at)
) ENGINE=InnoDB;

-- Removed dangerous DROP TABLE statements


-- Indexes to match migrations
ALTER TABLE users ADD UNIQUE KEY uq_users_phone (phone_number);
ALTER TABLE matches ADD INDEX idx_matches_tournament (tournament_id), ADD INDEX idx_matches_status (status);
ALTER TABLE refresh_tokens ADD INDEX idx_refresh_tokens_user (user_id);
ALTER TABLE refresh_tokens ADD INDEX idx_refresh_tokens_token (token);
ALTER TABLE password_resets ADD INDEX idx_password_resets_user (user_id), ADD INDEX idx_password_resets_active (user_id, used_at, expires_at);
ALTER TABLE teams ADD INDEX idx_teams_owner (owner_id);
ALTER TABLE players ADD INDEX idx_players_team (team_id);
ALTER TABLE tournament_teams ADD INDEX idx_tournament_teams_tournament (tournament_id);
ALTER TABLE ball_by_ball ADD INDEX idx_ball_by_ball_inning (inning_id);
ALTER TABLE ball_by_ball ADD INDEX idx_ball_by_ball_position (inning_id, over_number, ball_number, sequence);
ALTER TABLE ball_by_ball ADD INDEX idx_ball_by_ball_bowler (bowler_id);