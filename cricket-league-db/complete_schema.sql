<<<<<<< Local
-- Complete Cricket League Database Schema
-- This file contains the complete database schema including all features from migrations
-- Use this to create a fresh database without running migrations

-- Create database (uncomment if needed)
-- CREATE DATABASE IF NOT EXISTS cricket_league CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- USE cricket_league;

-- 1. Users table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_admin BOOLEAN DEFAULT FALSE
) ENGINE=InnoDB;

-- 2. Teams table
CREATE TABLE teams (
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
    CONSTRAINT fk_team_owner FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT teams_captain_vice_distinct CHECK (captain_player_id IS NULL OR vice_captain_player_id IS NULL OR captain_player_id <> vice_captain_player_id),
    CONSTRAINT uq_teams_captain_player_id UNIQUE (captain_player_id)
) ENGINE=InnoDB;

-- 3. Players table
CREATE TABLE players (
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

-- Note: Foreign key constraints for captain_player_id and vice_captain_player_id are not added
-- to avoid circular dependency with players table. These fields are managed by application logic.

-- 4. Tournaments table
CREATE TABLE tournaments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_name VARCHAR(100) NOT NULL,
    location VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    status ENUM('upcoming','not_started','live','completed','abandoned') NOT NULL DEFAULT 'not_started',
    created_by INT NOT NULL,
    overs INT DEFAULT 20 COMMENT 'Number of overs per innings',
    end_date DATE NULL COMMENT 'Expected tournament end date',
    CONSTRAINT fk_tournament_creator FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 5. Tournament Teams table
CREATE TABLE tournament_teams (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_id INT NOT NULL,
    team_id INT NULL,
    temp_team_name VARCHAR(100) NULL,
    temp_team_location VARCHAR(100) NULL,
    registration_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tournament_team_tournament FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE,
    CONSTRAINT fk_tournament_team_team FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE SET NULL,
    CONSTRAINT uq_tt_registered UNIQUE (tournament_id, team_id),
    CONSTRAINT uq_tt_temp UNIQUE (tournament_id, temp_team_name, temp_team_location)
) ENGINE=InnoDB;

-- 6. Matches table
CREATE TABLE matches (
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

-- 7. Tournament Matches table
CREATE TABLE tournament_matches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_id INT NOT NULL,
    team1_id INT NULL,
    team2_id INT NULL,
    team1_tt_id INT NULL,
    team2_tt_id INT NULL,
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
    CONSTRAINT fk_tournament_match_parent FOREIGN KEY (parent_match_id) REFERENCES tournament_matches(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 8. Match Innings table
CREATE TABLE match_innings (
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
    CONSTRAINT fk_innings_match FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE,
    CONSTRAINT fk_innings_team FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE,
    CONSTRAINT fk_innings_batting FOREIGN KEY (batting_team_id) REFERENCES teams(id) ON DELETE SET NULL,
    CONSTRAINT fk_innings_bowling FOREIGN KEY (bowling_team_id) REFERENCES teams(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 9. Player Match Stats table
CREATE TABLE player_match_stats (
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
    CONSTRAINT fk_stats_match FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 10. Ball by Ball table
CREATE TABLE ball_by_ball (
    id INT AUTO_INCREMENT PRIMARY KEY,
    match_id INT NOT NULL,
    inning_id INT NOT NULL,
    over_number INT NOT NULL,
    ball_number INT NOT NULL,
    batsman_id INT NOT NULL,
    bowler_id INT NOT NULL,
    runs INT DEFAULT 0,
    extras VARCHAR(32) NULL,
    wicket_type VARCHAR(32) NULL,
    out_player_id INT NULL,
    CONSTRAINT fk_ball_match FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE,
    CONSTRAINT fk_ball_innings FOREIGN KEY (inning_id) REFERENCES match_innings(id) ON DELETE CASCADE,
    CONSTRAINT fk_ball_batsman FOREIGN KEY (batsman_id) REFERENCES players(id) ON DELETE RESTRICT,
    CONSTRAINT fk_ball_bowler FOREIGN KEY (bowler_id) REFERENCES players(id) ON DELETE RESTRICT,
    CONSTRAINT fk_ball_out_player FOREIGN KEY (out_player_id) REFERENCES players(id) ON DELETE SET NULL,
    CONSTRAINT uq_ball_pos UNIQUE (inning_id, over_number, ball_number)
) ENGINE=InnoDB;

-- 11. Auth Failures table
CREATE TABLE auth_failures (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    failed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(64) NULL,
    user_agent VARCHAR(255) NULL,
    resolved_at TIMESTAMP NULL
) ENGINE=InnoDB;

-- 12. Refresh Tokens table
CREATE TABLE refresh_tokens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    token VARCHAR(512) NOT NULL,
    is_revoked TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT fk_refresh_tokens_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uq_refresh_token (token),
    KEY idx_refresh_user (user_id)
) ENGINE=InnoDB;

-- 13. Password Resets table
CREATE TABLE password_resets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    token_hash VARCHAR(255) NOT NULL,
    expires_at DATETIME NOT NULL,
    used_at DATETIME NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_password_resets_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 14. Feedback table
CREATE TABLE feedback (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    message TEXT NOT NULL,
    contact VARCHAR(255) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_feedback_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Indexes for performance optimization

-- Users indexes
CREATE INDEX idx_users_phone ON users(phone_number);

-- Teams indexes
CREATE INDEX idx_teams_name ON teams(team_name);
CREATE INDEX idx_teams_location ON teams(team_location);
CREATE INDEX idx_teams_name_location ON teams(team_name, team_location);

-- Players indexes (moved to ALTER TABLE statements below)

-- Tournaments indexes
CREATE INDEX idx_tournaments_created_by ON tournaments(created_by);
CREATE INDEX idx_tournaments_name ON tournaments(tournament_name);
CREATE INDEX idx_tournaments_status ON tournaments(status);
CREATE INDEX idx_tournaments_end_date ON tournaments(end_date);
CREATE INDEX idx_tournaments_overs ON tournaments(overs);

-- Tournament Teams indexes
CREATE INDEX idx_tournament_teams_team_id ON tournament_teams(team_id);

-- Matches indexes
CREATE INDEX idx_matches_team1_id ON matches(team1_id);
CREATE INDEX idx_matches_team2_id ON matches(team2_id);

-- Tournament Matches indexes
CREATE INDEX idx_tournament_matches_tournament ON tournament_matches(tournament_id);
CREATE INDEX idx_tournament_matches_team1_id ON tournament_matches(team1_id);
CREATE INDEX idx_tournament_matches_team2_id ON tournament_matches(team2_id);
CREATE INDEX idx_tournament_matches_team1_tt_id ON tournament_matches(team1_tt_id);
CREATE INDEX idx_tournament_matches_team2_tt_id ON tournament_matches(team2_tt_id);
CREATE INDEX idx_tournament_matches_parent_match_id ON tournament_matches(parent_match_id);

-- Match Innings indexes
CREATE INDEX idx_match_innings_match ON match_innings(match_id);
CREATE INDEX idx_match_innings_batting ON match_innings(batting_team_id);
CREATE INDEX idx_match_innings_bowling ON match_innings(bowling_team_id);

-- Player Match Stats indexes
CREATE INDEX idx_player_match_stats_player ON player_match_stats(player_id);
CREATE INDEX idx_player_match_stats_match ON player_match_stats(match_id);

-- Ball by Ball indexes (moved to ALTER TABLE statements below)

-- Auth Failures indexes
CREATE INDEX idx_auth_failures_phone ON auth_failures(phone_number);
CREATE INDEX idx_auth_failures_time ON auth_failures(failed_at);
CREATE INDEX idx_auth_failures_phone_time ON auth_failures(phone_number, failed_at);
CREATE INDEX idx_auth_failures_phone_ip_time ON auth_failures(phone_number, ip_address, failed_at);

-- Refresh Tokens indexes
CREATE INDEX idx_refresh_tokens_user_revoked ON refresh_tokens(user_id, is_revoked);

-- Password Resets indexes
CREATE INDEX idx_password_resets_user ON password_resets(user_id);
CREATE INDEX idx_password_resets_active ON password_resets(user_id, used_at, expires_at);

-- Feedback indexes
CREATE INDEX idx_feedback_user ON feedback(user_id);

-- Additional indexes to match schema.sql
ALTER TABLE users ADD UNIQUE KEY uq_users_phone (phone_number);
ALTER TABLE matches ADD INDEX idx_matches_tournament (tournament_id), ADD INDEX idx_matches_status (status);
ALTER TABLE refresh_tokens ADD INDEX idx_refresh_tokens_token (token);
ALTER TABLE teams ADD INDEX idx_teams_owner (owner_id);
ALTER TABLE players ADD INDEX idx_players_team (team_id);
ALTER TABLE tournament_teams ADD INDEX idx_tournament_teams_tournament (tournament_id);
ALTER TABLE ball_by_ball ADD INDEX idx_ball_by_ball_inning (inning_id);
ALTER TABLE ball_by_ball ADD INDEX idx_ball_by_ball_position (inning_id, over_number, ball_number);
ALTER TABLE ball_by_ball ADD INDEX idx_ball_by_ball_bowler (bowler_id);

-- Insert test data
INSERT INTO users (phone_number, password_hash) VALUES 
('12345678', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMeshCSR5P4BYq7s8J4xrV8KDe');

-- Get test user ID
SET @test_user_id = (SELECT id FROM users WHERE phone_number = '12345678');

-- Insert test team
INSERT INTO teams (team_name, team_location, owner_id, matches_played, matches_won, trophies) VALUES 
('Test Warriors', 'Test City', @test_user_id, 0, 0, 0);

-- Get test team ID
SET @test_team_id = (SELECT id FROM teams WHERE owner_id = @test_user_id LIMIT 1);

-- Insert test players
INSERT INTO players (team_id, player_name, player_role, runs, matches_played, hundreds, fifties, batting_average, strike_rate, wickets) VALUES 
(@test_team_id, 'Test Batsman 1', 'Batsman', 0, 0, 0, 0, 0.00, 0.00, 0),
(@test_team_id, 'Test Batsman 2', 'Batsman', 0, 0, 0, 0, 0.00, 0.00, 0),
(@test_team_id, 'Test Bowler 1', 'Bowler', 0, 0, 0, 0, 0.00, 0.00, 0),
(@test_team_id, 'Test All-rounder', 'All-rounder', 0, 0, 0, 0, 0.00, 0.00, 0),
(@test_team_id, 'Test Wicket-keeper', 'Wicket-keeper', 0, 0, 0, 0, 0.00, 0.00, 0);
=======
-- Complete Cricket League Database Schema
-- This file contains the complete database schema including all features from migrations
-- Use this to create a fresh database without running migrations

-- Create database (uncomment if needed)
-- CREATE DATABASE IF NOT EXISTS cricket_league CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- USE cricket_league;

-- 1. Users table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_admin BOOLEAN DEFAULT FALSE
) ENGINE=InnoDB;

-- 2. Teams table
CREATE TABLE teams (
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
    CONSTRAINT fk_team_owner FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT teams_captain_vice_distinct CHECK (captain_player_id IS NULL OR vice_captain_player_id IS NULL OR captain_player_id <> vice_captain_player_id),
    CONSTRAINT uq_teams_captain_player_id UNIQUE (captain_player_id)
) ENGINE=InnoDB;

-- 3. Players table
CREATE TABLE players (
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

-- Note: Foreign key constraints for captain_player_id and vice_captain_player_id are not added
-- to avoid circular dependency with players table. These fields are managed by application logic.

-- 4. Tournaments table
CREATE TABLE tournaments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_name VARCHAR(100) NOT NULL,
    location VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    status ENUM('upcoming','not_started','live','completed','abandoned') NOT NULL DEFAULT 'not_started',
    created_by INT NOT NULL,
    overs INT DEFAULT 20 COMMENT 'Number of overs per innings',
    end_date DATE NULL COMMENT 'Expected tournament end date',
    CONSTRAINT fk_tournament_creator FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 5. Tournament Teams table
CREATE TABLE tournament_teams (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_id INT NOT NULL,
    team_id INT NULL,
    temp_team_name VARCHAR(100) NULL,
    temp_team_location VARCHAR(100) NULL,
    registration_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tournament_team_tournament FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE,
    CONSTRAINT fk_tournament_team_team FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE SET NULL,
    CONSTRAINT uq_tt_registered UNIQUE (tournament_id, team_id),
    CONSTRAINT uq_tt_temp UNIQUE (tournament_id, temp_team_name, temp_team_location)
) ENGINE=InnoDB;

-- 6. Matches table
CREATE TABLE matches (
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

-- 7. Tournament Matches table
CREATE TABLE tournament_matches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_id INT NOT NULL,
    team1_id INT NULL,
    team2_id INT NULL,
    team1_tt_id INT NULL,
    team2_tt_id INT NULL,
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
    CONSTRAINT fk_tournament_match_parent FOREIGN KEY (parent_match_id) REFERENCES tournament_matches(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 8. Match Innings table
CREATE TABLE match_innings (
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

-- 9. Player Match Stats table
CREATE TABLE player_match_stats (
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
    CONSTRAINT fk_stats_match FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 10. Ball by Ball table
CREATE TABLE ball_by_ball (
    id INT AUTO_INCREMENT PRIMARY KEY,
    match_id INT NOT NULL,
    inning_id INT NOT NULL,
    over_number INT NOT NULL,
    ball_number INT NOT NULL,
    batsman_id INT NOT NULL,
    bowler_id INT NOT NULL,
    runs INT DEFAULT 0,
    extras VARCHAR(32) NULL,
    wicket_type VARCHAR(32) NULL,
    out_player_id INT NULL,
    CONSTRAINT fk_ball_match FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE,
    CONSTRAINT fk_ball_innings FOREIGN KEY (inning_id) REFERENCES match_innings(id) ON DELETE CASCADE,
    CONSTRAINT fk_ball_batsman FOREIGN KEY (batsman_id) REFERENCES players(id) ON DELETE RESTRICT,
    CONSTRAINT fk_ball_bowler FOREIGN KEY (bowler_id) REFERENCES players(id) ON DELETE RESTRICT,
    CONSTRAINT fk_ball_out_player FOREIGN KEY (out_player_id) REFERENCES players(id) ON DELETE SET NULL,
    CONSTRAINT uq_ball_pos UNIQUE (inning_id, over_number, ball_number)
) ENGINE=InnoDB;

-- 11. Auth Failures table
CREATE TABLE auth_failures (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    failed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(64) NULL,
    user_agent VARCHAR(255) NULL,
    resolved_at TIMESTAMP NULL
) ENGINE=InnoDB;

-- 12. Refresh Tokens table
CREATE TABLE refresh_tokens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    token VARCHAR(512) NOT NULL,
    is_revoked TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT fk_refresh_tokens_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uq_refresh_token (token),
    KEY idx_refresh_user (user_id)
) ENGINE=InnoDB;

-- 13. Password Resets table
CREATE TABLE password_resets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    token_hash VARCHAR(255) NOT NULL,
    expires_at DATETIME NOT NULL,
    used_at DATETIME NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_password_resets_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 14. Feedback table
CREATE TABLE feedback (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    message TEXT NOT NULL,
    contact VARCHAR(255) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_feedback_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Indexes for performance optimization

-- Users indexes
CREATE INDEX idx_users_phone ON users(phone_number);

-- Teams indexes
CREATE INDEX idx_teams_name ON teams(team_name);
CREATE INDEX idx_teams_location ON teams(team_location);
CREATE INDEX idx_teams_name_location ON teams(team_name, team_location);

-- Players indexes (moved to ALTER TABLE statements below)

-- Tournaments indexes
CREATE INDEX idx_tournaments_created_by ON tournaments(created_by);
CREATE INDEX idx_tournaments_name ON tournaments(tournament_name);
CREATE INDEX idx_tournaments_status ON tournaments(status);
CREATE INDEX idx_tournaments_end_date ON tournaments(end_date);
CREATE INDEX idx_tournaments_overs ON tournaments(overs);

-- Tournament Teams indexes
CREATE INDEX idx_tournament_teams_team_id ON tournament_teams(team_id);

-- Matches indexes
CREATE INDEX idx_matches_team1_id ON matches(team1_id);
CREATE INDEX idx_matches_team2_id ON matches(team2_id);

-- Tournament Matches indexes
CREATE INDEX idx_tournament_matches_tournament ON tournament_matches(tournament_id);
CREATE INDEX idx_tournament_matches_team1_id ON tournament_matches(team1_id);
CREATE INDEX idx_tournament_matches_team2_id ON tournament_matches(team2_id);
CREATE INDEX idx_tournament_matches_team1_tt_id ON tournament_matches(team1_tt_id);
CREATE INDEX idx_tournament_matches_team2_tt_id ON tournament_matches(team2_tt_id);
CREATE INDEX idx_tournament_matches_parent_match_id ON tournament_matches(parent_match_id);

-- Match Innings indexes
CREATE INDEX idx_match_innings_match ON match_innings(match_id);
CREATE INDEX idx_match_innings_batting ON match_innings(batting_team_id);
CREATE INDEX idx_match_innings_bowling ON match_innings(bowling_team_id);

-- Player Match Stats indexes
CREATE INDEX idx_player_match_stats_player ON player_match_stats(player_id);
CREATE INDEX idx_player_match_stats_match ON player_match_stats(match_id);

-- Ball by Ball indexes (moved to ALTER TABLE statements below)

-- Auth Failures indexes
CREATE INDEX idx_auth_failures_phone ON auth_failures(phone_number);
CREATE INDEX idx_auth_failures_time ON auth_failures(failed_at);
CREATE INDEX idx_auth_failures_phone_time ON auth_failures(phone_number, failed_at);
CREATE INDEX idx_auth_failures_phone_ip_time ON auth_failures(phone_number, ip_address, failed_at);

-- Refresh Tokens indexes
CREATE INDEX idx_refresh_tokens_user_revoked ON refresh_tokens(user_id, is_revoked);

-- Password Resets indexes
CREATE INDEX idx_password_resets_user ON password_resets(user_id);
CREATE INDEX idx_password_resets_active ON password_resets(user_id, used_at, expires_at);

-- Feedback indexes
CREATE INDEX idx_feedback_user ON feedback(user_id);

-- Additional indexes to match schema.sql
ALTER TABLE users ADD UNIQUE KEY uq_users_phone (phone_number);
ALTER TABLE matches ADD INDEX idx_matches_tournament (tournament_id), ADD INDEX idx_matches_status (status);
ALTER TABLE refresh_tokens ADD INDEX idx_refresh_tokens_token (token);
ALTER TABLE teams ADD INDEX idx_teams_owner (owner_id);
ALTER TABLE players ADD INDEX idx_players_team (team_id);
ALTER TABLE tournament_teams ADD INDEX idx_tournament_teams_tournament (tournament_id);
ALTER TABLE ball_by_ball ADD INDEX idx_ball_by_ball_inning (inning_id);
ALTER TABLE ball_by_ball ADD INDEX idx_ball_by_ball_position (inning_id, over_number, ball_number);
ALTER TABLE ball_by_ball ADD INDEX idx_ball_by_ball_bowler (bowler_id);

-- Insert test data
INSERT INTO users (phone_number, password_hash) VALUES 
('12345678', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMeshCSR5P4BYq7s8J4xrV8KDe');

-- Get test user ID
SET @test_user_id = (SELECT id FROM users WHERE phone_number = '12345678');

-- Insert test team
INSERT INTO teams (team_name, team_location, owner_id, matches_played, matches_won, trophies) VALUES 
('Test Warriors', 'Test City', @test_user_id, 0, 0, 0);

-- Get test team ID
SET @test_team_id = (SELECT id FROM teams WHERE owner_id = @test_user_id LIMIT 1);

-- Insert test players
INSERT INTO players (team_id, player_name, player_role, runs, matches_played, hundreds, fifties, batting_average, strike_rate, wickets) VALUES 
(@test_team_id, 'Test Batsman 1', 'Batsman', 0, 0, 0, 0, 0.00, 0.00, 0),
(@test_team_id, 'Test Batsman 2', 'Batsman', 0, 0, 0, 0, 0.00, 0.00, 0),
(@test_team_id, 'Test Bowler 1', 'Bowler', 0, 0, 0, 0, 0.00, 0.00, 0),
(@test_team_id, 'Test All-rounder', 'All-rounder', 0, 0, 0, 0, 0.00, 0.00, 0),
(@test_team_id, 'Test Wicket-keeper', 'Wicket-keeper', 0, 0, 0, 0, 0.00, 0.00, 0);
>>>>>>> Remote
