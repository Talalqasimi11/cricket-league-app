-- Add captain_name to users table for display purposes
SET @col_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'captain_name');
SET @sql := IF(@col_exists = 0, 'ALTER TABLE users ADD COLUMN captain_name VARCHAR(100) NULL AFTER password_hash', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
