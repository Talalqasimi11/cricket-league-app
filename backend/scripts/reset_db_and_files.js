const mysql = require("mysql2/promise");
const fs = require("fs");
const path = require("path");
const bcrypt = require("bcryptjs");
require("dotenv").config({ path: path.join(__dirname, "../.env") });

const dbConfig = {
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    database: process.env.DB_NAME,
    multipleStatements: true
};

async function resetDb() {
    console.log("Starting DB Reset...");
    let conn;
    try {
        conn = await mysql.createConnection(dbConfig);
    } catch (e) {
        console.error("Connection failed. Check .env", e);
        process.exit(1);
    }

    try {
        // 1. Get all tables
        const [rows] = await conn.query("SHOW TABLES");
        const tables = rows.map(r => Object.values(r)[0]);

        if (tables.length === 0) {
            console.log("No tables found.");
        } else {
            // 2. Disable FK checks
            await conn.query("SET FOREIGN_KEY_CHECKS = 0");

            // 3. Truncate each table
            for (const table of tables) {
                if (table === 'schema_migrations') continue;
                console.log(`Truncating ${table}...`);
                await conn.query(`TRUNCATE TABLE \`${table}\``);
            }

            // 4. Re-enable FK checks
            await conn.query("SET FOREIGN_KEY_CHECKS = 1");
            console.log("All tables truncated.");
        }

        // 5. Create Admin User
        const adminPhone = "+91234567890";
        const adminPass = "admin";

        console.log("Hashing password...");
        const hash = await bcrypt.hash(adminPass, 12);

        console.log("Creating default admin...");

        try {
            await conn.query(
                "INSERT INTO users (phone_number, password_hash, is_admin) VALUES (?, ?, 1)",
                [adminPhone, hash]
            );
            console.log(`✅ Admin created: Phone=${adminPhone}, Pass=${adminPass}`);
        } catch (err) {
            console.error("Failed to insert admin. Trying fallback...", err.message);
            // Fallback: try without is_admin
            try {
                await conn.query(
                    "INSERT INTO users (phone_number, password_hash) VALUES (?, ?)",
                    [adminPhone, hash]
                );
                console.log(`✅ Admin created (without is_admin flag): Phone=${adminPhone}, Pass=${adminPass}`);
                // Try to update it separately just in case
                await conn.query("UPDATE users SET is_admin = 1 WHERE phone_number = ?", [adminPhone]);
            } catch (e2) {
                console.error("Fallback failed:", e2.message);
            }
        }

    } catch (err) {
        console.error("DB Reset Error:", err);
    } finally {
        if (conn) await conn.end();
    }
}

async function clearUploads() {
    console.log("Clearing uploads...");
    const uploadsDir = path.join(__dirname, "../uploads");
    if (fs.existsSync(uploadsDir)) {
        const files = fs.readdirSync(uploadsDir);
        for (const file of files) {
            if (file === '.gitkeep') continue;
            const curPath = path.join(uploadsDir, file);
            try {
                if (fs.lstatSync(curPath).isDirectory()) {
                    fs.rmSync(curPath, { recursive: true, force: true });
                } else {
                    fs.unlinkSync(curPath);
                }
            } catch (e) {
                console.error(`Failed to delete ${file}:`, e.message);
            }
        }
        console.log("Uploads cleared.");
    } else {
        console.log("Uploads directory not found.");
    }
}

(async () => {
    await resetDb();
    await clearUploads();
    process.exit(0);
})();
