#!/usr/bin/env node

/**
 * Test cleanup script
 * This script cleans up test data after test execution
 */

const mysql = require('mysql2/promise');
require('dotenv').config();

async function cleanupTestEnvironment() {
  let connection;
  
  try {
    console.log('🧹 Cleaning up test environment...\n');
    
    // Connect to database
    connection = await mysql.createConnection({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASS,
      database: process.env.DB_NAME,
    });
    
    console.log('✅ Connected to database');
    
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
    
    // Clear test feedback
    await connection.execute('DELETE FROM feedback WHERE message LIKE ?', ['%test%']);
    console.log('✅ Cleared test feedback');
    
    // Clear any test tournaments created
    await connection.execute('DELETE FROM tournaments WHERE tournament_name LIKE ?', ['%Test%']);
    console.log('✅ Cleared test tournaments');
    
    // Clear any test matches
    await connection.execute('DELETE FROM matches WHERE id > 0'); // Clear all matches for clean testing
    console.log('✅ Cleared test matches');
    
    console.log('\n🎉 Test environment cleanup completed!');
    
  } catch (error) {
    console.error('❌ Error cleaning up test environment:', error.message);
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
      console.log('\n✅ Database connection closed');
    }
  }
}

// Run the cleanup function
cleanupTestEnvironment();
