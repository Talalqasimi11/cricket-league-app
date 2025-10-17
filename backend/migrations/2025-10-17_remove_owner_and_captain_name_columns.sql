-- Remove owner_name and captain_name columns as per user request
-- Only one player can be captain, assigned by user itself

-- Remove captain_name from users table
SET @col_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'captain_name');
SET @sql := IF(@col_exists > 0, 'ALTER TABLE users DROP COLUMN captain_name', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Remove owner_name from teams table
SET @col_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'teams' AND COLUMN_NAME = 'owner_name');
SET @sql := IF(@col_exists > 0, 'ALTER TABLE teams DROP COLUMN owner_name', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Remove owner_phone from teams table (redundant with users.phone_number)
SET @col_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'teams' AND COLUMN_NAME = 'owner_phone');
SET @sql := IF(@col_exists > 0, 'ALTER TABLE teams DROP COLUMN owner_phone', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Add constraint to ensure only one captain per team
-- First, remove any duplicate captain assignments
UPDATE teams SET captain_player_id = NULL WHERE captain_player_id IN (
  SELECT captain_player_id FROM (
    SELECT captain_player_id, COUNT(*) as cnt 
    FROM teams 
    WHERE captain_player_id IS NOT NULL 
    GROUP BY captain_player_id 
    HAVING cnt > 1
  ) as duplicates
);

-- Add unique constraint for captain_player_id to ensure only one team per captain
SET @constraint_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'teams' AND CONSTRAINT_NAME = 'uq_teams_captain_player_id'
);
SET @sql := IF(@constraint_exists = 0,
  'ALTER TABLE teams ADD CONSTRAINT uq_teams_captain_player_id UNIQUE (captain_player_id)',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
