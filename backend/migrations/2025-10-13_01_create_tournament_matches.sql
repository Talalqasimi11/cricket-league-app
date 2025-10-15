-- Create core tournament_matches table used across controllers
CREATE TABLE IF NOT EXISTS tournament_matches (
  id INT AUTO_INCREMENT PRIMARY KEY,
  tournament_id INT NOT NULL,
  team1_id INT NULL,
  team2_id INT NULL,
  team1_tt_id INT NULL,
  team2_tt_id INT NULL,
  round VARCHAR(50) NOT NULL DEFAULT 'round_1',
  match_date DATETIME NULL,
  location VARCHAR(255) NULL,
  status ENUM('upcoming','live','finished') NOT NULL DEFAULT 'upcoming',
  winner_id INT NULL,
  parent_match_id INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_tournament_matches_tournament_id (tournament_id),
  INDEX idx_tournament_matches_team1_id (team1_id),
  INDEX idx_tournament_matches_team2_id (team2_id),
  INDEX idx_tournament_matches_team1_tt_id (team1_tt_id),
  INDEX idx_tournament_matches_team2_tt_id (team2_tt_id),
  INDEX idx_tournament_matches_parent_match_id (parent_match_id)
);