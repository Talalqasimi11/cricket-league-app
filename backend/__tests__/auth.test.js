const request = require('supertest');
const mysql = require('mysql2/promise');
const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const fs = require('fs').promises;
const path = require('path');

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

describe('Auth API Integration Tests', () => {
  let app;
  let db;
  let server;
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

    // Initialize schema
    const schemaPath = path.join(__dirname, '../../cricket-league-db/complete_schema.sql');
    const schemaSQL = await fs.readFile(schemaPath, 'utf8');
    const statements = schemaSQL.split(';').filter(stmt => stmt.trim());
    for (const statement of statements) {
      if (statement.trim()) {
        await db.execute(statement);
      }
    }

    // Create Express app for testing
    app = express();
    app.use(cors({ origin: true, credentials: true }));
    app.use(express.json());
    app.use(cookieParser());
    
    // Import and mount auth routes
    const authRoutes = require('../routes/authRoutes');
    app.use('/api/auth', authRoutes);
    
    // Start test server
    server = app.listen(0);
  });

  beforeEach(async () => {
    // Start a transaction for each test
    await db.execute('START TRANSACTION');
  });

  afterEach(async () => {
    // Rollback transaction after each test
    await db.execute('ROLLBACK');
  });

  afterAll(async () => {
    // Cleanup
    if (db) {
      await db.end();
    }
    if (server) {
      server.close();
    }
  });

  describe('POST /api/auth/register', () => {
    test('should register a new captain with valid data', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          phone_number: testPhone,
          password: testPassword,
          team_name: testTeamName,
          team_location: testTeamLocation,
        });
      expect(res.status).toBe(201);
      expect(res.body.message).toContain('registered successfully');
    });

    test('should reject registration with duplicate phone number', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({ 
          phone_number: testPhone, 
          password: testPassword, 
          team_name: 'Test', 
          team_location: 'Test' 
        });
      expect(res.status).toBe(409);
      expect(res.body.error).toContain('already registered');
    });

    test('should reject registration with invalid phone format', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({ 
          phone_number: 'invalid', 
          password: testPassword, 
          team_name: 'Test', 
          team_location: 'Test' 
        });
      expect(res.status).toBe(400);
      expect(res.body.error).toContain('Invalid phone number format');
    });

    test('should reject registration with short password', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({ 
          phone_number: '+15551234567', 
          password: 'short', 
          team_name: 'Test', 
          team_location: 'Test' 
        });
      expect(res.status).toBe(400);
      expect(res.body.error).toContain('at least 8 characters');
    });
  });

  describe('POST /api/auth/login', () => {
    test('should login with correct credentials', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ phone_number: testPhone, password: testPassword });
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('token');
      expect(res.body).toHaveProperty('refresh_token');
      expect(res.body).toHaveProperty('user');
      expect(res.body.user).toHaveProperty('id');
      expect(res.body.user).toHaveProperty('phone_number', testPhone);
    });

    test('should reject login with incorrect password', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ phone_number: testPhone, password: 'wrongpassword' });
      expect(res.status).toBe(401);
      expect(res.body.error).toContain('Invalid credentials');
    });

    test('should reject login for non-existent user', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ phone_number: '+15559999999', password: testPassword });
      expect(res.status).toBe(404);
      expect(res.body.error).toContain('User not found');
    });

    test('should implement progressive throttling after multiple failures', async () => {
      // Clear any existing failures first
      await db.execute('DELETE FROM auth_failures WHERE phone_number = ?', [testPhone]);
      
      // Make 3 failed attempts
      for (let i = 0; i < 3; i++) {
        await request(app)
          .post('/api/auth/login')
          .send({ phone_number: testPhone, password: 'wrongpassword' });
      }
      
      // 4th attempt should be throttled
      const res = await request(app)
        .post('/api/auth/login')
        .send({ phone_number: testPhone, password: 'wrongpassword' });
      
      expect(res.status).toBe(429);
      expect(res.body.error).toContain('Too many failed login attempts');
      expect(res.body).toHaveProperty('retryAfter');
      expect(typeof res.body.retryAfter).toBe('number');
    });
  });

  describe('POST /api/auth/refresh', () => {
    test('should refresh access token with valid refresh token', async () => {
      const loginRes = await request(app)
        .post('/api/auth/login')
        .send({ phone_number: testPhone, password: testPassword });
      const refreshToken = loginRes.body.refresh_token;
      
      const res = await request(app)
        .post('/api/auth/refresh')
        .send({ refresh_token: refreshToken });
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('token');
    });

    test('should reject refresh with invalid token', async () => {
      const res = await request(app)
        .post('/api/auth/refresh')
        .send({ refresh_token: 'invalid.token.here' });
      expect(res.status).toBe(401);
      expect(res.body.error).toContain('Invalid refresh token');
    });

    test('should refresh with cookie-based token', async () => {
      const loginRes = await request(app)
        .post('/api/auth/login')
        .send({ phone_number: testPhone, password: testPassword });
      
      const cookies = loginRes.headers['set-cookie'];
      const refreshCookie = cookies.find(cookie => cookie.startsWith('refresh_token='));
      
      const res = await request(app)
        .post('/api/auth/refresh')
        .set('Cookie', refreshCookie);
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('token');
    });
  });

  describe('POST /api/auth/logout', () => {
    test('should logout and revoke refresh token', async () => {
      const loginRes = await request(app)
        .post('/api/auth/login')
        .send({ phone_number: testPhone, password: testPassword });
      
      const res = await request(app)
        .post('/api/auth/logout')
        .send({ refresh_token: loginRes.body.refresh_token });
      expect(res.status).toBe(200);
      expect(res.body.message).toContain('Logged out');
    });

    test('should logout with cookie-based token', async () => {
      const loginRes = await request(app)
        .post('/api/auth/login')
        .send({ phone_number: testPhone, password: testPassword });
      
      const cookies = loginRes.headers['set-cookie'];
      const refreshCookie = cookies.find(cookie => cookie.startsWith('refresh_token='));
      
      const res = await request(app)
        .post('/api/auth/logout')
        .set('Cookie', refreshCookie);
      expect(res.status).toBe(200);
      expect(res.body.message).toContain('Logged out');
    });
  });

  describe('Password Reset Flow', () => {
    test('should request password reset for valid user', async () => {
      const res = await request(app)
        .post('/api/auth/forgot-password')
        .send({ phone_number: testPhone });
      expect(res.status).toBe(200);
      expect(res.body.message).toContain('Reset initiated');
      expect(res.body).toHaveProperty('token'); // In test environment
    });

    test('should verify password reset token', async () => {
      // First request reset
      const resetRes = await request(app)
        .post('/api/auth/forgot-password')
        .send({ phone_number: testPhone });
      const token = resetRes.body.token;
      
      // Verify token
      const verifyRes = await request(app)
        .post('/api/auth/verify-reset')
        .send({ phone_number: testPhone, token });
      expect(verifyRes.status).toBe(200);
      expect(verifyRes.body.valid).toBe(true);
    });

    test('should confirm password reset', async () => {
      // First request reset
      const resetRes = await request(app)
        .post('/api/auth/forgot-password')
        .send({ phone_number: testPhone });
      const token = resetRes.body.token;
      
      // Confirm reset with new password
      const confirmRes = await request(app)
        .post('/api/auth/reset-password')
        .send({ 
          phone_number: testPhone, 
          token, 
          new_password: 'NewPassword123!' 
        });
      expect(confirmRes.status).toBe(200);
      expect(confirmRes.body.message).toContain('Password reset successful');
    });
  });

  describe('Cookie Security', () => {
    test('should set secure cookie flags', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ phone_number: testPhone, password: testPassword });
      
      const cookies = res.headers['set-cookie'];
      const refreshCookie = cookies.find(cookie => cookie.startsWith('refresh_token='));
      const csrfCookie = cookies.find(cookie => cookie.startsWith('csrf-token='));
      
      expect(refreshCookie).toContain('HttpOnly');
      expect(refreshCookie).toContain('Path=/');
      expect(csrfCookie).toContain('Path=/');
    });
  });
});
