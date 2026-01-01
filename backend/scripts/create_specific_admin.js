
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

        console.log("Connected to DB");
        const phone = "+92123456789";
        const passwordRaw = "admin";
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(passwordRaw, salt);

        const [rows] = await conn.query("SELECT id FROM users WHERE phone_number = ?", [phone]);
        if (rows.length > 0) {
            console.log("Admin user exists, updating...");
            await conn.query("UPDATE users SET password_hash = ?, is_admin = 1 WHERE id = ?", [hashedPassword, rows[0].id]);
        } else {
            console.log("Creating admin user...");
            await conn.query("INSERT INTO users (phone_number, password_hash, is_admin) VALUES (?, ?, 1)", [phone, hashedPassword]);
        }

        console.log("SUCCESS: Admin user ready (+92123456789 / admin)");
        await conn.end();
    } catch (e) {
        console.error("ERROR:", e);
    }
})();
