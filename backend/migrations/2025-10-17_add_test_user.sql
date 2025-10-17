-- Add test user for development/testing
-- Phone: 12345678, Password: 12345678
-- This migration is idempotent and will only insert if the user doesn't exist

-- Insert test user (bcrypt hash for '12345678' with salt rounds 12)
-- Hash generated: $2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMeshCSR5P4BYq7s8J4xrV8KDe
INSERT INTO users (phone_number, password_hash, captain_name)
SELECT '12345678', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMeshCSR5P4BYq7s8J4xrV8KDe', 'Test Captain'
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE phone_number = '12345678'
);

-- Get the test user ID
SET @test_user_id = (SELECT id FROM users WHERE phone_number = '12345678');

-- Insert test team for the test user
INSERT INTO teams (team_name, team_location, owner_id, owner_name, owner_phone, captain_id, matches_played, matches_won, trophies)
SELECT 
    'Test Warriors',
    'Test City',
    @test_user_id,
    'Test Captain',
    '12345678',
    @test_user_id,
    0,
    0,
    0
WHERE NOT EXISTS (
    SELECT 1 FROM teams WHERE owner_id = @test_user_id
);

-- Get the test team ID
SET @test_team_id = (SELECT id FROM teams WHERE owner_id = @test_user_id LIMIT 1);

-- Insert some test players for the test team
INSERT INTO players (team_id, player_name, player_role, runs, matches_played, hundreds, fifties, batting_average, strike_rate, wickets)
SELECT @test_team_id, 'Test Batsman 1', 'Batsman', 0, 0, 0, 0, 0.00, 0.00, 0
WHERE NOT EXISTS (SELECT 1 FROM players WHERE team_id = @test_team_id AND player_name = 'Test Batsman 1');

INSERT INTO players (team_id, player_name, player_role, runs, matches_played, hundreds, fifties, batting_average, strike_rate, wickets)
SELECT @test_team_id, 'Test Batsman 2', 'Batsman', 0, 0, 0, 0, 0.00, 0.00, 0
WHERE NOT EXISTS (SELECT 1 FROM players WHERE team_id = @test_team_id AND player_name = 'Test Batsman 2');

INSERT INTO players (team_id, player_name, player_role, runs, matches_played, hundreds, fifties, batting_average, strike_rate, wickets)
SELECT @test_team_id, 'Test Bowler 1', 'Bowler', 0, 0, 0, 0, 0.00, 0.00, 0
WHERE NOT EXISTS (SELECT 1 FROM players WHERE team_id = @test_team_id AND player_name = 'Test Bowler 1');

INSERT INTO players (team_id, player_name, player_role, runs, matches_played, hundreds, fifties, batting_average, strike_rate, wickets)
SELECT @test_team_id, 'Test All-rounder', 'All-rounder', 0, 0, 0, 0, 0.00, 0.00, 0
WHERE NOT EXISTS (SELECT 1 FROM players WHERE team_id = @test_team_id AND player_name = 'Test All-rounder');

INSERT INTO players (team_id, player_name, player_role, runs, matches_played, hundreds, fifties, batting_average, strike_rate, wickets)
SELECT @test_team_id, 'Test Wicket-keeper', 'Wicket-keeper', 0, 0, 0, 0, 0.00, 0.00, 0
WHERE NOT EXISTS (SELECT 1 FROM players WHERE team_id = @test_team_id AND player_name = 'Test Wicket-keeper');

