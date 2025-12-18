const mysql = require("mysql2/promise");
const path = require("path");
require("dotenv").config({ path: path.join(__dirname, "../.env") });

(async () => {
    try {
        const conn = await mysql.createConnection({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASS,
            database: process.env.DB_NAME
        });

        const tables = ['matches', 'teams', 'tournaments'];

        for (const table of tables) {
            console.log(`\n--- ${table.toUpperCase()} ---`);
            try {
                const [rows] = await conn.query(`DESCRIBE ${table}`);
                console.log(rows.map(r => r.Field).join(', '));
            } catch (e) {
                console.log(`Error describing ${table}: ${e.message}`);
            }
        }
        await conn.end();
    } catch (e) {
        console.error("Connection Error:", e);
    }
})();
