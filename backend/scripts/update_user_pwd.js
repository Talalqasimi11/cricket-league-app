
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

        const id = 2; // based on list_users output
        const passwordRaw = "password123";
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(passwordRaw, salt);

        console.log("Updating password for ID 2...");
        await conn.query("UPDATE users SET password_hash = ? WHERE id = ?", [hashedPassword, id]);

        console.log("SUCCESS");
        await conn.end();
    } catch (e) {
        console.error("ERROR:", e);
    }
})();
