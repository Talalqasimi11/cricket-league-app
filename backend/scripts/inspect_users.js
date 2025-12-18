
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

        const [rows] = await conn.query("SELECT password_hash FROM users LIMIT 1");
        console.log("ROWS:", rows);
        await conn.end();
    } catch (e) {
        console.error("Error:", e);
    }
})();
