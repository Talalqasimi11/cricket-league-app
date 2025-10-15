
-- Create the new database
CREATE DATABASE cricket_league;

-- Switch to the new database context
USE cricket_league;

-- 1. Users (Team Owners/Captains)
-- This table stores login information. The user who creates a team is its owner.
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    captain_name VARCHAR(100) NULL -- Display name for the user/captain
) ENGINE=InnoDB;

-- 2. Teams
-- Each team is owned by one user. The `owner_id` links to the users table.
CREATE TABLE teams (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner_id INT NOT NULL,
    team_name VARCHAR(100) NOT NULL,
    team_location VARCHAR(100) NOT NULL,
    team_logo_url VARCHAR(255) NULL,
    matches_played INT DEFAULT 0,
    matches_won INT DEFAULT 0,
    trophies INT DEFAULT 0,
    -- Foreign key to the user who owns the team
    CONSTRAINT fk_team_owner FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 3. Players
-- Players belong to a team. If a team is deleted, its players are also deleted.
CREATE TABLE players (
    id INT AUTO_INCREMENT PRIMARY KEY,
    team_id INT NOT NULL,
    player_name VARCHAR(100) NOT NULL,
    player_role ENUM('Batsman','Bowler','All-Rounder','Wicket-Keeper') NOT NULL,
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
CREATE TABLE tournaments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_name VARCHAR(100) NOT NULL,
    location VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    status ENUM('ongoing','completed','cancelled') NOT NULL DEFAULT 'ongoing',
    created_by INT NOT NULL,
    CONSTRAINT fk_tournament_creator FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 5. Tournament Teams
-- This table links teams to tournaments. It can include registered teams or temporary teams.
CREATE TABLE tournament_teams (
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
CREATE TABLE matches (
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
CREATE TABLE match_innings (
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
CREATE TABLE player_match_stats (
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
CREATE TABLE ball_by_ball (
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
DROP TABLE IF EXISTS players;
DROP TABLE IF EXISTS team_tournament_summary;
DROP TABLE IF EXISTS teams;
DROP TABLE IF EXISTS users;

-- 1. Users (Captains)
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    captain_name VARCHAR(100) NULL -- Display name for the user/captain
) ENGINE=InnoDB;

-- 2. Teams
-- Each team is owned by one user. The `owner_id` links to the users table.
CREATE TABLE teams (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner_id INT NOT NULL,
    team_name VARCHAR(100) NOT NULL,
    team_location VARCHAR(100) NOT NULL,
    team_logo_url VARCHAR(255) NULL,
    matches_played INT DEFAULT 0,
    matches_won INT DEFAULT 0,
    trophies INT DEFAULT 0,
    -- Foreign key to the user who owns the team
    CONSTRAINT fk_team_owner FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 3. Players
-- Players belong to a team. If a team is deleted, its players are also deleted.
CREATE TABLE players (
    id INT AUTO_INCREMENT PRIMARY KEY,
    team_id INT NOT NULL,
    player_name VARCHAR(100) NOT NULL,
    player_role ENUM('Batsman','Bowler','All-Rounder','Wicket-Keeper') NOT NULL,
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
CREATE TABLE tournaments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_name VARCHAR(100) NOT NULL,
    location VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    status ENUM('ongoing','completed','cancelled') NOT NULL DEFAULT 'ongoing',
    created_by INT NOT NULL,
    CONSTRAINT fk_tournament_creator FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 5. Tournament Teams
-- This table links teams to tournaments. It can include registered teams or temporary teams.
CREATE TABLE tournament_teams (
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
CREATE TABLE matches (
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
CREATE TABLE match_innings (
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
CREATE TABLE player_match_stats (
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
CREATE TABLE ball_by_ball (
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