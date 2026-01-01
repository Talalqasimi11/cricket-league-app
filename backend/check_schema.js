const { db } = require("./config/db");

async function checkSchema() {
    try {
        console.log("Checking indices for 'player_match_stats'...");
        const [rows] = await db.query("SHOW INDEX FROM player_match_stats");
        console.log(JSON.stringify(rows, null, 2));

        // Also check table structure
        const [cols] = await db.query("DESCRIBE player_match_stats");
        console.log("Columns:", JSON.stringify(cols, null, 2));

        process.exit(0);
    } catch (e) {
        console.error("Error:", e);
        process.exit(1);
    }
}

checkSchema();
