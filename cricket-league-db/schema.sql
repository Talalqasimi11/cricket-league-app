-- Drop existing tables if any (to avoid conflicts during re-creation)
DROP TABLE IF EXISTS ball_by_ball;
DROP TABLE IF EXISTS player_match_stats;
DROP TABLE IF EXISTS match_innings;
DROP TABLE IF EXISTS matches;
DROP TABLE IF EXISTS tournament_teams;
DROP TABLE IF EXISTS tournaments;
DROP TABLE IF EXISTS players;
DROP TABLE IF EXISTS team_tournament_summary;
DROP TABLE IF EXISTS teams;
DROP TABLE IF EXISTS users;

-- 1. Users (Captains)
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    team_id INT UNIQUE
) ENGINE=InnoDB;

-- 2. Teams
CREATE TABLE teams (
    id INT AUTO_INCREMENT PRIMARY KEY,
    captain_id INT NOT NULL UNIQUE,
    team_name VARCHAR(100) NOT NULL,
    team_location VARCHAR(100) NOT NULL,
    matches_played INT DEFAULT 0,
    matches_won INT DEFAULT 0,
    trophies INT DEFAULT 0,
    CONSTRAINT fk_captain FOREIGN KEY (captain_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Link user.team_id → teams.id
ALTER TABLE users
    ADD CONSTRAINT fk_user_team FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE SET NULL;

-- 3. Players
CREATE TABLE players (
    id INT AUTO_INCREMENT PRIMARY KEY,
    team_id INT NOT NULL,
    player_name VARCHAR(100) NOT NULL,
    player_role ENUM('Batsman','Bowler','All-Rounder','Wicket-Keeper') NOT NULL,
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
CREATE TABLE tournaments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_name VARCHAR(100) NOT NULL,
    location VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    status ENUM('ongoing','completed','cancelled') NOT NULL DEFAULT 'ongoing',
    created_by INT NOT NULL,
    CONSTRAINT fk_tournament_creator FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 5. Tournament Teams (registered + temporary teams)
CREATE TABLE tournament_teams (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_id INT NOT NULL,
    team_id INT NULL,
    temp_team_name VARCHAR(100),
    temp_team_location VARCHAR(100),
    CONSTRAINT fk_tournament FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE,
    CONSTRAINT fk_registered_team FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 6. Matches
CREATE TABLE matches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_id INT NOT NULL,
    team1_id INT NULL,
    team2_id INT NULL,
    tournament_team1_id INT NULL,
    tournament_team2_id INT NULL,
    overs INT NOT NULL,
    match_datetime DATETIME NOT NULL,
    status ENUM('not_started','live','completed','abandoned') DEFAULT 'not_started',
    winner_team_id INT NULL,
    winner_tournament_team_id INT NULL,
    CONSTRAINT fk_match_tournament FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE,
    CONSTRAINT fk_match_team1 FOREIGN KEY (team1_id) REFERENCES teams(id) ON DELETE SET NULL,
    CONSTRAINT fk_match_team2 FOREIGN KEY (team2_id) REFERENCES teams(id) ON DELETE SET NULL,
    CONSTRAINT fk_match_tournament_team1 FOREIGN KEY (tournament_team1_id) REFERENCES tournament_teams(id) ON DELETE SET NULL,
    CONSTRAINT fk_match_tournament_team2 FOREIGN KEY (tournament_team2_id) REFERENCES tournament_teams(id) ON DELETE SET NULL,
    CONSTRAINT fk_match_winner_team FOREIGN KEY (winner_team_id) REFERENCES teams(id) ON DELETE SET NULL,
    CONSTRAINT fk_match_winner_tournament_team FOREIGN KEY (winner_tournament_team_id) REFERENCES tournament_teams(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 7. Match Innings
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
    CONSTRAINT fk_player_match FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE,
    CONSTRAINT fk_match_player FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 9. Ball-by-Ball
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
