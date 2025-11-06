-- Migration script to add legal_balls field to match_innings table
-- This is required for existing databases that don't have this field yet
-- Run this script after deploying the updated schema

-- Add legal_balls column if it doesn't exist
ALTER TABLE match_innings ADD COLUMN IF NOT EXISTS legal_balls INT DEFAULT 0;

-- Update existing records to calculate legal_balls from overs_decimal
-- Assumes overs_decimal contains valid data
UPDATE match_innings 
SET legal_balls = FLOOR(overs_decimal * 6) 
WHERE legal_balls = 0 AND overs_decimal > 0;

-- Add comment to document the field
ALTER TABLE match_innings MODIFY COLUMN legal_balls INT DEFAULT 0 COMMENT 'Number of legal deliveries bowled (excludes wides and no-balls)';
