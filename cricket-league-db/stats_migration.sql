-- Migration: Add Boundary Tracking to Player Stats
-- Required for the "Stats Lounge" and enhanced Live Scoring

-- 1. Add 'fours' and 'sixes' columns to player_match_stats
ALTER TABLE player_match_stats 
ADD COLUMN fours INT DEFAULT 0 AFTER runs,
ADD COLUMN sixes INT DEFAULT 0 AFTER fours;

-- 2. (Optional) Backfill existing data
-- If you have already played matches, this calculates the 4s/6s from the ball-by-ball data 
-- so your stats are accurate immediately.

UPDATE player_match_stats pms
JOIN (
    SELECT match_id, batsman_id,
           SUM(CASE WHEN runs = 4 THEN 1 ELSE 0 END) as count_4s,
           SUM(CASE WHEN runs = 6 THEN 1 ELSE 0 END) as count_6s
    FROM ball_by_ball
    WHERE extras IS NULL OR extras = '' -- Only count runs off the bat
    GROUP BY match_id, batsman_id
) derived ON pms.match_id = derived.match_id AND pms.player_id = derived.batsman_id
SET 
    pms.fours = derived.count_4s,
    pms.sixes = derived.count_6s;