#!/usr/bin/env node

/**
 * Seed script to create test data for development/testing
 * Run with: node scripts/seedTestData.js
 */

const bcrypt = require('bcryptjs');
const mysql = require('mysql2/promise');
require('dotenv').config();

async function seedTestData() {
  let connection;
  
  try {
    console.log('🌱 Starting test data seeding...\n');
    
    // Connect to database
    connection = await mysql.createConnection({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASS,
      database: process.env.DB_NAME,
    });
    
    console.log('✅ Connected to database');
    
    // Test credentials
    const testPhone = '12345678';
    const testPassword = '12345678';
    const passwordHash = await bcrypt.hash(testPassword, 12);
    
    // Check if test user already exists
    const [existingUsers] = await connection.execute(
      'SELECT id FROM users WHERE phone_number = ?',
      [testPhone]
    );
    
    let userId;
    
    if (existingUsers.length > 0) {
      userId = existingUsers[0].id;
      console.log(`ℹ️  Test user already exists (ID: ${userId})`);
      
      // Update password in case it changed
      await connection.execute(
        'UPDATE users SET password_hash = ? WHERE id = ?',
        [passwordHash, userId]
      );
      console.log('✅ Updated test user password');
    } else {
      // Create test user
      const [result] = await connection.execute(
        'INSERT INTO users (phone_number, password_hash) VALUES (?, ?)',
        [testPhone, passwordHash]
      );
      userId = result.insertId;
      console.log(`✅ Created test user (ID: ${userId})`);
    }
    
    // Check if test team exists
    const [existingTeams] = await connection.execute(
      'SELECT id FROM teams WHERE owner_id = ?',
      [userId]
    );
    
    let teamId;
    
    if (existingTeams.length > 0) {
      teamId = existingTeams[0].id;
      console.log(`ℹ️  Test team already exists (ID: ${teamId})`);
    } else {
      // Create test team
      const [teamResult] = await connection.execute(
        `INSERT INTO teams (team_name, team_location, owner_id, matches_played, matches_won, trophies)
         VALUES (?, ?, ?, 0, 0, 0)`,
        ['Test Warriors', 'Test City', userId]
      );
      teamId = teamResult.insertId;
      console.log(`✅ Created test team (ID: ${teamId})`);
    }
    
    // Create test players
    const testPlayers = [
      { name: 'Test Batsman 1', role: 'Batsman' },
      { name: 'Test Batsman 2', role: 'Batsman' },
      { name: 'Test Bowler 1', role: 'Bowler' },
      { name: 'Test Bowler 2', role: 'Bowler' },
      { name: 'Test All-rounder', role: 'All-rounder' },
      { name: 'Test Wicket-keeper', role: 'Wicket-keeper' },
    ];
    
    let playersCreated = 0;
    let playersSkipped = 0;
    
    for (const player of testPlayers) {
      const [existing] = await connection.execute(
        'SELECT id FROM players WHERE team_id = ? AND player_name = ?',
        [teamId, player.name]
      );
      
      if (existing.length === 0) {
        await connection.execute(
          `INSERT INTO players (team_id, player_name, player_role, runs, matches_played, hundreds, fifties, batting_average, strike_rate, wickets)
           VALUES (?, ?, ?, 0, 0, 0, 0, 0.00, 0.00, 0)`,
          [teamId, player.name, player.role]
        );
        playersCreated++;
      } else {
        playersSkipped++;
      }
    }
    
    if (playersCreated > 0) {
      console.log(`✅ Created ${playersCreated} test players`);
    }
    if (playersSkipped > 0) {
      console.log(`ℹ️  Skipped ${playersSkipped} existing players`);
    }
    
    console.log('\n🎉 Test data seeding completed!\n');
    console.log('📝 Test Credentials:');
    console.log('   Phone Number: 12345678');
    console.log('   Password: 12345678');
    console.log('   Team: Test Warriors');
    console.log('   Location: Test City\n');
    
    console.log('🧪 You can now test the following endpoints:');
    console.log('   POST /api/auth/login');
    console.log('   GET  /api/teams/my-team');
    console.log('   POST /api/players');
    console.log('   POST /api/tournaments');
    console.log('   etc.\n');
    
  } catch (error) {
    console.error('❌ Error seeding test data:', error.message);
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
      console.log('✅ Database connection closed');
    }
  }
}

// Run the seed function
seedTestData();

