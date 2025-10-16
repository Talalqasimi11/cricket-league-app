const mysql = require("mysql2/promise");
const fs = require("fs");
const path = require("path");
require("dotenv").config();

let db;

// ✅ Initialize database connection with auto-setup
(async () => {
  try {
    // First, connect without database to create it if needed
    const tempConnection = await mysql.createConnection({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASS,
    });

    // Create database if it doesn't exist
    await tempConnection.execute(`CREATE DATABASE IF NOT EXISTS \`${process.env.DB_NAME}\``);
    console.log(`✅ Database '${process.env.DB_NAME}' ready`);
    
    // Close temporary connection
    await tempConnection.end();

    // Now create the main connection pool with the database
    db = mysql.createPool({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASS,
      database: process.env.DB_NAME,
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0,
    });

    // Test the connection
    const conn = await db.getConnection();
    console.log("✅ MySQL connected successfully");
    conn.release();

    // Run schema setup if tables don't exist
    await setupSchema();
    
    // Run migrations after schema setup
    await runMigrations();

  } catch (err) {
    console.error("❌ MySQL connection error:", err.message);
    console.error("Please check your database credentials in .env file");
  }
})();

// ✅ Setup database schema
async function setupSchema() {
  try {
    const conn = await db.getConnection();
    
    // Check if users table exists
    const [tables] = await conn.execute(
      "SELECT COUNT(*) as count FROM information_schema.tables WHERE table_schema = ? AND table_name = 'users'",
      [process.env.DB_NAME]
    );
    
    if (tables[0].count === 0) {
      console.log("📋 Setting up database schema...");
      
      // Read and execute schema file
      const schemaPath = path.join(__dirname, '../../cricket-league-db/schema.sql');
      const schema = fs.readFileSync(schemaPath, 'utf8');
      
      // Split by semicolon and execute each statement
      const statements = schema.split(';').filter(stmt => stmt.trim().length > 0);
      
      for (const statement of statements) {
        if (statement.trim()) {
          try {
            await conn.execute(statement);
          } catch (err) {
            // Ignore errors for statements that might already exist
            if (!err.message.includes('already exists')) {
              console.warn(`Warning: ${err.message}`);
            }
          }
        }
      }
      
      console.log("✅ Database schema setup complete");
    } else {
      console.log("✅ Database schema already exists");
    }
    
    conn.release();
  } catch (err) {
    console.error("❌ Schema setup error:", err.message);
  }
}

// ✅ Run migrations after schema setup (with tracking)
async function runMigrations() {
  try {
    const conn = await db.getConnection();
    
    // Create migrations tracking table if it doesn't exist
    await conn.execute(`
      CREATE TABLE IF NOT EXISTS migrations (
        id INT AUTO_INCREMENT PRIMARY KEY,
        filename VARCHAR(255) NOT NULL UNIQUE,
        executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Get list of migration files
    const migrationsDir = path.join(__dirname, '../migrations');
    const migrationFiles = fs.readdirSync(migrationsDir)
      .filter(file => file.endsWith('.sql'))
      .sort(); // Ensure migrations run in order
    
    // Get already executed migrations
    const [executedMigrations] = await conn.execute(
      "SELECT filename FROM migrations"
    );
    const executedSet = new Set(executedMigrations.map(row => row.filename));
    
    // Filter out already executed migrations
    const pendingMigrations = migrationFiles.filter(file => !executedSet.has(file));
    
    if (pendingMigrations.length === 0) {
      console.log("✅ No pending migrations");
      conn.release();
      return;
    }
    
    console.log(`🔄 Running ${pendingMigrations.length} pending migrations...`);
    
    for (const file of pendingMigrations) {
      const migrationPath = path.join(migrationsDir, file);
      const migration = fs.readFileSync(migrationPath, 'utf8');
      
      // Split by semicolon and execute each statement
      const statements = migration.split(';').filter(stmt => stmt.trim().length > 0);
      
      for (const statement of statements) {
        if (statement.trim()) {
          try {
            await conn.execute(statement);
          } catch (err) {
            // Log migration errors but continue
            console.warn(`Migration ${file} warning: ${err.message}`);
          }
        }
      }
      
      // Record migration as executed
      await conn.execute(
        "INSERT INTO migrations (filename) VALUES (?)",
        [file]
      );
      
      console.log(`✅ Migration ${file} completed`);
    }
    
    console.log("✅ All pending migrations completed");
    conn.release();
  } catch (err) {
    console.error("❌ Migration error:", err.message);
  }
}

module.exports = db;
