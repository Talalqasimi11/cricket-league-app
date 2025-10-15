/*
  Simple SQL migration runner for MySQL (mysql2/promise)
  - Tracks applied files in _migrations table
  - Applies any new .sql files in ./migrations in lexicographic order
*/

const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
require('dotenv').config();

(async () => {
  const migrationsDir = path.resolve(__dirname, '..', 'migrations');

  // Connect with multipleStatements enabled for convenience
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    database: process.env.DB_NAME,
    multipleStatements: true,
  });

  try {
    console.log('➡️  Ensuring migrations table exists...');
    await conn.query(`
      CREATE TABLE IF NOT EXISTS _migrations (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL UNIQUE,
        applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      ) ENGINE=InnoDB;
    `);

    const [appliedRows] = await conn.query('SELECT name FROM _migrations');
    const applied = new Set(appliedRows.map(r => r.name));

    const files = fs
      .readdirSync(migrationsDir)
      .filter(f => f.toLowerCase().endsWith('.sql'))
      .sort((a, b) => a.localeCompare(b));

    if (files.length === 0) {
      console.log('ℹ️  No migration files found.');
      process.exit(0);
    }

    for (const file of files) {
      if (applied.has(file)) {
        console.log(`✅ Skipping already applied: ${file}`);
        continue;
      }

      const fullPath = path.join(migrationsDir, file);
      const raw = fs.readFileSync(fullPath, 'utf8');

      // Strip out single-line comments and split into statements by semicolon
      const sanitized = raw
        .split('\n')
        .map(line => {
          const trimmed = line.trim();
          if (trimmed.startsWith('--')) return ''; // remove SQL comments
          return line;
        })
        .join('\n');

      const statements = sanitized
        .split(';')
        .map(s => s.trim())
        .filter(s => s.length > 0);

      console.log(`🚀 Applying: ${file}`);
      try {
        await conn.beginTransaction();
        for (const stmt of statements) {
          await conn.query(stmt);
        }
        await conn.query('INSERT INTO _migrations (name) VALUES (?)', [file]);
        await conn.commit();
        console.log(`✅ Applied: ${file}`);
      } catch (err) {
        await conn.rollback();
        console.error(`❌ Failed to apply ${file}:`, err.message);
        process.exitCode = 1;
        break;
      }
    }
  } finally {
    await conn.end();
  }
})();
