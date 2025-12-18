
require('dotenv').config({ path: '.env' });
const mysql = require('mysql2/promise');

const dbConfig = {
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    database: process.env.DB_NAME
};

async function checkSchema() {
    let conn;
    try {
        conn = await mysql.createConnection(dbConfig);
        const [rows] = await conn.query("DESCRIBE tournament_matches");
        const fs = require('fs');
        fs.writeFileSync('schema_dump_utf8.json', JSON.stringify(rows, null, 2), 'utf8');
        console.log("Written to schema_dump_utf8.json");
    } catch (error) {
        console.error(error);
    } finally {
        if (conn) await conn.end();
    }
}

checkSchema();
