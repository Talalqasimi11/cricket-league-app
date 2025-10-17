#!/usr/bin/env node

/**
 * Cleanup script to remove test data
 * Run with: node scripts/cleanupTestData.js
 */

const mysql = require('mysql2/promise');
require('dotenv').config();

async function cleanupTestData() {
  let connection;
  
  try {
    console.log('🧹 Starting test data cleanup...\n');
    
    // Connect to database
    connection = await mysql.createConnection({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASS,
      database: process.env.DB_NAME,
    });
    
    console.log('✅ Connected to database');
    
    const testPhone = '12345678';
    
    // Get test user ID
    const [users] = await connection.execute(
      'SELECT id FROM users WHERE phone_number = ?',
      [testPhone]
    );
    
    if (users.length === 0) {
      console.log('ℹ️  No test user found. Nothing to cleanup.');
      return;
    }
    
    const userId = users[0].id;
    console.log(`Found test user (ID: ${userId})`);
    
    // Get test team ID
    const [teams] = await connection.execute(
      'SELECT id FROM teams WHERE owner_id = ?',
      [userId]
    );
    
    if (teams.length > 0) {
      const teamId = teams[0].id;
      
      // Delete players
      const [playersResult] = await connection.execute(
        'DELETE FROM players WHERE team_id = ?',
        [teamId]
      );
      console.log(`✅ Deleted ${playersResult.affectedRows} players`);
      
      // Delete team
      const [teamsResult] = await connection.execute(
        'DELETE FROM teams WHERE id = ?',
        [teamId]
      );
      console.log(`✅ Deleted ${teamsResult.affectedRows} team(s)`);
    }
    
    // Delete refresh tokens
    const [tokensResult] = await connection.execute(
      'DELETE FROM refresh_tokens WHERE user_id = ?',
      [userId]
    );
    console.log(`✅ Deleted ${tokensResult.affectedRows} refresh token(s)`);
    
    // Delete auth failures
    const [failuresResult] = await connection.execute(
      'DELETE FROM auth_failures WHERE phone_number = ?',
      [testPhone]
    );
    console.log(`✅ Deleted ${failuresResult.affectedRows} auth failure(s)`);
    
    // Delete user
    const [usersResult] = await connection.execute(
      'DELETE FROM users WHERE id = ?',
      [userId]
    );
    console.log(`✅ Deleted ${usersResult.affectedRows} user(s)`);
    
    console.log('\n🎉 Test data cleanup completed!\n');
    
  } catch (error) {
    console.error('❌ Error cleaning up test data:', error.message);
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
      console.log('✅ Database connection closed');
    }
  }
}

// Run the cleanup function
cleanupTestData();

