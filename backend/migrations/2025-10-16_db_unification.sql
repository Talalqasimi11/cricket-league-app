-- Unify DB schema to match controllers usage

-- TEAMS: owner_name, owner_phone, captain_id, captain_player_id, vice_captain_player_id, team_logo_url
ALTER TABLE teams
  ADD COLUMN IF NOT EXISTS owner_name VARCHAR(100) NULL,
  ADD COLUMN IF NOT EXISTS owner_phone VARCHAR(20) NULL,
  ADD COLUMN IF NOT EXISTS captain_id INT NULL,
  ADD COLUMN IF NOT EXISTS captain_player_id INT NULL,
  ADD COLUMN IF NOT EXISTS vice_captain_player_id INT NULL,
  ADD COLUMN IF NOT EXISTS team_logo_url VARCHAR(255) NULL,
  ADD INDEX IF NOT EXISTS idx_teams_captain (captain_id),
  ADD INDEX IF NOT EXISTS idx_teams_owner (owner_id);

-- MATCHES: status, winner_team_id, overs (ensure exist), drop legacy winner column if present
ALTER TABLE matches
  ADD COLUMN IF NOT EXISTS status ENUM('not_started','live','completed','abandoned') DEFAULT 'not_started',
  ADD COLUMN IF NOT EXISTS overs INT NOT NULL DEFAULT 20,
  ADD COLUMN IF NOT EXISTS winner_team_id INT NULL,
  ADD CONSTRAINT IF NOT EXISTS fk_match_winner_team FOREIGN KEY (winner_team_id) REFERENCES teams(id) ON DELETE SET NULL,
  DROP COLUMN IF EXISTS winner;

-- MATCH_INNINGS: inning_number, overs, status (keep overs_faced if present for back-compat)
ALTER TABLE match_innings
  ADD COLUMN IF NOT EXISTS inning_number INT NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS overs INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS status ENUM('in_progress','completed') NOT NULL DEFAULT 'in_progress';

-- PLAYER_MATCH_STATS: add columns used in controllers; keep legacy columns
ALTER TABLE player_match_stats
  ADD COLUMN IF NOT EXISTS runs INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS balls_faced INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS balls_bowled INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS runs_conceded INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS wickets INT DEFAULT 0,
  ADD UNIQUE KEY IF NOT EXISTS uq_match_player (match_id, player_id);

-- BALL_BY_BALL: unify to live controller fields; retain legacy columns where needed
ALTER TABLE ball_by_ball
  ADD COLUMN IF NOT EXISTS inning_id INT NULL,
  ADD COLUMN IF NOT EXISTS over_number INT NULL,
  ADD COLUMN IF NOT EXISTS ball_number INT NULL,
  ADD COLUMN IF NOT EXISTS batsman_id INT NULL,
  ADD COLUMN IF NOT EXISTS runs INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS extras VARCHAR(32) NULL,
  ADD COLUMN IF NOT EXISTS wicket_type VARCHAR(32) NULL,
  ADD COLUMN IF NOT EXISTS out_player_id INT NULL;

-- Add unique key for ball_by_ball with correct column names
ALTER TABLE ball_by_ball
  ADD UNIQUE KEY IF NOT EXISTS uq_ball_position (match_id, over_number, ball_number, inning_id);

-- Ensure foreign keys where applicable
ALTER TABLE ball_by_ball
  ADD CONSTRAINT IF NOT EXISTS fk_bbb_match FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE;


