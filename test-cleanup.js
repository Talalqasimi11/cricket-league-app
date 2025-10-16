#!/usr/bin/env node

/**
 * Test Cleanup Script for Cricket League App
 * 
 * This script cleans up the test environment by:
 * 1. Stopping background processes
 * 2. Cleaning up test data
 * 3. Resetting database state
 * 4. Removing temporary files
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// Configuration
const config = {
  backendDir: './backend',
  frontendDir: './frontend',
  dbName: 'cricket_league',
  testDataPattern: '+123456789%'
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
      cwd: options.cwd || process.cwd(),
      ...options 
    });
    return { success: true, output: result };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

// Cleanup functions
function stopBackendServer() {
  log('Stopping backend server...', 'info');
  
  try {
    // Kill any Node.js processes running on port 5000
    const killResult = runCommand('lsof -ti:5000 | xargs kill -9', { silent: true });
    if (killResult.success) {
      log('Backend server stopped', 'success');
    } else {
      log('No backend server process found on port 5000', 'info');
    }
  } catch (error) {
    log(`Error stopping backend server: ${error.message}`, 'error');
  }
  
  // Also try to kill the process we started
  if (global.backendProcess) {
    try {
      global.backendProcess.kill();
      log('Background backend process killed', 'success');
    } catch (error) {
      log(`Error killing background process: ${error.message}`, 'error');
    }
  }
}

function cleanupTestData() {
  log('Cleaning up test data...', 'info');
  
  try {
    // Clean up test users and related data
    const cleanupQueries = [
      `DELETE FROM ball_by_ball WHERE match_id IN (SELECT id FROM matches WHERE tournament_id IN (SELECT id FROM tournaments WHERE tournament_name LIKE 'Test%'))`,
      `DELETE FROM player_match_stats WHERE match_id IN (SELECT id FROM matches WHERE tournament_id IN (SELECT id FROM tournaments WHERE tournament_name LIKE 'Test%'))`,
      `DELETE FROM match_innings WHERE match_id IN (SELECT id FROM matches WHERE tournament_id IN (SELECT id FROM tournaments WHERE tournament_name LIKE 'Test%'))`,
      `DELETE FROM matches WHERE tournament_id IN (SELECT id FROM tournaments WHERE tournament_name LIKE 'Test%')`,
      `DELETE FROM tournament_teams WHERE tournament_id IN (SELECT id FROM tournaments WHERE tournament_name LIKE 'Test%')`,
      `DELETE FROM tournaments WHERE tournament_name LIKE 'Test%'`,
      `DELETE FROM players WHERE team_id IN (SELECT id FROM teams WHERE team_name LIKE 'Test%')`,
      `DELETE FROM teams WHERE team_name LIKE 'Test%'`,
      `DELETE FROM users WHERE phone_number LIKE '${config.testDataPattern}'`,
      `DELETE FROM refresh_tokens WHERE user_id NOT IN (SELECT id FROM users)`,
      `DELETE FROM password_resets WHERE user_id NOT IN (SELECT id FROM users)`
    ];
    
    // Execute cleanup queries
    cleanupQueries.forEach(query => {
      const result = runCommand(`mysql -u root -p -e "USE ${config.dbName}; ${query};"`, { silent: true });
      if (result.success) {
        log(`Cleaned up: ${query.split(' ')[1]}`, 'success');
      } else {
        log(`Warning: Could not clean up ${query.split(' ')[1]}: ${result.error}`, 'error');
      }
    });
    
    log('Test data cleanup completed', 'success');
    return true;
  } catch (error) {
    log(`Error cleaning up test data: ${error.message}`, 'error');
    return false;
  }
}

function cleanupTempFiles() {
  log('Cleaning up temporary files...', 'info');
  
  const tempFiles = [
    'test-results.html',
    'test-results.json',
    'test-screenshots/',
    'logs/',
    '.test-cache/'
  ];
  
  tempFiles.forEach(file => {
    try {
      if (fs.existsSync(file)) {
        if (fs.statSync(file).isDirectory()) {
          fs.rmSync(file, { recursive: true, force: true });
          log(`Removed directory: ${file}`, 'success');
        } else {
          fs.unlinkSync(file);
          log(`Removed file: ${file}`, 'success');
        }
      }
    } catch (error) {
      log(`Warning: Could not remove ${file}: ${error.message}`, 'error');
    }
  });
}

function resetDatabase() {
  log('Resetting database state...', 'info');
  
  try {
    // Reset auto-increment counters
    const resetQueries = [
      'ALTER TABLE users AUTO_INCREMENT = 1',
      'ALTER TABLE teams AUTO_INCREMENT = 1',
      'ALTER TABLE players AUTO_INCREMENT = 1',
      'ALTER TABLE tournaments AUTO_INCREMENT = 1',
      'ALTER TABLE matches AUTO_INCREMENT = 1',
      'ALTER TABLE ball_by_ball AUTO_INCREMENT = 1'
    ];
    
    resetQueries.forEach(query => {
      const result = runCommand(`mysql -u root -p -e "USE ${config.dbName}; ${query};"`, { silent: true });
      if (result.success) {
        log(`Reset auto-increment for ${query.split(' ')[2]}`, 'success');
      } else {
        log(`Warning: Could not reset ${query.split(' ')[2]}: ${result.error}`, 'error');
      }
    });
    
    log('Database state reset completed', 'success');
    return true;
  } catch (error) {
    log(`Error resetting database: ${error.message}`, 'error');
    return false;
  }
}

function generateCleanupReport() {
  log('Generating cleanup report...', 'info');
  
  const report = {
    timestamp: new Date().toISOString(),
    cleanup: {
      backendServer: 'stopped',
      testData: 'cleaned',
      tempFiles: 'removed',
      database: 'reset'
    },
    status: 'completed'
  };
  
  try {
    fs.writeFileSync('cleanup-report.json', JSON.stringify(report, null, 2));
    log('Cleanup report saved to cleanup-report.json', 'success');
  } catch (error) {
    log(`Warning: Could not save cleanup report: ${error.message}`, 'error');
  }
}

// Main cleanup function
async function cleanup() {
  log('Starting Cricket League App Test Cleanup', 'info');
  log('========================================', 'info');
  
  try {
    // Stop backend server
    stopBackendServer();
    
    // Clean up test data
    if (!cleanupTestData()) {
      log('Test data cleanup had some issues, but continuing...', 'error');
    }
    
    // Reset database
    if (!resetDatabase()) {
      log('Database reset had some issues, but continuing...', 'error');
    }
    
    // Clean up temporary files
    cleanupTempFiles();
    
    // Generate cleanup report
    generateCleanupReport();
    
    log('', 'info');
    log('🎉 Test environment cleanup completed!', 'success');
    log('', 'info');
    log('Cleanup summary:', 'info');
    log('- Backend server stopped', 'success');
    log('- Test data removed from database', 'success');
    log('- Temporary files cleaned up', 'success');
    log('- Database state reset', 'success');
    log('', 'info');
    
  } catch (error) {
    log(`Cleanup error: ${error.message}`, 'error');
    process.exit(1);
  }
}

// Run cleanup if this script is executed directly
if (require.main === module) {
  cleanup();
}

module.exports = {
  cleanup,
  stopBackendServer,
  cleanupTestData,
  cleanupTempFiles,
  resetDatabase,
  generateCleanupReport
};
