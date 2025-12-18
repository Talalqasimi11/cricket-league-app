-- Migration: Security Tables, Feedback, and Performance Indexes
-- Description: Adds missing tables required by authController and feedbackController, plus performance optimizations.

-- 1. Refresh Tokens (Required for JWT Auth & Logout)
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    token VARCHAR(512) NOT NULL,
    is_revoked BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    revoked_at DATETIME NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_token (token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Auth Failures (Required for Rate Limiting & Security)
CREATE TABLE IF NOT EXISTS auth_failures (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NULL,
    email VARCHAR(255) NULL,
    ip_address VARCHAR(45),
    user_agent VARCHAR(255),
    failed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    resolved_at DATETIME NULL,
    INDEX idx_ip_phone (ip_address, phone_number),
    INDEX idx_failed_at (failed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Password Resets (Required for Forgot Password Flow)
CREATE TABLE IF NOT EXISTS password_resets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    token_hash VARCHAR(255) NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    used_at DATETIME NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_active (user_id, used_at, expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Feedback (Required for Support Screen)
CREATE TABLE IF NOT EXISTS feedback (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL, -- Nullable to allow guest feedback if needed
    message TEXT NOT NULL,
    contact VARCHAR(100) NULL,
    status VARCHAR(20) DEFAULT 'open', -- open, reviewed, closed
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Performance Indexes (Optimizations for frequent queries)

-- Optimize "My Team" lookups (teamController.getMyTeam)
CREATE INDEX IF NOT EXISTS idx_teams_owner ON teams(owner_id);

-- Optimize fetching live/upcoming matches (matchProvider)
CREATE INDEX IF NOT EXISTS idx_matches_status ON matches(status);

-- Optimize Tournament Bracket rendering (tournamentMatchController)
CREATE INDEX IF NOT EXISTS idx_tourn_matches_tourn_id ON tournament_matches(tournament_id);

-- Optimize Player Stats calculation (liveScoreController)
CREATE INDEX IF NOT EXISTS idx_ball_match_inning ON ball_by_ball(match_id, inning_id);

-- Optimize searching players by team
CREATE INDEX IF NOT EXISTS idx_players_team ON players(team_id);