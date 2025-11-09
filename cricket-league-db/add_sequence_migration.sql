-- Migration to add sequence column to ball_by_ball table
-- This allows multiple entries for the same delivery (e.g., wide, no-ball)
-- Run this on existing databases to support proper extras tracking

-- Add sequence column if it doesn't exist
ALTER TABLE ball_by_ball 
ADD COLUMN IF NOT EXISTS sequence INT DEFAULT 0 
COMMENT 'Sequence for multiple events on same delivery (0=legal, 1+=extras)';

-- Drop old unique constraint if it exists
ALTER TABLE ball_by_ball DROP INDEX IF EXISTS uniq_ball;

-- Add new unique constraint with sequence
ALTER TABLE ball_by_ball 
ADD CONSTRAINT uq_ball_pos UNIQUE (inning_id, over_number, ball_number, sequence);

-- Update existing records to have sequence = 0 (legal balls)
UPDATE ball_by_ball SET sequence = 0 WHERE sequence IS NULL;
