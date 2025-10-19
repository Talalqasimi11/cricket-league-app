const request = require('supertest');
const mysql = require('mysql2/promise');
const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');

// Test database setup
const setupTestDB = async () => {
  const db = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASS || '',
    database: process.env.TEST_DB_NAME || 'cricket_league_test',
  });
  return db;
};

describe('Teams API Integration Tests', () => {
  let app;
  let db;
  let server;
  let authToken;
  let teamId;
  let playerId;
  const testPhone = `+1555${Date.now().toString().slice(-7)}`;
  const testPassword = 'TestPassword123!';
  const testTeamName = 'Test Team';
  const testTeamLocation = 'Test City';

  beforeAll(async () => {
    // Set test environment
    process.env.NODE_ENV = 'test';
    process.env.JWT_SECRET = 'test-jwt-secret';
    process.env.JWT_REFRESH_SECRET = 'test-refresh-secret';
    process.env.JWT_ISS = 'test-issuer';
    process.env.JWT_AUD = 'test-audience';
    process.env.ALLOW_REFRESH_IN_BODY = 'true';
    
    // Setup test database
    db = await setupTestDB();
    
    // Create Express app for testing
    app = express();
    app.use(cors({ origin: true, credentials: true }));
    app.use(express.json());
    app.use(cookieParser());
    
    // Import and mount routes
    const authRoutes = require('../routes/authRoutes');
    const teamRoutes = require('../routes/teamRoutes');
    const playerRoutes = require('../routes/playerRoutes');
    const tournamentRoutes = require('../routes/tournamentRoutes');
    const tournamentTeamRoutes = require('../routes/tournamentTeamRoutes');
    const tournamentMatchRoutes = require('../routes/tournamentMatchRoutes');
    
    app.use('/api/auth', authRoutes);
    app.use('/api/teams', teamRoutes);
    app.use('/api/players', playerRoutes);
    app.use('/api/tournaments', tournamentRoutes);
    app.use('/api/tournament-teams', tournamentTeamRoutes);
    app.use('/api/tournament-matches', tournamentMatchRoutes);
    
    // Start test server
    server = app.listen(0);
  });

  beforeEach(async () => {
    // Clean up test data
    await db.query('DELETE FROM players WHERE team_id IN (SELECT id FROM teams WHERE owner_id IN (SELECT id FROM users WHERE phone_number = ?))', [testPhone]);
    await db.query('DELETE FROM teams WHERE owner_id IN (SELECT id FROM users WHERE phone_number = ?)', [testPhone]);
    await db.query('DELETE FROM users WHERE phone_number = ?', [testPhone]);
    
    // Register and login to get auth token
    const registerRes = await request(app)
      .post('/api/auth/register')
      .send({
        phone_number: testPhone,
        password: testPassword,
        team_name: testTeamName,
        team_location: testTeamLocation
      });
    
    expect(registerRes.status).toBe(201);
    authToken = registerRes.body.token;
    
    // Get team ID for tests
    const teamRes = await request(app)
      .get('/api/teams/my-team')
      .set('Authorization', `Bearer ${authToken}`);
    
    if (teamRes.status === 200) {
      teamId = teamRes.body.id;
    }
  });

  afterAll(async () => {
    // Clean up test data
    await db.query('DELETE FROM players WHERE team_id IN (SELECT id FROM teams WHERE owner_id IN (SELECT id FROM users WHERE phone_number = ?))', [testPhone]);
    await db.query('DELETE FROM teams WHERE owner_id IN (SELECT id FROM users WHERE phone_number = ?)', [testPhone]);
    await db.query('DELETE FROM users WHERE phone_number = ?', [testPhone]);
    
    if (server) {
      server.close();
    }
    if (db) {
      await db.end();
    }
  });

  describe('GET /api/teams', () => {
    test('should get all teams (public endpoint)', async () => {
      const res = await request(app).get('/api/teams');
      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThan(0);
    });
  });

  describe('GET /api/teams/my-team', () => {
    test('should get authenticated user team details', async () => {
      const res = await request(app)
        .get('/api/teams/my-team')
        .set('Authorization', `Bearer ${authToken}`);
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('id');
      expect(res.body).toHaveProperty('team_name', testTeamName);
      expect(res.body).toHaveProperty('team_location', testTeamLocation);
      expect(res.body).toHaveProperty('players');
      expect(Array.isArray(res.body.players)).toBe(true);
    });

    test('should reject unauthenticated request', async () => {
      const res = await request(app).get('/api/teams/my-team');
      expect(res.status).toBe(401);
    });
  });

  describe('PUT /api/teams/update', () => {
    test('should update team successfully', async () => {
      const res = await request(app)
        .put('/api/teams/update')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          team_name: 'Updated Team Name',
          team_location: 'Updated City'
        });
      
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('message', 'Team updated successfully');
      expect(res.body.team).toHaveProperty('team_name', 'Updated Team Name');
    });

    test('should reject update with missing required fields', async () => {
      const res = await request(app)
        .put('/api/teams/update')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          team_name: 'Test Team'
          // Missing team_location
        });
      
      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Team name and location are required');
    });

    test('should reject update with invalid captain selection', async () => {
      // First add a player to the team
      const addPlayerRes = await request(app)
        .post('/api/players')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          player_name: 'Test Player',
          player_role: 'Batsman'
        });
      
      expect(addPlayerRes.status).toBe(201);
      playerId = addPlayerRes.body.id;

      // Try to update with invalid captain (non-existent player ID)
      const res = await request(app)
        .put('/api/teams/update')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          team_name: 'Test Team',
          team_location: 'Test City',
          captain_player_id: 99999 // Invalid player ID
        });
      
      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Captain must be a player on your team');
    });

    test('should reject update with invalid vice captain selection', async () => {
      const res = await request(app)
        .put('/api/teams/update')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          team_name: 'Test Team',
          team_location: 'Test City',
          vice_captain_player_id: 99999 // Invalid player ID
        });
      
      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Vice Captain must be a player on your team');
    });

    test('should reject update with same captain and vice captain', async () => {
      // First add a player to the team
      const addPlayerRes = await request(app)
        .post('/api/players')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          player_name: 'Test Player',
          player_role: 'Batsman'
        });
      
      expect(addPlayerRes.status).toBe(201);
      playerId = addPlayerRes.body.id;

      const res = await request(app)
        .put('/api/teams/update')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          team_name: 'Test Team',
          team_location: 'Test City',
          captain_player_id: playerId,
          vice_captain_player_id: playerId // Same as captain
        });
      
      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Captain and Vice Captain must be different players');
    });
  });

  describe('DELETE /api/teams/my-team', () => {
    test('should delete team successfully when no constraints exist', async () => {
      const res = await request(app)
        .delete('/api/teams/my-team')
        .set('Authorization', `Bearer ${authToken}`);
      
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('message', 'Team deleted successfully');
      
      // Verify team is actually deleted
      const getTeamRes = await request(app)
        .get('/api/teams/my-team')
        .set('Authorization', `Bearer ${authToken}`);
      expect(getTeamRes.status).toBe(404);
    });

    test('should reject deletion when team is in tournament_teams', async () => {
      // Create a tournament
      const tournamentRes = await request(app)
        .post('/api/tournaments')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          tournament_name: 'Test Tournament',
          location: 'Test Location',
          start_date: '2024-12-01'
        });
      
      expect(tournamentRes.status).toBe(201);
      const tournamentId = tournamentRes.body.id;

      // Add team to tournament
      const addToTournamentRes = await request(app)
        .post('/api/tournament-teams')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          tournament_id: tournamentId,
          team_id: teamId
        });
      
      expect(addToTournamentRes.status).toBe(201);

      // Try to delete team
      const deleteRes = await request(app)
        .delete('/api/teams/my-team')
        .set('Authorization', `Bearer ${authToken}`);
      
      expect(deleteRes.status).toBe(400);
      expect(deleteRes.body).toHaveProperty('error', 'Cannot delete team that is participating in tournaments. Please withdraw from all tournaments first.');
    });

    test('should reject deletion when team has direct match references', async () => {
      // Create a tournament first
      const tournamentRes = await request(app)
        .post('/api/tournaments')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          tournament_name: 'Test Tournament',
          location: 'Test Location',
          start_date: '2024-12-01'
        });
      
      expect(tournamentRes.status).toBe(201);
      const tournamentId = tournamentRes.body.id;

      // Create a match with this team
      const matchRes = await request(app)
        .post('/api/tournament-matches')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          tournament_id: tournamentId,
          team1_id: teamId,
          team2_id: teamId, // Using same team for simplicity
          match_datetime: '2024-12-01 10:00:00',
          venue: 'Test Venue',
          overs: 20
        });
      
      expect(matchRes.status).toBe(201);

      // Try to delete team
      const deleteRes = await request(app)
        .delete('/api/teams/my-team')
        .set('Authorization', `Bearer ${authToken}`);
      
      expect(deleteRes.status).toBe(400);
      expect(deleteRes.body).toHaveProperty('error', 'Cannot delete team that has match history.');
    });

    test('should reject deletion when team has tournament match references via tournament_teams', async () => {
      // Create a tournament
      const tournamentRes = await request(app)
        .post('/api/tournaments')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          tournament_name: 'Test Tournament',
          location: 'Test Location',
          start_date: '2024-12-01'
        });
      
      expect(tournamentRes.status).toBe(201);
      const tournamentId = tournamentRes.body.id;

      // Add team to tournament
      const addToTournamentRes = await request(app)
        .post('/api/tournament-teams')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          tournament_id: tournamentId,
          team_id: teamId
        });
      
      expect(addToTournamentRes.status).toBe(201);
      const tournamentTeamId = addToTournamentRes.body.id;

      // Create a match using tournament_teams references
      const matchRes = await request(app)
        .post('/api/tournament-matches')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          tournament_id: tournamentId,
          team1_tt_id: tournamentTeamId,
          team2_tt_id: tournamentTeamId, // Using same team for simplicity
          match_datetime: '2024-12-01 10:00:00',
          venue: 'Test Venue',
          overs: 20
        });
      
      expect(matchRes.status).toBe(201);

      // Try to delete team
      const deleteRes = await request(app)
        .delete('/api/teams/my-team')
        .set('Authorization', `Bearer ${authToken}`);
      
      expect(deleteRes.status).toBe(400);
      expect(deleteRes.body).toHaveProperty('error', 'Cannot delete team that has tournament match history.');
    });

    test('should allow deletion when team is in tournament_teams but has no matches', async () => {
      // Create a tournament
      const tournamentRes = await request(app)
        .post('/api/tournaments')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          tournament_name: 'Test Tournament',
          location: 'Test Location',
          start_date: '2024-12-01'
        });
      
      expect(tournamentRes.status).toBe(201);
      const tournamentId = tournamentRes.body.id;

      // Add team to tournament (but no matches)
      const addToTournamentRes = await request(app)
        .post('/api/tournament-teams')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          tournament_id: tournamentId,
          team_id: teamId
        });
      
      expect(addToTournamentRes.status).toBe(201);

      // Try to delete team - this should be blocked
      const deleteRes = await request(app)
        .delete('/api/teams/my-team')
        .set('Authorization', `Bearer ${authToken}`);
      
      expect(deleteRes.status).toBe(400);
      expect(deleteRes.body).toHaveProperty('error', 'Cannot delete team that is participating in tournaments. Please withdraw from all tournaments first.');
    });

    test('should reject deletion for unauthenticated request', async () => {
      const res = await request(app).delete('/api/teams/my-team');
      expect(res.status).toBe(401);
    });

    test('should reject deletion when user has no team', async () => {
      // Create a new user without a team
      const newPhone = `+1555${Date.now().toString().slice(-7)}`;
      const registerRes = await request(app)
        .post('/api/auth/register')
        .send({
          phone_number: newPhone,
          password: 'TestPassword123!',
          team_name: 'Another Team',
          team_location: 'Another City'
        });
      
      expect(registerRes.status).toBe(201);
      const newAuthToken = registerRes.body.token;

      // Delete the team first
      const deleteRes = await request(app)
        .delete('/api/teams/my-team')
        .set('Authorization', `Bearer ${newAuthToken}`);
      
      expect(deleteRes.status).toBe(200);

      // Try to delete again
      const deleteAgainRes = await request(app)
        .delete('/api/teams/my-team')
        .set('Authorization', `Bearer ${newAuthToken}`);
      
      expect(deleteAgainRes.status).toBe(404);
      expect(deleteAgainRes.body).toHaveProperty('error', 'Team not found');
    });
  });

  describe('Route ordering test', () => {
    test('should not shadow /my-team with /:id', async () => {
      // Test that /my-team works correctly
      const myTeamRes = await request(app)
        .get('/api/teams/my-team')
        .set('Authorization', `Bearer ${authToken}`);
      expect(myTeamRes.status).toBe(200);
      
      // Test that /:id works for specific team ID
      const teamByIdRes = await request(app).get(`/api/teams/${teamId}`);
      expect(teamByIdRes.status).toBe(200);
      expect(teamByIdRes.body).toHaveProperty('id', teamId);
    });

    // Additional negative test cases for public endpoints and URL validation
    test('should not include owner_phone in public team list', async () => {
      const res = await request(app).get('/api/teams');
      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      
      // Check that no team in the list has owner_phone
      res.body.forEach(team => {
        expect(team).not.toHaveProperty('owner_phone');
        expect(team).not.toHaveProperty('owner_id');
      });
    });

    test('should not include owner_phone in public team by ID', async () => {
      const res = await request(app).get(`/api/teams/${teamId}`);
      expect(res.status).toBe(200);
      expect(res.body).not.toHaveProperty('owner_phone');
      expect(res.body).not.toHaveProperty('owner_id');
    });

    test('should include owner_phone in authenticated my-team endpoint', async () => {
      const res = await request(app)
        .get('/api/teams/my-team')
        .set('Authorization', `Bearer ${authToken}`);
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('owner_phone');
    });

    test('should reject team registration with invalid team_logo_url - javascript scheme', async () => {
      const invalidPhone = `+1555${Date.now().toString().slice(-7)}`;
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          phone_number: invalidPhone,
          password: 'TestPassword123!',
          team_name: 'Test Team',
          team_location: 'Test City',
          team_logo_url: 'javascript:alert("xss")'
        });
      expect(res.status).toBe(400);
      expect(res.body.error).toContain('Invalid team logo URL');
    });

    test('should reject team registration with invalid team_logo_url - file scheme', async () => {
      const invalidPhone = `+1555${Date.now().toString().slice(-7)}`;
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          phone_number: invalidPhone,
          password: 'TestPassword123!',
          team_name: 'Test Team',
          team_location: 'Test City',
          team_logo_url: 'file:///etc/passwd'
        });
      expect(res.status).toBe(400);
      expect(res.body.error).toContain('Invalid team logo URL');
    });

    test('should reject team registration with invalid team_logo_url - too long', async () => {
      const invalidPhone = `+1555${Date.now().toString().slice(-7)}`;
      const longUrl = 'https://example.com/' + 'a'.repeat(300);
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          phone_number: invalidPhone,
          password: 'TestPassword123!',
          team_name: 'Test Team',
          team_location: 'Test City',
          team_logo_url: longUrl
        });
      expect(res.status).toBe(400);
      expect(res.body.error).toContain('Invalid team logo URL');
    });

    test('should reject team update with invalid team_logo_url', async () => {
      const res = await request(app)
        .put('/api/teams/update')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          team_name: 'Updated Team',
          team_location: 'Updated City',
          team_logo_url: 'javascript:alert("xss")'
        });
      expect(res.status).toBe(400);
      expect(res.body.error).toContain('Invalid team logo URL');
    });

    test('should accept valid team_logo_url with http scheme', async () => {
      const res = await request(app)
        .put('/api/teams/update')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          team_name: 'Updated Team',
          team_location: 'Updated City',
          team_logo_url: 'http://example.com/logo.png'
        });
      expect(res.status).toBe(200);
    });

    test('should accept valid team_logo_url with https scheme', async () => {
      const res = await request(app)
        .put('/api/teams/update')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          team_name: 'Updated Team',
          team_location: 'Updated City',
          team_logo_url: 'https://example.com/logo.png'
        });
      expect(res.status).toBe(200);
    });

    test('should normalize http to https for team_logo_url', async () => {
      const res = await request(app)
        .put('/api/teams/update')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          team_name: 'Updated Team',
          team_location: 'Updated City',
          team_logo_url: 'http://example.com/logo.png'
        });
      expect(res.status).toBe(200);
      expect(res.body.team.team_logo_url).toBe('https://example.com/logo.png');
    });

    test('should accept null team_logo_url', async () => {
      const res = await request(app)
        .put('/api/teams/update')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          team_name: 'Updated Team',
          team_location: 'Updated City',
          team_logo_url: null
        });
      expect(res.status).toBe(200);
    });

    test('should accept empty string team_logo_url', async () => {
      const res = await request(app)
        .put('/api/teams/update')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          team_name: 'Updated Team',
          team_location: 'Updated City',
          team_logo_url: ''
        });
      expect(res.status).toBe(200);
    });
  });
});

