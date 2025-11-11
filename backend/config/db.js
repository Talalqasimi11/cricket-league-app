const mysql = require("mysql2/promise");
require("dotenv").config();

// Database configuration
const dbConfig = {
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  connectTimeout: 10000,
  enableKeepAlive: true,
  keepAliveInitialDelay: 10000,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  multipleStatements: false // Security: prevent multiple statements
};

// Create database pool with retry mechanism
let db;
let retryCount = 0;
const MAX_RETRIES = 5;
const RETRY_DELAY = 5000; // 5 seconds

const initializePool = async () => {
  try {
    db = mysql.createPool(dbConfig);
    
    // Verify connection
    await db.execute('SELECT 1');
    console.log('✅ Database connection established successfully');
    retryCount = 0; // Reset retry count on successful connection
    
    // Add connection monitoring
    db.on('connection', (connection) => {
      console.log('New database connection established');
      
      connection.on('error', (err) => {
        console.error('Database connection error:', err);
        handleConnectionError(err);
      });
    });

    db.on('error', (err) => {
      console.error('Database pool error:', err);
      handleConnectionError(err);
    });

  } catch (err) {
    console.error('Failed to initialize database pool:', err);
    handleConnectionError(err);
  }
};

const handleConnectionError = async (err) => {
  if (retryCount >= MAX_RETRIES) {
    console.error(`❌ Failed to connect to database after ${MAX_RETRIES} attempts`);
    process.exit(1); // Exit if we can't establish connection
  }

  if (err.code === 'PROTOCOL_CONNECTION_LOST' || err.code === 'ECONNREFUSED') {
    retryCount++;
    console.log(`Attempting to reconnect... (Attempt ${retryCount}/${MAX_RETRIES})`);
    
    setTimeout(async () => {
      await initializePool();
    }, RETRY_DELAY);
  }
};

// Initialize pool on module load
initializePool();

// Health check function with timeout
const checkConnection = async (timeout = 5000) => {
  try {
    const checkPromise = db.execute('SELECT 1');
    const timeoutPromise = new Promise((_, reject) => {
      setTimeout(() => reject(new Error('Health check timeout')), timeout);
    });

    await Promise.race([checkPromise, timeoutPromise]);
    return true;
  } catch (err) {
    console.error('Database health check failed:', err);
    return false;
  }
};

// Helper for transactions
const withTransaction = async (callback) => {
  const conn = await db.getConnection();
  await conn.beginTransaction();
  
  try {
    const result = await callback(conn);
    await conn.commit();
    return result;
  } catch (err) {
    await conn.rollback();
    throw err;
  } finally {
    conn.release();
  }
};

module.exports = { 
  db, 
  checkConnection,
  withTransaction,
  // Export for testing
  _testing: {
    initializePool,
    handleConnectionError
  }
};