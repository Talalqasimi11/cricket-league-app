const mysql = require("mysql2/promise");
const bcrypt = require("bcryptjs");
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

        const adminPhone = "+91234567890";
        const adminPass = "admin";
        const hash = await bcrypt.hash(adminPass, 12);

        console.log("Attempting to insert admin...");

        const [result] = await conn.query(
            "INSERT INTO users (phone_number, password_hash, is_admin, created_at) VALUES (?, ?, ?, NOW())",
            [adminPhone, hash, 1]
        );

        console.log(`✅ Admin created with ID: ${result.insertId}`);
        await conn.end();
        process.exit(0);
    } catch (e) {
        console.error("❌ Failed:", e);
        process.exit(1);
    }
})();
