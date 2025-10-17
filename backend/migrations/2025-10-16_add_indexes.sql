-- Indexes for performance and constraints

-- ball_by_ball unique (ensure table exists first)
SET @table_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ball_by_ball');
SET @idx_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ball_by_ball' AND INDEX_NAME = 'uq_ball_position');
SET @sql := IF(@table_exists > 0 AND @idx_exists = 0, 'ALTER TABLE ball_by_ball ADD UNIQUE KEY uq_ball_position (match_id, over_number, ball_number)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- player_match_stats indexes
SET @table_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'player_match_stats');
SET @idx_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'player_match_stats' AND INDEX_NAME = 'idx_pms_match');
SET @sql := IF(@table_exists > 0 AND @idx_exists = 0, 'ALTER TABLE player_match_stats ADD INDEX idx_pms_match (match_id)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'player_match_stats' AND INDEX_NAME = 'idx_pms_player');
SET @sql := IF(@table_exists > 0 AND @idx_exists = 0, 'ALTER TABLE player_match_stats ADD INDEX idx_pms_player (player_id)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'player_match_stats' AND INDEX_NAME = 'idx_pms_match_player');
SET @sql := IF(@table_exists > 0 AND @idx_exists = 0, 'ALTER TABLE player_match_stats ADD INDEX idx_pms_match_player (match_id, player_id)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- matches indexes
SET @table_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'matches');
SET @idx_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'matches' AND INDEX_NAME = 'idx_matches_tournament');
SET @sql := IF(@table_exists > 0 AND @idx_exists = 0, 'ALTER TABLE matches ADD INDEX idx_matches_tournament (tournament_id)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'matches' AND INDEX_NAME = 'idx_matches_status');
SET @sql := IF(@table_exists > 0 AND @idx_exists = 0, 'ALTER TABLE matches ADD INDEX idx_matches_status (status)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- users unique phone number
SET @idx_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND INDEX_NAME = 'uq_users_phone');
SET @sql := IF(@idx_exists = 0, 'ALTER TABLE users ADD UNIQUE KEY uq_users_phone (phone_number)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- refresh tokens by user
SET @table_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'refresh_tokens');
SET @idx_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'refresh_tokens' AND INDEX_NAME = 'idx_refresh_tokens_user');
SET @sql := IF(@table_exists > 0 AND @idx_exists = 0, 'ALTER TABLE refresh_tokens ADD INDEX idx_refresh_tokens_user (user_id)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- password resets by user and active token checks
SET @table_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'password_resets');
SET @idx_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'password_resets' AND INDEX_NAME = 'idx_password_resets_user');
SET @sql := IF(@table_exists > 0 AND @idx_exists = 0, 'ALTER TABLE password_resets ADD INDEX idx_password_resets_user (user_id)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'password_resets' AND INDEX_NAME = 'idx_password_resets_active');
SET @sql := IF(@table_exists > 0 AND @idx_exists = 0, 'ALTER TABLE password_resets ADD INDEX idx_password_resets_active (user_id, used_at, expires_at)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- teams by owner
SET @table_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'teams');
SET @idx_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'teams' AND INDEX_NAME = 'idx_teams_owner');
SET @sql := IF(@table_exists > 0 AND @idx_exists = 0, 'ALTER TABLE teams ADD INDEX idx_teams_owner (owner_id)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- players by team
SET @table_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'players');
SET @idx_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'players' AND INDEX_NAME = 'idx_players_team');
SET @sql := IF(@table_exists > 0 AND @idx_exists = 0, 'ALTER TABLE players ADD INDEX idx_players_team (team_id)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- tournament_teams by tournament
SET @table_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tournament_teams');
SET @idx_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tournament_teams' AND INDEX_NAME = 'idx_tournament_teams_tournament');
SET @sql := IF(@table_exists > 0 AND @idx_exists = 0, 'ALTER TABLE tournament_teams ADD INDEX idx_tournament_teams_tournament (tournament_id)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;


