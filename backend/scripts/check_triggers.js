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

        console.log("Connected to DB:", process.env.DB_NAME);

        const [triggers] = await conn.query("SHOW TRIGGERS LIKE 'users'");
        if (triggers.length === 0) {
            console.log("No triggers found on users table.");
        } else {
            console.log("Triggers found:");
            triggers.forEach(t => {
                console.log(`- Trigger: ${t.Trigger}`);
                console.log(`  Event: ${t.Event}`);
                console.log(`  Statement: ${t.Statement}`);
            });
        }

        await conn.end();
    } catch (e) {
        console.error("Error:", e);
    }
})();
