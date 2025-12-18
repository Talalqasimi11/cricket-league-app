const mysql = require("mysql2/promise");
const fs = require("fs");
const path = require("path");
require("dotenv").config({ path: path.join(__dirname, "../.env") });

const dbConfig = {
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    database: process.env.DB_NAME,
    multipleStatements: true
};

async function recreateDb() {
    console.log("Recreating DB from schema.sql...");
    let conn;
    try {
        // Create connection without database to check if it exists or create it
        conn = await mysql.createConnection({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASS,
            multipleStatements: true
        });

        console.log(`Creating database ${dbConfig.database} if not exists...`);
        await conn.query(`CREATE DATABASE IF NOT EXISTS \`${dbConfig.database}\``);
        await conn.query(`USE \`${dbConfig.database}\``);

        const schemaPath = path.join(__dirname, "../schema.sql");
        const schemaSql = fs.readFileSync(schemaPath, "utf8");

        console.log("Executing schema SQL...");
        await conn.query(schemaSql);

        console.log("✅ Database recreated successfully.");

    } catch (err) {
        console.error("❌ DB Recreation Error:", err);
    } finally {
        if (conn) await conn.end();
    }
}

recreateDb();
