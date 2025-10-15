-- Add owner and captain fields to teams table, and migrate existing data (MySQL-compatible, idempotent)

-- Add owner_id
SET @col_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'teams' AND COLUMN_NAME = 'owner_id');
SET @sql := IF(@col_exists = 0, 'ALTER TABLE teams ADD COLUMN owner_id INT NULL AFTER trophies', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Add owner_name
SET @col_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'teams' AND COLUMN_NAME = 'owner_name');
SET @sql := IF(@col_exists = 0, 'ALTER TABLE teams ADD COLUMN owner_name VARCHAR(100) NULL AFTER owner_id', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Add owner_phone
SET @col_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'teams' AND COLUMN_NAME = 'owner_phone');
SET @sql := IF(@col_exists = 0, 'ALTER TABLE teams ADD COLUMN owner_phone VARCHAR(30) NULL AFTER owner_name', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Add captain_player_id
SET @col_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'teams' AND COLUMN_NAME = 'captain_player_id');
SET @sql := IF(@col_exists = 0, 'ALTER TABLE teams ADD COLUMN captain_player_id INT NULL AFTER owner_phone', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Add vice_captain_player_id
SET @col_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'teams' AND COLUMN_NAME = 'vice_captain_player_id');
SET @sql := IF(@col_exists = 0, 'ALTER TABLE teams ADD COLUMN vice_captain_player_id INT NULL AFTER captain_player_id', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Create indexes if missing
SET @idx_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'teams' AND INDEX_NAME = 'idx_teams_owner_id');
SET @sql := IF(@idx_exists = 0, 'CREATE INDEX idx_teams_owner_id ON teams (owner_id)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'teams' AND INDEX_NAME = 'idx_teams_captain_player_id');
SET @sql := IF(@idx_exists = 0, 'CREATE INDEX idx_teams_captain_player_id ON teams (captain_player_id)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'teams' AND INDEX_NAME = 'idx_teams_vice_captain_player_id');
SET @sql := IF(@idx_exists = 0, 'CREATE INDEX idx_teams_vice_captain_player_id ON teams (vice_captain_player_id)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Migrate existing captain_id-based ownership to owner fields
UPDATE teams t
LEFT JOIN users u ON t.captain_id = u.id
SET t.owner_id = COALESCE(t.owner_id, t.captain_id),
    t.owner_name = COALESCE(t.owner_name, u.captain_name, u.phone_number),
    t.owner_phone = COALESCE(t.owner_phone, u.phone_number)
WHERE t.owner_id IS NULL;

-- Add constraint to ensure captain and vice are different (if supported and not present)
SET @chk_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'teams' AND CONSTRAINT_NAME = 'teams_captain_vice_distinct'
);
SET @sql := IF(@chk_exists = 0,
  'ALTER TABLE teams ADD CONSTRAINT teams_captain_vice_distinct CHECK (captain_player_id IS NULL OR vice_captain_player_id IS NULL OR captain_player_id <> vice_captain_player_id)',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
