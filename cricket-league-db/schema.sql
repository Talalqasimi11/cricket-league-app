
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
    -- Foreign key to the captain player (must be from this team)
    CONSTRAINT fk_team_captain FOREIGN KEY (captain_player_id) REFERENCES players(id) ON DELETE SET NULL,
    -- Foreign key to the vice-captain player (must be from this team)
    CONSTRAINT fk_team_vice_captain FOREIGN KEY (vice_captain_player_id) REFERENCES players(id) ON DELETE SET NULL,
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
    player_role VARCHAR(32) NOT NULL,
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

-- 4. Tournaments
-- Tournaments are created by a user.
-- Note: 'upcoming' and 'not_started' are treated as synonyms; 'upcoming' added via migrations
CREATE TABLE IF NOT EXISTS tournaments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_name VARCHAR(100) NOT NULL,
    location VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    status ENUM('upcoming','not_started','live','completed','abandoned') NOT NULL DEFAULT 'not_started',
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
    tournament_id INT NOT NULL,
    team1_id INT NULL,
    team2_id INT NULL,
    overs INT NOT NULL,
    match_datetime DATETIME NOT NULL,
    status ENUM('not_started','live','completed','abandoned') DEFAULT 'not_started',
    winner_team_id INT NULL,
    CONSTRAINT fk_match_tournament FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE,
    CONSTRAINT fk_match_team1 FOREIGN KEY (team1_id) REFERENCES teams(id) ON DELETE SET NULL,
    CONSTRAINT fk_match_team2 FOREIGN KEY (team2_id) REFERENCES teams(id) ON DELETE SET NULL,
    CONSTRAINT fk_match_winner_team FOREIGN KEY (winner_team_id) REFERENCES teams(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 7. Match Innings
-- Stores the summary for each innings of a match.
CREATE TABLE IF NOT EXISTS match_innings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    match_id INT NOT NULL,
    batting_team_id INT NULL,
    bowling_team_id INT NULL,
    runs INT DEFAULT 0,
    wickets INT DEFAULT 0,
    overs_faced DECIMAL(4,1) DEFAULT 0.0,
    CONSTRAINT fk_innings_match FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE,
    CONSTRAINT fk_innings_batting FOREIGN KEY (batting_team_id) REFERENCES teams(id) ON DELETE SET NULL,
    CONSTRAINT fk_innings_bowling FOREIGN KEY (bowling_team_id) REFERENCES teams(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 8. Player Match Stats
-- Records the performance of each player in a specific match.
CREATE TABLE IF NOT EXISTS player_match_stats (
    id INT AUTO_INCREMENT PRIMARY KEY,
    match_id INT NOT NULL,
    player_id INT NOT NULL,
    runs_scored INT DEFAULT 0,
    balls_faced INT DEFAULT 0,
    fours INT DEFAULT 0,
    sixes INT DEFAULT 0,
    wickets_taken INT DEFAULT 0,
    overs_bowled DECIMAL(4,1) DEFAULT 0.0,
    runs_conceded INT DEFAULT 0,
    catches INT DEFAULT 0,
    stumpings INT DEFAULT 0,
    CONSTRAINT fk_stats_match FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE,
    CONSTRAINT fk_stats_player FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 9. Ball-by-Ball
-- Stores the detailed record of every ball bowled in a match.
CREATE TABLE IF NOT EXISTS ball_by_ball (
    id INT AUTO_INCREMENT PRIMARY KEY,
    match_id INT NOT NULL,
    over_number INT NOT NULL,
    ball_number INT NOT NULL,
    striker_id INT NOT NULL,
    bowler_id INT NOT NULL,
    runs_scored INT DEFAULT 0,
    extras ENUM('none','wide','no-ball','bye','leg-bye') DEFAULT 'none',
    wicket BOOLEAN DEFAULT FALSE,
    dismissal_type ENUM('bowled','caught','lbw','run_out','stumped','hit_wicket','none') DEFAULT 'none',
    fielder_id INT NULL,
    CONSTRAINT fk_ball_match FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE,
    CONSTRAINT fk_ball_striker FOREIGN KEY (striker_id) REFERENCES players(id) ON DELETE CASCADE,
    CONSTRAINT fk_ball_bowler FOREIGN KEY (bowler_id) REFERENCES players(id) ON DELETE CASCADE,
    CONSTRAINT fk_ball_fielder FOREIGN KEY (fielder_id) REFERENCES players(id) ON DELETE SET NULL
) ENGINE=InnoDB;
-- Removed dangerous DROP TABLE statements


-- Indexes to match migrations
ALTER TABLE users ADD UNIQUE KEY uq_users_phone (phone_number);
ALTER TABLE matches ADD INDEX idx_matches_tournament (tournament_id), ADD INDEX idx_matches_status (status);
ALTER TABLE refresh_tokens ADD INDEX idx_refresh_tokens_user (user_id);
ALTER TABLE password_resets ADD INDEX idx_password_resets_user (user_id), ADD INDEX idx_password_resets_active (user_id, used_at, expires_at);
ALTER TABLE teams ADD INDEX idx_teams_owner (owner_id);
ALTER TABLE players ADD INDEX idx_players_team (team_id);
ALTER TABLE tournament_teams ADD INDEX idx_tournament_teams_tournament (tournament_id);
-- Note: Unique key for ball_by_ball will be handled by migrations
-- as the exact column names may vary between schema and actual usage