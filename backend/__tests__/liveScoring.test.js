const request = require('supertest');
const app = require('../index');
const db = require('../config/db');

describe('Live Scoring API', () => {
  let testUser, testTeam1, testTeam2, testMatch, testPlayer1, testPlayer2;
  let authToken;

  beforeAll(async () => {
    // Clean up any existing test data
    await db.query('DELETE FROM ball_by_ball WHERE match_id IN (SELECT id FROM matches WHERE tournament_id IN (SELECT id FROM tournaments WHERE tournament_name LIKE "Test%"))');
    await db.query('DELETE FROM match_innings WHERE match_id IN (SELECT id FROM matches WHERE tournament_id IN (SELECT id FROM tournaments WHERE tournament_name LIKE "Test%"))');
    await db.query('DELETE FROM player_match_stats WHERE match_id IN (SELECT id FROM matches WHERE tournament_id IN (SELECT id FROM tournaments WHERE tournament_name LIKE "Test%"))');
    await db.query('DELETE FROM matches WHERE tournament_id IN (SELECT id FROM tournaments WHERE tournament_name LIKE "Test%")');
    await db.query('DELETE FROM tournament_teams WHERE tournament_id IN (SELECT id FROM tournaments WHERE tournament_name LIKE "Test%")');
    await db.query('DELETE FROM tournaments WHERE tournament_name LIKE "Test%"');
    await db.query('DELETE FROM players WHERE team_id IN (SELECT id FROM teams WHERE team_name LIKE "Test%")');
    await db.query('DELETE FROM teams WHERE team_name LIKE "Test%"');
    await db.query('DELETE FROM users WHERE phone_number LIKE "test%"');

    // Create test user
    const [userResult] = await db.query(
      'INSERT INTO users (phone_number, password_hash) VALUES (?, ?)',
      ['test1234567890', 'hashed_password']
    );
    testUser = { id: userResult.insertId, phone_number: 'test1234567890' };

    // Create test teams
    const [team1Result] = await db.query(
      'INSERT INTO teams (owner_id, team_name, team_location) VALUES (?, ?, ?)',
      [testUser.id, 'Test Team A', 'Test Location A']
    );
    testTeam1 = { id: team1Result.insertId, name: 'Test Team A' };

    const [team2Result] = await db.query(
      'INSERT INTO teams (owner_id, team_name, team_location) VALUES (?, ?, ?)',
      [testUser.id, 'Test Team B', 'Test Location B']
    );
    testTeam2 = { id: team2Result.insertId, name: 'Test Team B' };

    // Create test players
    const [player1Result] = await db.query(
      'INSERT INTO players (team_id, player_name, player_role) VALUES (?, ?, ?)',
      [testTeam1.id, 'Test Player 1', 'Batsman']
    );
    testPlayer1 = { id: player1Result.insertId, name: 'Test Player 1' };

    const [player2Result] = await db.query(
      'INSERT INTO players (team_id, player_name, player_role) VALUES (?, ?, ?)',
      [testTeam2.id, 'Test Player 2', 'Bowler']
    );
    testPlayer2 = { id: player2Result.insertId, name: 'Test Player 2' };

    // Create test tournament
    const [tournamentResult] = await db.query(
      'INSERT INTO tournaments (tournament_name, location, start_date, created_by) VALUES (?, ?, ?, ?)',
      ['Test Tournament', 'Test Location', '2024-01-01', testUser.id]
    );
    const testTournament = { id: tournamentResult.insertId };

    // Create test match
    const [matchResult] = await db.query(
      'INSERT INTO matches (tournament_id, team1_id, team2_id, overs, match_date, venue, status) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [testTournament.id, testTeam1.id, testTeam2.id, 20, '2024-01-01 10:00:00', 'Test Venue', 'live']
    );
    testMatch = { id: matchResult.insertId };

    // Get auth token (simplified for testing)
    authToken = 'test_token';
  });

  afterAll(async () => {
    // Clean up test data
    await db.query('DELETE FROM ball_by_ball WHERE match_id = ?', [testMatch.id]);
    await db.query('DELETE FROM match_innings WHERE match_id = ?', [testMatch.id]);
    await db.query('DELETE FROM player_match_stats WHERE match_id = ?', [testMatch.id]);
    await db.query('DELETE FROM matches WHERE id = ?', [testMatch.id]);
    await db.query('DELETE FROM tournaments WHERE id = (SELECT tournament_id FROM matches WHERE id = ?)', [testMatch.id]);
    await db.query('DELETE FROM players WHERE id IN (?, ?)', [testPlayer1.id, testPlayer2.id]);
    await db.query('DELETE FROM teams WHERE id IN (?, ?)', [testTeam1.id, testTeam2.id]);
    await db.query('DELETE FROM users WHERE id = ?', [testUser.id]);
  });

  describe('POST /api/live/start-innings', () => {
    it('should start innings successfully', async () => {
      const response = await request(app)
        .post('/api/live/start-innings')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          match_id: testMatch.id,
          batting_team_id: testTeam1.id,
          bowling_team_id: testTeam2.id,
          inning_number: 1
        });

      expect(response.status).toBe(200);
      expect(response.body.message).toContain('Innings 1 started successfully');
    });

    it('should reject unauthorized user', async () => {
      const response = await request(app)
        .post('/api/live/start-innings')
        .set('Authorization', 'Bearer invalid_token')
        .send({
          match_id: testMatch.id,
          batting_team_id: testTeam1.id,
          bowling_team_id: testTeam2.id,
          inning_number: 2
        });

      expect(response.status).toBe(401);
    });

    it('should reject if match not found', async () => {
      const response = await request(app)
        .post('/api/live/start-innings')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          match_id: 99999,
          batting_team_id: testTeam1.id,
          bowling_team_id: testTeam2.id,
          inning_number: 1
        });

      expect(response.status).toBe(404);
    });
  });

  describe('POST /api/live/ball', () => {
    let inningId;

    beforeAll(async () => {
      // Get the innings ID
      const [innings] = await db.query(
        'SELECT id FROM match_innings WHERE match_id = ? ORDER BY id DESC LIMIT 1',
        [testMatch.id]
      );
      inningId = innings[0].id;
    });

    it('should add ball successfully', async () => {
      const response = await request(app)
        .post('/api/live/ball')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          match_id: testMatch.id,
          inning_id: inningId,
          over_number: 0,
          ball_number: 1,
          batsman_id: testPlayer1.id,
          bowler_id: testPlayer2.id,
          runs: 4
        });

      expect(response.status).toBe(200);
      expect(response.body.message).toBe('Ball recorded successfully');
    });

    it('should reject invalid ball sequence', async () => {
      const response = await request(app)
        .post('/api/live/ball')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          match_id: testMatch.id,
          inning_id: inningId,
          over_number: 0,
          ball_number: 3, // Should be 2 after first ball
          batsman_id: testPlayer1.id,
          bowler_id: testPlayer2.id,
          runs: 1
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toContain('Invalid ball sequence');
    });

    it('should reject duplicate ball', async () => {
      const response = await request(app)
        .post('/api/live/ball')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          match_id: testMatch.id,
          inning_id: inningId,
          over_number: 0,
          ball_number: 1, // Duplicate
          batsman_id: testPlayer1.id,
          bowler_id: testPlayer2.id,
          runs: 1
        });

      expect(response.status).toBe(409);
      expect(response.body.error).toContain('Ball already exists');
    });

    it('should handle wides correctly', async () => {
      const response = await request(app)
        .post('/api/live/ball')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          match_id: testMatch.id,
          inning_id: inningId,
          over_number: 0,
          ball_number: 2,
          batsman_id: testPlayer1.id,
          bowler_id: testPlayer2.id,
          runs: 1,
          extras: 'wide'
        });

      expect(response.status).toBe(200);
    });

    it('should handle wickets correctly', async () => {
      const response = await request(app)
        .post('/api/live/ball')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          match_id: testMatch.id,
          inning_id: inningId,
          over_number: 0,
          ball_number: 3,
          batsman_id: testPlayer1.id,
          bowler_id: testPlayer2.id,
          runs: 0,
          wicket_type: 'bowled',
          out_player_id: testPlayer1.id
        });

      expect(response.status).toBe(200);
    });
  });

  describe('POST /api/live/end-innings', () => {
    let inningId;

    beforeAll(async () => {
      // Get the innings ID
      const [innings] = await db.query(
        'SELECT id FROM match_innings WHERE match_id = ? ORDER BY id DESC LIMIT 1',
        [testMatch.id]
      );
      inningId = innings[0].id;
    });

    it('should end innings successfully', async () => {
      const response = await request(app)
        .post('/api/live/end-innings')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          inning_id: inningId
        });

      expect(response.status).toBe(200);
      expect(response.body.message).toContain('ended manually');
    });

    it('should reject if innings already ended', async () => {
      const response = await request(app)
        .post('/api/live/end-innings')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          inning_id: inningId
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toContain('already ended');
    });
  });

  describe('GET /api/live/:match_id', () => {
    it('should get live score successfully', async () => {
      const response = await request(app)
        .get(`/api/live/${testMatch.id}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('innings');
      expect(response.body).toHaveProperty('balls');
      expect(response.body).toHaveProperty('players');
    });
  });

  describe('GET /api/viewer/live-score/:match_id', () => {
    it('should get viewer data successfully', async () => {
      const response = await request(app)
        .get(`/api/viewer/live-score/${testMatch.id}`);

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('innings');
      expect(response.body).toHaveProperty('balls');
      expect(response.body).toHaveProperty('players');
      expect(response.body).toHaveProperty('currentBatsmen');
      expect(response.body).toHaveProperty('currentBowler');
      expect(response.body).toHaveProperty('last12Balls');
      expect(response.body).toHaveProperty('partnership');
    });
  });
});
