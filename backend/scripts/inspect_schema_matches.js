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

        const query = `
            SELECT COLUMN_NAME 
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_SCHEMA = '${process.env.DB_NAME}' 
            AND TABLE_NAME = 'match_innings';
        `;

        const [rows] = await conn.query(query);
        console.log("MATCH_INNINGS TABLE COLUMNS:");
        rows.forEach(r => console.log(r.COLUMN_NAME));

        await conn.end();
    } catch (e) {
        console.error("Error:", e);
    }
})();
