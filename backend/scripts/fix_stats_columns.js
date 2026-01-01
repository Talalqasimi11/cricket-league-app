const { db } = require("./config/db");

async function fixStatsColumns() {
    try {
        console.log("🚀 Starting database schema fix...");

        // 1. Add missing columns to player_match_stats
        const [columns] = await db.query("DESCRIBE player_match_stats");
        const columnNames = columns.map(c => c.Field);

        if (!columnNames.includes('maiden_overs')) {
            console.log("➕ Adding 'maiden_overs' to 'player_match_stats'...");
            await db.query("ALTER TABLE player_match_stats ADD COLUMN maiden_overs INT DEFAULT 0 AFTER wickets");
        } else {
            console.log("✅ 'maiden_overs' already exists.");
        }

        if (!columnNames.includes('is_out')) {
            console.log("➕ Adding 'is_out' to 'player_match_stats'...");
            await db.query("ALTER TABLE player_match_stats ADD COLUMN is_out TINYINT(1) DEFAULT 0 AFTER sixes");
        } else {
            console.log("✅ 'is_out' already exists.");
        }

        console.log("✅ Database schema fix completed successfully!");
        process.exit(0);
    } catch (err) {
        console.error("❌ Error fixing database schema:", err);
        process.exit(1);
    }
}

fixStatsColumns();
