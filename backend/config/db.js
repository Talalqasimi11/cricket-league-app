const mysql = require("mysql2/promise");
require("dotenv").config();

// Create database pool
const db = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  connectTimeout: 10000,
  enableKeepAlive: true,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

// Add connection error handling and retry logic
db.on('connection', (connection) => {
  console.log('New database connection established');
});

db.on('error', (err) => {
  console.error('Database pool error:', err);
  if (err.code === 'PROTOCOL_CONNECTION_LOST') {
    console.log('Database connection lost, attempting to reconnect...');
  }
});

// Health check function
const checkConnection = async () => {
  try {
    await db.execute('SELECT 1');
    return true;
  } catch (err) {
    console.error('Database health check failed:', err);
    return false;
  }
};

module.exports = { db, checkConnection };