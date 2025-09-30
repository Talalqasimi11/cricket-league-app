const mysql = require("mysql2/promise");
require("dotenv").config();

// ✅ Create MySQL connection pool
const db = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10, // adjust based on server capacity
  queueLimit: 0,
});

// ✅ Test connection once at startup
(async () => {
  try {
    const conn = await db.getConnection();
    console.log("✅ MySQL connected successfully");
    conn.release();
  } catch (err) {
    console.error("❌ MySQL connection error:", err.message);
  }
})();

module.exports = db;
