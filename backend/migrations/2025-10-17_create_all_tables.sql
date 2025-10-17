-- Create all missing tables from the main schema
-- This migration ensures all required tables exist

-- 1. Users table (should already exist)
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL
) ENGINE=InnoDB;

-- 2. Teams table
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
    CONSTRAINT fk_team_owner FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_team_captain FOREIGN KEY (captain_player_id) REFERENCES players(id) ON DELETE SET NULL,
    CONSTRAINT fk_team_vice_captain FOREIGN KEY (vice_captain_player_id) REFERENCES players(id) ON DELETE SET NULL,
    CONSTRAINT teams_captain_vice_distinct CHECK (captain_player_id IS NULL OR vice_captain_player_id IS NULL OR captain_player_id <> vice_captain_player_id),
    CONSTRAINT uq_teams_captain_player_id UNIQUE (captain_player_id)
) ENGINE=InnoDB;

-- 3. Players table
CREATE TABLE IF NOT EXISTS players (
    id INT AUTO_INCREMENT PRIMARY KEY,
    team_id INT NOT NULL,
    player_name VARCHAR(100) NOT NULL,
    player_role ENUM('Batsman','Bowler','All-rounder','Wicket-keeper') NOT NULL,
    runs INT DEFAULT 0,
    matches_played INT DEFAULT 0,
    hundreds INT DEFAULT 0,
    fifties INT DEFAULT 0,
    batting_average DECIMAL(5,2) DEFAULT 0.00,
    strike_rate DECIMAL(5,2) DEFAULT 0.00,
    wickets INT DEFAULT 0,
    CONSTRAINT fk_player_team FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 4. Tournaments table
CREATE TABLE IF NOT EXISTS tournaments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_name VARCHAR(100) NOT NULL,
    location VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    status ENUM('upcoming','not_started','live','completed','abandoned') NOT NULL DEFAULT 'not_started',
    created_by INT NOT NULL,
    CONSTRAINT fk_tournament_creator FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 5. Tournament Teams table
CREATE TABLE IF NOT EXISTS tournament_teams (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_id INT NOT NULL,
    team_id INT NOT NULL,
    CONSTRAINT fk_tournament_team_tournament FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE,
    CONSTRAINT fk_tournament_team_team FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE,
    UNIQUE KEY unique_tournament_team (tournament_id, team_id)
) ENGINE=InnoDB;

-- 6. Matches table
CREATE TABLE IF NOT EXISTS matches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_id INT NULL,
    team1_id INT NOT NULL,
    team2_id INT NOT NULL,
    match_date DATETIME NOT NULL,
    venue VARCHAR(100) NOT NULL,
    status ENUM('not_started','live','completed','abandoned') DEFAULT 'not_started',
    overs INT NOT NULL DEFAULT 20,
    winner_team_id INT NULL,
    CONSTRAINT fk_match_tournament FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE SET NULL,
    CONSTRAINT fk_match_team1 FOREIGN KEY (team1_id) REFERENCES teams(id) ON DELETE CASCADE,
    CONSTRAINT fk_match_team2 FOREIGN KEY (team2_id) REFERENCES teams(id) ON DELETE CASCADE,
    CONSTRAINT fk_match_winner FOREIGN KEY (winner_team_id) REFERENCES teams(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 7. Match Innings table
CREATE TABLE IF NOT EXISTS match_innings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    match_id INT NOT NULL,
    team_id INT NOT NULL,
    inning_number INT NOT NULL DEFAULT 1,
    overs INT NOT NULL DEFAULT 0,
    status ENUM('in_progress','completed') NOT NULL DEFAULT 'in_progress',
    CONSTRAINT fk_innings_match FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE,
    CONSTRAINT fk_innings_team FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 8. Player Match Stats table
CREATE TABLE IF NOT EXISTS player_match_stats (
    id INT AUTO_INCREMENT PRIMARY KEY,
    player_id INT NOT NULL,
    match_id INT NOT NULL,
    runs INT DEFAULT 0,
    balls_faced INT DEFAULT 0,
    balls_bowled INT DEFAULT 0,
    runs_conceded INT DEFAULT 0,
    wickets INT DEFAULT 0,
    CONSTRAINT fk_stats_player FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE,
    CONSTRAINT fk_stats_match FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 9. Ball by Ball table
CREATE TABLE IF NOT EXISTS ball_by_ball (
    id INT AUTO_INCREMENT PRIMARY KEY,
    match_id INT NOT NULL,
    inning_id INT NULL,
    over_number INT NULL,
    ball_number INT NULL,
    batsman_id INT NULL,
    runs INT DEFAULT 0,
    extras VARCHAR(32) NULL,
    wicket_type VARCHAR(32) NULL,
    out_player_id INT NULL,
    CONSTRAINT fk_ball_match FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE,
    CONSTRAINT fk_ball_innings FOREIGN KEY (inning_id) REFERENCES match_innings(id) ON DELETE CASCADE,
    CONSTRAINT fk_ball_batsman FOREIGN KEY (batsman_id) REFERENCES players(id) ON DELETE SET NULL,
    CONSTRAINT fk_ball_out_player FOREIGN KEY (out_player_id) REFERENCES players(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 10. Auth failures table (for rate limiting)
CREATE TABLE IF NOT EXISTS auth_failures (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    failed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_auth_failures_phone (phone_number),
    KEY idx_auth_failures_time (failed_at)
) ENGINE=InnoDB;
