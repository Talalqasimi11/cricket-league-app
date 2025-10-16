#!/usr/bin/env node

/**
 * TestSprite Test Runner for Cricket League App
 * 
 * This script runs comprehensive tests for the Cricket League App
 * covering authentication, team management, tournaments, live scoring, and more.
 * 
 * Prerequisites:
 * 1. Backend server running on http://localhost:5000
 * 2. MySQL database with cricket_league schema
 * 3. TestSprite installed: npm install -g testsprite
 * 
 * Usage:
 * node test-cricket-app.js
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// Test configuration
const config = {
  backendUrl: 'http://localhost:5000',
  testTimeout: 30000,
  retries: 2,
  parallel: true,
  maxConcurrency: 5
};

// Test data
const testData = {
  validCaptain: {
    phone_number: '+1234567890',
    password: 'password123',
    team_name: 'Test Team',
    team_location: 'Test City',
    captain_name: 'Test Captain',
    owner_name: 'Test Owner'
  },
  validPlayer: {
    player_name: 'Test Player',
    player_role: 'batsman',
    player_image_url: 'https://example.com/player.jpg'
  },
  validTournament: {
    tournament_name: 'Test Tournament',
    location: 'Test Stadium',
    start_date: '2024-12-01'
  }
};

// Utility functions
function log(message, type = 'info') {
  const timestamp = new Date().toISOString();
  const prefix = type === 'error' ? '❌' : type === 'success' ? '✅' : 'ℹ️';
  console.log(`${prefix} [${timestamp}] ${message}`);
}

function runCommand(command, options = {}) {
  try {
    const result = execSync(command, { 
      encoding: 'utf8', 
      stdio: options.silent ? 'pipe' : 'inherit',
      ...options 
    });
    return { success: true, output: result };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

function waitForServer(url, timeout = 30000) {
  const startTime = Date.now();
  return new Promise((resolve) => {
    const checkServer = async () => {
      try {
        const response = await fetch(url);
        if (response.ok) {
          log(`Server is ready at ${url}`, 'success');
          resolve(true);
        } else {
          throw new Error('Server not ready');
        }
      } catch (error) {
        if (Date.now() - startTime > timeout) {
          log(`Server not ready after ${timeout}ms`, 'error');
          resolve(false);
        } else {
          setTimeout(checkServer, 1000);
        }
      }
    };
    checkServer();
  });
}

// Test functions
async function testHealthCheck() {
  log('Testing health check endpoint...');
  try {
    const response = await fetch(`${config.backendUrl}/health`);
    const data = await response.json();
    
    if (response.ok && data.status === 'ok' && data.db === 'up') {
      log('Health check passed', 'success');
      return true;
    } else {
      log(`Health check failed: ${JSON.stringify(data)}`, 'error');
      return false;
    }
  } catch (error) {
    log(`Health check error: ${error.message}`, 'error');
    return false;
  }
}

async function testAuthentication() {
  log('Testing authentication endpoints...');
  const results = [];
  
  // Test registration
  try {
    const registerResponse = await fetch(`${config.backendUrl}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(testData.validCaptain)
    });
    
    if (registerResponse.ok) {
      log('Registration test passed', 'success');
      results.push(true);
    } else {
      const error = await registerResponse.json();
      log(`Registration test failed: ${error.error}`, 'error');
      results.push(false);
    }
  } catch (error) {
    log(`Registration test error: ${error.message}`, 'error');
    results.push(false);
  }
  
  // Test login
  try {
    const loginResponse = await fetch(`${config.backendUrl}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        phone_number: testData.validCaptain.phone_number,
        password: testData.validCaptain.password
      })
    });
    
    if (loginResponse.ok) {
      const loginData = await loginResponse.json();
      if (loginData.token && loginData.refresh_token) {
        log('Login test passed', 'success');
        results.push(true);
        // Store tokens for other tests
        global.testTokens = {
          accessToken: loginData.token,
          refreshToken: loginData.refresh_token,
          userId: loginData.user.id
        };
      } else {
        log('Login test failed: Missing tokens', 'error');
        results.push(false);
      }
    } else {
      const error = await loginResponse.json();
      log(`Login test failed: ${error.error}`, 'error');
      results.push(false);
    }
  } catch (error) {
    log(`Login test error: ${error.message}`, 'error');
    results.push(false);
  }
  
  return results.every(r => r);
}

async function testTeamManagement() {
  log('Testing team management endpoints...');
  const results = [];
  
  if (!global.testTokens) {
    log('No authentication tokens available, skipping team tests', 'error');
    return false;
  }
  
  // Test get my team
  try {
    const teamResponse = await fetch(`${config.backendUrl}/api/teams/my-team`, {
      headers: { 'Authorization': `Bearer ${global.testTokens.accessToken}` }
    });
    
    if (teamResponse.ok) {
      log('Get my team test passed', 'success');
      results.push(true);
    } else {
      log('Get my team test failed', 'error');
      results.push(false);
    }
  } catch (error) {
    log(`Get my team test error: ${error.message}`, 'error');
    results.push(false);
  }
  
  // Test add player
  try {
    const playerResponse = await fetch(`${config.backendUrl}/api/players/add`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${global.testTokens.accessToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(testData.validPlayer)
    });
    
    if (playerResponse.ok) {
      log('Add player test passed', 'success');
      results.push(true);
    } else {
      log('Add player test failed', 'error');
      results.push(false);
    }
  } catch (error) {
    log(`Add player test error: ${error.message}`, 'error');
    results.push(false);
  }
  
  return results.every(r => r);
}

async function testTournamentManagement() {
  log('Testing tournament management endpoints...');
  const results = [];
  
  if (!global.testTokens) {
    log('No authentication tokens available, skipping tournament tests', 'error');
    return false;
  }
  
  // Test create tournament
  try {
    const tournamentResponse = await fetch(`${config.backendUrl}/api/tournaments/create`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${global.testTokens.accessToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(testData.validTournament)
    });
    
    if (tournamentResponse.ok) {
      const tournamentData = await tournamentResponse.json();
      global.testTournamentId = tournamentData.id;
      log('Create tournament test passed', 'success');
      results.push(true);
    } else {
      log('Create tournament test failed', 'error');
      results.push(false);
    }
  } catch (error) {
    log(`Create tournament test error: ${error.message}`, 'error');
    results.push(false);
  }
  
  // Test get tournaments
  try {
    const tournamentsResponse = await fetch(`${config.backendUrl}/api/tournaments/`);
    
    if (tournamentsResponse.ok) {
      log('Get tournaments test passed', 'success');
      results.push(true);
    } else {
      log('Get tournaments test failed', 'error');
      results.push(false);
    }
  } catch (error) {
    log(`Get tournaments test error: ${error.message}`, 'error');
    results.push(false);
  }
  
  return results.every(r => r);
}

async function testLiveScoring() {
  log('Testing live scoring endpoints...');
  const results = [];
  
  if (!global.testTokens) {
    log('No authentication tokens available, skipping live scoring tests', 'error');
    return false;
  }
  
  // Test get live score (this should work even without a match)
  try {
    const liveScoreResponse = await fetch(`${config.backendUrl}/api/live/1`);
    
    // This might return 404 if no match exists, which is expected
    if (liveScoreResponse.ok || liveScoreResponse.status === 404) {
      log('Live score endpoint test passed', 'success');
      results.push(true);
    } else {
      log('Live score endpoint test failed', 'error');
      results.push(false);
    }
  } catch (error) {
    log(`Live score test error: ${error.message}`, 'error');
    results.push(false);
  }
  
  return results.every(r => r);
}

async function testErrorHandling() {
  log('Testing error handling...');
  const results = [];
  
  // Test invalid endpoint
  try {
    const invalidResponse = await fetch(`${config.backendUrl}/api/nonexistent`);
    
    if (invalidResponse.status === 404) {
      log('404 error handling test passed', 'success');
      results.push(true);
    } else {
      log('404 error handling test failed', 'error');
      results.push(false);
    }
  } catch (error) {
    log(`404 error handling test error: ${error.message}`, 'error');
    results.push(false);
  }
  
  // Test malformed JSON
  try {
    const malformedResponse = await fetch(`${config.backendUrl}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: 'invalid json'
    });
    
    if (malformedResponse.status === 400) {
      log('Malformed JSON error handling test passed', 'success');
      results.push(true);
    } else {
      log('Malformed JSON error handling test failed', 'error');
      results.push(false);
    }
  } catch (error) {
    log(`Malformed JSON error handling test error: ${error.message}`, 'error');
    results.push(false);
  }
  
  return results.every(r => r);
}

// Main test runner
async function runTests() {
  log('Starting Cricket League App Test Suite', 'info');
  log('=====================================', 'info');
  
  // Check if server is running
  log('Checking if backend server is running...', 'info');
  const serverReady = await waitForServer(`${config.backendUrl}/health`);
  if (!serverReady) {
    log('Backend server is not running. Please start it first.', 'error');
    log('Run: cd backend && npm start', 'info');
    process.exit(1);
  }
  
  const testResults = {
    healthCheck: false,
    authentication: false,
    teamManagement: false,
    tournamentManagement: false,
    liveScoring: false,
    errorHandling: false
  };
  
  // Run tests
  testResults.healthCheck = await testHealthCheck();
  testResults.authentication = await testAuthentication();
  testResults.teamManagement = await testTeamManagement();
  testResults.tournamentManagement = await testTournamentManagement();
  testResults.liveScoring = await testLiveScoring();
  testResults.errorHandling = await testErrorHandling();
  
  // Print results
  log('', 'info');
  log('Test Results Summary', 'info');
  log('===================', 'info');
  
  Object.entries(testResults).forEach(([test, passed]) => {
    const status = passed ? 'PASS' : 'FAIL';
    const icon = passed ? '✅' : '❌';
    log(`${icon} ${test}: ${status}`, passed ? 'success' : 'error');
  });
  
  const totalTests = Object.keys(testResults).length;
  const passedTests = Object.values(testResults).filter(Boolean).length;
  const failedTests = totalTests - passedTests;
  
  log('', 'info');
  log(`Total Tests: ${totalTests}`, 'info');
  log(`Passed: ${passedTests}`, 'success');
  log(`Failed: ${failedTests}`, failedTests > 0 ? 'error' : 'success');
  
  if (failedTests === 0) {
    log('🎉 All tests passed!', 'success');
    process.exit(0);
  } else {
    log('❌ Some tests failed. Check the logs above for details.', 'error');
    process.exit(1);
  }
}

// Run tests if this script is executed directly
if (require.main === module) {
  runTests().catch(error => {
    log(`Test runner error: ${error.message}`, 'error');
    process.exit(1);
  });
}

module.exports = {
  runTests,
  testHealthCheck,
  testAuthentication,
  testTeamManagement,
  testTournamentManagement,
  testLiveScoring,
  testErrorHandling
};
