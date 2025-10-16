-- Indexes for performance and constraints

-- ball_by_ball unique (ensure table/columns exist in schema)
ALTER TABLE ball_by_ball
  ADD UNIQUE KEY uq_ball_position (match_id, over_number, ball_number);

-- player_match_stats indexes
ALTER TABLE player_match_stats
  ADD INDEX idx_pms_match (match_id),
  ADD INDEX idx_pms_player (player_id),
  ADD INDEX idx_pms_match_player (match_id, player_id);

-- matches indexes
ALTER TABLE matches
  ADD INDEX idx_matches_tournament (tournament_id),
  ADD INDEX idx_matches_status (status);

-- users unique phone number
ALTER TABLE users
  ADD UNIQUE KEY uq_users_phone (phone_number);

-- refresh tokens by user
ALTER TABLE refresh_tokens
  ADD INDEX idx_refresh_tokens_user (user_id);

-- password resets by user and active token checks
ALTER TABLE password_resets
  ADD INDEX idx_password_resets_user (user_id),
  ADD INDEX idx_password_resets_active (user_id, used_at, expires_at);

-- teams by owner
ALTER TABLE teams
  ADD INDEX idx_teams_owner (owner_id);

-- players by team
ALTER TABLE players
  ADD INDEX idx_players_team (team_id);

-- tournament_teams by tournament
ALTER TABLE tournament_teams
  ADD INDEX idx_tournament_teams_tournament (tournament_id);


