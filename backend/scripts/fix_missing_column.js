const { db } = require('../config/db');

async function fixSchema() {
    try {
        console.log("Checking tournament_matches columns...");
        const [cols] = await db.query("SHOW COLUMNS FROM tournament_matches LIKE 'match_id'");

        if (cols.length > 0) {
            console.log("Column 'match_id' already exists.");
        } else {
            console.log("Adding 'match_id' column...");
            await db.query("ALTER TABLE tournament_matches ADD COLUMN match_id INT NULL");
            console.log("Column added successfully.");
        }
        process.exit(0);
    } catch (error) {
        console.error("Error updating schema:", error);
        process.exit(1);
    }
}

fixSchema();
