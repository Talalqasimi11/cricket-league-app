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

        const [rows] = await conn.query("SHOW TRIGGERS LIKE 'matches'");
        console.log("TRIGGERS on matches:", rows.length);
        rows.forEach(r => console.log(r.Trigger));

        await conn.end();
    } catch (e) {
        console.error("Error:", e);
    }
})();
