-- Create tournaments table if it doesn't exist
-- This migration ensures the tournaments table is created with all required columns

-- Check if tournaments table exists
SET @table_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tournaments');

-- Create tournaments table if it doesn't exist
SET @sql := IF(@table_exists = 0, 
  'CREATE TABLE tournaments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_name VARCHAR(100) NOT NULL,
    location VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    status ENUM(\'upcoming\',\'not_started\',\'live\',\'completed\',\'abandoned\') NOT NULL DEFAULT \'not_started\',
    created_by INT NOT NULL,
    CONSTRAINT fk_tournament_creator FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
  ) ENGINE=InnoDB', 
  'SELECT 1');

PREPARE stmt FROM @sql; 
EXECUTE stmt; 
DEALLOCATE PREPARE stmt;

-- Create tournament_teams table if it doesn't exist
SET @table_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tournament_teams');

SET @sql := IF(@table_exists = 0, 
  'CREATE TABLE tournament_teams (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_id INT NOT NULL,
    team_id INT NOT NULL,
    CONSTRAINT fk_tournament_team_tournament FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE,
    CONSTRAINT fk_tournament_team_team FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE,
    UNIQUE KEY unique_tournament_team (tournament_id, team_id)
  ) ENGINE=InnoDB', 
  'SELECT 1');

PREPARE stmt FROM @sql; 
EXECUTE stmt; 
DEALLOCATE PREPARE stmt;
