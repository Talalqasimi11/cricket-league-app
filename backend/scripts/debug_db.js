const mysql = require("mysql2/promise");
const path = require("path");
require("dotenv").config({ path: path.join(__dirname, "../.env") });

(async () => {
    console.log("DB_HOST:", process.env.DB_HOST);
    console.log("DB_NAME:", process.env.DB_NAME);

    try {
        const conn = await mysql.createConnection({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASS,
            database: process.env.DB_NAME
        });

        console.log("Connected.");

        const [rows] = await conn.query("SHOW COLUMNS FROM users");
        console.log("Columns details:");
        rows.forEach(r => console.log(JSON.stringify(r)));

        await conn.end();
    } catch (e) {
        console.error("Error:", e);
    }
})();
