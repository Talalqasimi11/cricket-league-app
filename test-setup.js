#!/usr/bin/env node

/**
 * Test Setup Script for Cricket League App
 * 
 * This script prepares the test environment by:
 * 1. Starting the backend server
 * 2. Verifying database connection
 * 3. Setting up test data
 * 4. Ensuring all services are ready
 */

const { execSync, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

// Configuration
const config = {
  backendDir: './backend',
  frontendDir: './frontend',
  backendUrl: 'http://localhost:5000',
  dbName: 'cricket_league',
  testTimeout: 60000
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

async function waitForServer(url, timeout = 30000) {
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

// Setup functions
function checkPrerequisites() {
  log('Checking prerequisites...', 'info');
  
  // Check if Node.js is installed
  const nodeCheck = runCommand('node --version', { silent: true });
  if (!nodeCheck.success) {
    log('Node.js is not installed', 'error');
    return false;
  }
  log(`Node.js version: ${nodeCheck.output.trim()}`, 'success');
  
  // Check if npm is installed
  const npmCheck = runCommand('npm --version', { silent: true });
  if (!npmCheck.success) {
    log('npm is not installed', 'error');
    return false;
  }
  log(`npm version: ${npmCheck.output.trim()}`, 'success');
  
  // Check if Flutter is installed
  const flutterCheck = runCommand('flutter --version', { silent: true });
  if (!flutterCheck.success) {
    log('Flutter is not installed', 'error');
    return false;
  }
  log(`Flutter version: ${flutterCheck.output.split('\n')[0]}`, 'success');
  
  // Check if MySQL is available
  const mysqlCheck = runCommand('mysql --version', { silent: true });
  if (!mysqlCheck.success) {
    log('MySQL is not installed or not in PATH', 'error');
    return false;
  }
  log(`MySQL version: ${mysqlCheck.output.split('\n')[0]}`, 'success');
  
  return true;
}

function installDependencies() {
  log('Installing dependencies...', 'info');
  
  // Install root dependencies
  const rootInstall = runCommand('npm install');
  if (!rootInstall.success) {
    log('Failed to install root dependencies', 'error');
    return false;
  }
  log('Root dependencies installed', 'success');
  
  // Install backend dependencies
  const backendInstall = runCommand('npm install', { cwd: config.backendDir });
  if (!backendInstall.success) {
    log('Failed to install backend dependencies', 'error');
    return false;
  }
  log('Backend dependencies installed', 'success');
  
  // Install frontend dependencies
  const frontendInstall = runCommand('flutter pub get', { cwd: config.frontendDir });
  if (!frontendInstall.success) {
    log('Failed to install frontend dependencies', 'error');
    return false;
  }
  log('Frontend dependencies installed', 'success');
  
  return true;
}

function checkDatabase() {
  log('Checking database connection...', 'info');
  
  // Check if database exists
  const dbCheck = runCommand(`mysql -u root -p -e "USE ${config.dbName};"`, { silent: true });
  if (!dbCheck.success) {
    log(`Database '${config.dbName}' does not exist. Please create it first.`, 'error');
    log('Run: mysql -u root -p -e "CREATE DATABASE cricket_league;"', 'info');
    return false;
  }
  log(`Database '${config.dbName}' is accessible`, 'success');
  
  return true;
}

function startBackendServer() {
  log('Starting backend server...', 'info');
  
  // Check if .env file exists
  const envPath = path.join(config.backendDir, '.env');
  if (!fs.existsSync(envPath)) {
    log('Backend .env file not found. Creating template...', 'info');
    
    const envTemplate = `DB_HOST=localhost
DB_USER=root
DB_PASS=your_password
DB_NAME=cricket_league
PORT=5000

JWT_SECRET=your_long_random_secret_at_least_32_chars
JWT_REFRESH_SECRET=your_long_random_refresh_secret_at_least_32_chars
JWT_AUD=cric-league-app
JWT_ISS=cric-league-auth

CORS_ORIGINS=http://localhost:3000,http://localhost:5000,http://127.0.0.1:5000,http://10.0.2.2:5000

NODE_ENV=development
COOKIE_SECURE=false
ROTATE_REFRESH_ON_USE=false`;
    
    fs.writeFileSync(envPath, envTemplate);
    log('Please update backend/.env with your database credentials', 'info');
  }
  
  // Start backend server in background
  const backendProcess = spawn('npm', ['start'], {
    cwd: config.backendDir,
    stdio: 'pipe',
    detached: true
  });
  
  // Store process ID for cleanup
  global.backendProcess = backendProcess;
  
  log('Backend server starting...', 'info');
  return true;
}

async function verifySetup() {
  log('Verifying setup...', 'info');
  
  // Wait for server to be ready
  const serverReady = await waitForServer(`${config.backendUrl}/health`, config.testTimeout);
  if (!serverReady) {
    log('Backend server failed to start or is not responding', 'error');
    return false;
  }
  
  // Test health endpoint
  try {
    const response = await fetch(`${config.backendUrl}/health`);
    const data = await response.json();
    
    if (data.status === 'ok' && data.db === 'up') {
      log('Backend server is healthy and database is connected', 'success');
      return true;
    } else {
      log(`Backend health check failed: ${JSON.stringify(data)}`, 'error');
      return false;
    }
  } catch (error) {
    log(`Health check error: ${error.message}`, 'error');
    return false;
  }
}

function createTestData() {
  log('Creating test data...', 'info');
  
  // This would typically involve inserting test data into the database
  // For now, we'll just log that test data will be created during tests
  log('Test data will be created during test execution', 'info');
  
  return true;
}

// Main setup function
async function setup() {
  log('Setting up Cricket League App Test Environment', 'info');
  log('==============================================', 'info');
  
  try {
    // Check prerequisites
    if (!checkPrerequisites()) {
      log('Prerequisites check failed', 'error');
      process.exit(1);
    }
    
    // Install dependencies
    if (!installDependencies()) {
      log('Dependency installation failed', 'error');
      process.exit(1);
    }
    
    // Check database
    if (!checkDatabase()) {
      log('Database check failed', 'error');
      process.exit(1);
    }
    
    // Start backend server
    if (!startBackendServer()) {
      log('Failed to start backend server', 'error');
      process.exit(1);
    }
    
    // Verify setup
    if (!(await verifySetup())) {
      log('Setup verification failed', 'error');
      process.exit(1);
    }
    
    // Create test data
    if (!createTestData()) {
      log('Test data creation failed', 'error');
      process.exit(1);
    }
    
    log('', 'info');
    log('🎉 Test environment setup completed successfully!', 'success');
    log('', 'info');
    log('Next steps:', 'info');
    log('1. Run tests: npm test', 'info');
    log('2. Run full test suite: npm run test:full', 'info');
    log('3. Clean up: npm run test:cleanup', 'info');
    log('', 'info');
    
  } catch (error) {
    log(`Setup error: ${error.message}`, 'error');
    process.exit(1);
  }
}

// Run setup if this script is executed directly
if (require.main === module) {
  setup();
}

module.exports = {
  setup,
  checkPrerequisites,
  installDependencies,
  checkDatabase,
  startBackendServer,
  verifySetup,
  createTestData
};
