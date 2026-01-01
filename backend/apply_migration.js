const { db } = require("./config/db");

async function migrate() {
    try {
        console.log("Checking for target_score column...");
        const [columns] = await db.query("DESCRIBE matches");
        const hasTargetScore = columns.some(c => c.Field === 'target_score');

        if (hasTargetScore) {
            console.log("target_score column already exists.");
        } else {
            console.log("Adding target_score column to matches table...");
            await db.query("ALTER TABLE matches ADD COLUMN target_score INT DEFAULT NULL");
            console.log("Successfully added target_score column.");
        }
        process.exit(0);
    } catch (err) {
        console.error("Migration failed:", err.message);
        process.exit(1);
    }
}

migrate();
