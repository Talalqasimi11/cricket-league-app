
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

        const phone = "9999999999";
        const password = "password123";
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // Check if exists
        const [rows] = await conn.query("SELECT id FROM users WHERE phone_number = ?", [phone]);
        if (rows.length > 0) {
            console.log("User already exists, updating password...");
            await conn.query("UPDATE users SET password_hash = ? WHERE id = ?", [hashedPassword, rows[0].id]);
        } else {
            console.log("Creating new user...");
            await conn.query("INSERT INTO users (phone_number, password_hash, user_name) VALUES (?, ?, ?)", [phone, hashedPassword, "TestUser"]);
        }

        console.log("User ready: 9999999999 / password123");
        await conn.end();
    } catch (e) {
        console.error("Error:", e);
    }
})();
