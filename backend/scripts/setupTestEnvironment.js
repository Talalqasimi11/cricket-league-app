#!/usr/bin/env node

/**
 * Comprehensive test setup script
 * This script sets up clean test data and clears any existing test artifacts
 */

const mysql = require('mysql2/promise');
require('dotenv').config();

async function setupTestEnvironment() {
  let connection;
  
  try {
    console.log('🧪 Setting up test environment...\n');
    
    // Connect to database
    connection = await mysql.createConnection({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASS,
      database: process.env.DB_NAME,
    });
    
    console.log('✅ Connected to database');
    
    // Clear existing test data
    console.log('🧹 Cleaning up existing test data...');
    
    // Clear auth failures
    await connection.execute('DELETE FROM auth_failures WHERE phone_number = ?', ['12345678']);
    console.log('✅ Cleared auth failures');
    
    // Clear refresh tokens for test user
    const [testUser] = await connection.execute('SELECT id FROM users WHERE phone_number = ?', ['12345678']);
    if (testUser.length > 0) {
      await connection.execute('DELETE FROM refresh_tokens WHERE user_id = ?', [testUser[0].id]);
      console.log('✅ Cleared refresh tokens');
    }
    
    // Clear password resets
    if (testUser.length > 0) {
      await connection.execute('DELETE FROM password_resets WHERE user_id = ?', [testUser[0].id]);
      console.log('✅ Cleared password resets');
    }
    
    // Clear feedback
    await connection.execute('DELETE FROM feedback WHERE message LIKE ?', ['%test%']);
    console.log('✅ Cleared test feedback');
    
    // Update test user password to ensure it's correct
    const bcrypt = require('bcryptjs');
    const passwordHash = await bcrypt.hash('12345678', 12);
    
    let userId;
    if (testUser.length > 0) {
      userId = testUser[0].id;
      await connection.execute(
        'UPDATE users SET password_hash = ? WHERE id = ?',
        [passwordHash, userId]
      );
      console.log('✅ Updated test user password');
    } else {
      // Create test user if it doesn't exist
      const [result] = await connection.execute(
        'INSERT INTO users (phone_number, password_hash) VALUES (?, ?)',
        ['12345678', passwordHash]
      );
      userId = result.insertId;
      console.log('✅ Created test user');
    }
    
    // Ensure test user has a team (create if doesn't exist)
    const [existingTeam] = await connection.execute(
      'SELECT id FROM teams WHERE owner_id = ?',
      [userId]
    );
    
    if (existingTeam.length === 0) {
      await connection.execute(
        `INSERT INTO teams (team_name, team_location, owner_id, matches_played, matches_won, trophies)
         VALUES (?, ?, ?, 0, 0, 0)`,
        ['Test Warriors', 'Test City', userId]
      );
      console.log('✅ Created test team');
    } else {
      console.log('✅ Test team already exists');
    }
    
    console.log('\n🎉 Test environment setup completed!');
    console.log('\n📝 Test Credentials:');
    console.log('   Phone Number: 12345678');
    console.log('   Password: 12345678');
    console.log('   Team: Test Warriors');
    console.log('   Location: Test City');
    
  } catch (error) {
    console.error('❌ Error setting up test environment:', error.message);
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
      console.log('\n✅ Database connection closed');
    }
  }
}

// Run the setup function
setupTestEnvironment();
