
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const mysql = require('mysql2/promise');

const dbConfig = {
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    database: process.env.DB_NAME
};

async function migrate() {
    let conn;
    try {
        conn = await mysql.createConnection(dbConfig);
        console.log("Connected. Adding match_id column...");

        // Check if column exists first to avoid error
        const [columns] = await conn.query("SHOW COLUMNS FROM tournament_matches LIKE 'match_id'");
        if (columns.length > 0) {
            console.log("Column match_id already exists.");
        } else {
            await conn.query("ALTER TABLE tournament_matches ADD COLUMN match_id INT NULL");
            console.log("Column match_id added.");

            await conn.query("ALTER TABLE tournament_matches ADD CONSTRAINT fk_tm_match FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE SET NULL");
            console.log("Foreign key constraint added.");
        }

    } catch (error) {
        console.error("Migration failed:", error);
    } finally {
        if (conn) await conn.end();
    }
}

migrate();
