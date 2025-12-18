const mysql = require("mysql2/promise");
const path = require("path");
require("dotenv").config({ path: path.join(__dirname, "../.env") });

(async () => {
    const conn = await mysql.createConnection({
        host: process.env.DB_HOST,
        user: process.env.DB_USER,
        password: process.env.DB_PASS,
        database: process.env.DB_NAME
    });

    console.log("Attempting insert...");
    try {
        // Minimal insert
        const [res] = await conn.query(
            "INSERT INTO tournament_matches (tournament_id, round, status) VALUES (1, 'test', 'upcoming')"
        );
        console.log("Success:", res.insertId);
    } catch (e) {
        console.error("FAIL:", e.message);
    } finally {
        conn.end();
    }
})();
