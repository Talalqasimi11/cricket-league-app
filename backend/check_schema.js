const mysql = require("mysql2/promise");
require("dotenv").config();

const dbConfig = {
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    database: process.env.DB_NAME,
};

async function checkSchema() {
    try {
        const connection = await mysql.createConnection(dbConfig);
        const [rows] = await connection.execute("DESCRIBE matches");
        console.log("Matches Table Schema:");
        rows.forEach(r => console.log(r.Field));
        await connection.end();
    } catch (err) {
        console.error("Error:", err);
    }
}

checkSchema();
