-- Make sure you are in your DB
CREATE DATABASE IF NOT EXISTS cricket_league;
USE cricket_league;

-- Drop existing tables in reverse dependency order
DROP TABLE IF EXISTS ball_by_ball;
DROP TABLE IF EXISTS player_match_stats;
DROP TABLE IF EXISTS match_innings;
DROP TABLE IF EXISTS matches;
DROP TABLE IF EXISTS team_tournament_summary;
DROP TABLE IF EXISTS tournament_teams;
DROP TABLE IF EXISTS tournaments;
DROP TABLE IF EXISTS players;
DROP TABLE IF EXISTS teams;
DROP TABLE IF EXISTS users;

-- ========================
-- USERS
-- ========================
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  phone_number VARCHAR(20) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(100) NOT NULL,
  role ENUM('captain','admin') NOT NULL DEFAULT 'captain',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========================
-- TEAMS
-- ========================
CREATE TABLE teams (
  id INT AUTO_INCREMENT PRIMARY KEY,
  team_name VARCHAR(150) NOT NULL,
  team_location VARCHAR(150) NOT NULL,
  matches_played INT NOT NULL DEFAULT 0 CHECK (matches_played >= 0),
  matches_won INT NOT NULL DEFAULT 0 CHECK (matches_won >= 0),
  captain_id INT NOT NULL UNIQUE,
  CONSTRAINT fk_teams_captain FOREIGN KEY (captain_id) REFERENCES users(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========================
-- PLAYERS
-- ========================
CREATE TABLE players (
  id INT AUTO_INCREMENT PRIMARY KEY,
  team_id INT NOT NULL,
  player_name VARCHAR(100) NOT NULL,
  player_role VARCHAR(50) NOT NULL,
  runs INT NOT NULL DEFAULT 0,
  matches_played INT NOT NULL DEFAULT 0,
  hundreds INT NOT NULL DEFAULT 0,
  fifties INT NOT NULL DEFAULT 0,
  CONSTRAINT fk_players_team FOREIGN KEY (team_id) REFERENCES teams(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========================
-- TOURNAMENTS
-- ========================
CREATE TABLE tournaments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  tournament_name VARCHAR(150) NOT NULL,
  location VARCHAR(150) NOT NULL,
  start_date DATE NOT NULL,
  status ENUM('ongoing','completed','cancelled') NOT NULL,
  created_by INT NOT NULL,
  CONSTRAINT fk_tournaments_user FOREIGN KEY (created_by) REFERENCES users(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========================
-- TOURNAMENT_TEAMS
-- (can hold both registered and temporary teams)
-- ========================
CREATE TABLE tournament_teams (
  id INT AUTO_INCREMENT PRIMARY KEY,
  tournament_id INT NOT NULL,
  team_id INT NULL,
  temp_team_name VARCHAR(150) NULL,
  temp_team_location VARCHAR(150) NULL,
  CONSTRAINT fk_tt_tournament FOREIGN KEY (tournament_id) REFERENCES tournaments(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_tt_team FOREIGN KEY (team_id) REFERENCES teams(id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========================
-- MATCHES
-- ========================
CREATE TABLE matches (
  id INT AUTO_INCREMENT PRIMARY KEY,
  tournament_id INT NOT NULL,
  team_a_id INT NULL,
  team_b_id INT NULL,
  team_a_tournament_team_id INT NULL,
  team_b_tournament_team_id INT NULL,
  status ENUM('live','completed','abandoned') NOT NULL,
  overs INT NOT NULL,
  match_datetime DATETIME NOT NULL,
  winner_team_id INT NULL,
  winner_tournament_team_id INT NULL,
  CONSTRAINT fk_matches_tournament FOREIGN KEY (tournament_id) REFERENCES tournaments(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_matches_team_a FOREIGN KEY (team_a_id) REFERENCES teams(id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_matches_team_b FOREIGN KEY (team_b_id) REFERENCES teams(id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_matches_ta_tt FOREIGN KEY (team_a_tournament_team_id) REFERENCES tournament_teams(id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_matches_tb_tt FOREIGN KEY (team_b_tournament_team_id) REFERENCES tournament_teams(id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_matches_winner_team FOREIGN KEY (winner_team_id) REFERENCES teams(id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_matches_winner_tt FOREIGN KEY (winner_tournament_team_id) REFERENCES tournament_teams(id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========================
-- MATCH_INNINGS
-- ========================
CREATE TABLE match_innings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  match_id INT NOT NULL,
  batting_team_id INT NULL,
  bowling_team_id INT NULL,
  batting_tournament_team_id INT NULL,
  bowling_tournament_team_id INT NULL,
  total_runs INT NOT NULL DEFAULT 0,
  total_wickets INT NOT NULL DEFAULT 0,
  overs_played FLOAT NOT NULL DEFAULT 0,
  CONSTRAINT fk_innings_match FOREIGN KEY (match_id) REFERENCES matches(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_innings_bat_team FOREIGN KEY (batting_team_id) REFERENCES teams(id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_innings_bowl_team FOREIGN KEY (bowling_team_id) REFERENCES teams(id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_innings_bat_tt FOREIGN KEY (batting_tournament_team_id) REFERENCES tournament_teams(id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_innings_bowl_tt FOREIGN KEY (bowling_tournament_team_id) REFERENCES tournament_teams(id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========================
-- TEAM_TOURNAMENT_SUMMARY
-- ========================
CREATE TABLE team_tournament_summary (
  id INT AUTO_INCREMENT PRIMARY KEY,
  tournament_id INT NOT NULL,
  team_id INT NULL,
  tournament_team_id INT NULL,
  matches_played INT NOT NULL DEFAULT 0,
  matches_won INT NOT NULL DEFAULT 0,
  runs_for INT NOT NULL DEFAULT 0,
  runs_against INT NOT NULL DEFAULT 0,
  CONSTRAINT fk_tts_tournament FOREIGN KEY (tournament_id) REFERENCES tournaments(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_tts_team FOREIGN KEY (team_id) REFERENCES teams(id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_tts_tt FOREIGN KEY (tournament_team_id) REFERENCES tournament_teams(id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========================
-- PLAYER_MATCH_STATS
-- ========================
CREATE TABLE player_match_stats (
  id INT AUTO_INCREMENT PRIMARY KEY,
  match_id INT NOT NULL,
  player_id INT NOT NULL,
  tournament_team_id INT NULL,
  runs_scored INT NOT NULL DEFAULT 0,
  balls_faced INT NOT NULL DEFAULT 0,
  fours INT NOT NULL DEFAULT 0,
  sixes INT NOT NULL DEFAULT 0,
  overs_bowled FLOAT NOT NULL DEFAULT 0,
  runs_conceded INT NOT NULL DEFAULT 0,
  wickets INT NOT NULL DEFAULT 0,
  player_of_match BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT fk_pms_match FOREIGN KEY (match_id) REFERENCES matches(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_pms_player FOREIGN KEY (player_id) REFERENCES players(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_pms_tt FOREIGN KEY (tournament_team_id) REFERENCES tournament_teams(id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========================
-- BALL_BY_BALL
-- ========================
CREATE TABLE ball_by_ball (
  id INT AUTO_INCREMENT PRIMARY KEY,
  match_id INT NOT NULL,
  innings_id INT NOT NULL,
  over_number INT NOT NULL,
  ball_in_over INT NOT NULL,
  bowler_player_id INT NOT NULL,
  batsman_player_id INT NOT NULL,
  non_striker_player_id INT NOT NULL,
  runs INT NOT NULL DEFAULT 0,
  extra_type VARCHAR(50) NULL,
  is_wicket BOOLEAN NOT NULL DEFAULT FALSE,
  dismissal_type VARCHAR(50) NULL,
  notes VARCHAR(255) NULL,
  CONSTRAINT fk_bbb_match FOREIGN KEY (match_id) REFERENCES matches(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_bbb_innings FOREIGN KEY (innings_id) REFERENCES match_innings(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_bbb_bowler FOREIGN KEY (bowler_player_id) REFERENCES players(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_bbb_batsman FOREIGN KEY (batsman_player_id) REFERENCES players(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_bbb_non_striker FOREIGN KEY (non_striker_player_id) REFERENCES players(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
