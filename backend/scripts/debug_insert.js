const mysql = require("mysql2/promise");
const path = require("path");
const bcrypt = require("bcryptjs");
require("dotenv").config({ path: path.join(__dirname, "../.env") });

(async () => {
    let conn;
    try {
        conn = await mysql.createConnection({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASS,
            database: process.env.DB_NAME
        });

        const adminPhone = "+91234567890";
        const adminPass = "admin";
        const hash = await bcrypt.hash(adminPass, 12);

        console.log("1. Trying insert WITHOUT is_admin...");
        try {
            const [res1] = await conn.query(
                "INSERT INTO users (phone_number, password_hash, created_at) VALUES (?, ?, NOW())",
                [adminPhone, hash]
            );
            console.log("   Success! Insert ID:", res1.insertId);

            console.log("2. Trying UPDATE is_admin = 1...");
            await conn.query("UPDATE users SET is_admin = 1 WHERE id = ?", [res1.insertId]);
            console.log("   Success! Updated is_admin.");

        } catch (e1) {
            console.error("   Failed insert 1:", e1.message);
        }

        // Clean up
        // await conn.query("DELETE FROM users WHERE phone_number = ?", [adminPhone]);

    } catch (e) {
        console.error("Global Error:", e);
    } finally {
        if (conn) await conn.end();
    }
})();
