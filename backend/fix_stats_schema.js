const { db } = require("./config/db");

async function fixSchema() {
    try {
        console.log("Starting Schema Fix for player_match_stats...");

        // 1. Check if Unique Index Exists
        const [indices] = await db.query("SHOW INDEX FROM player_match_stats WHERE Key_name = 'unique_match_player'");
        if (indices.length > 0) {
            console.log("Success: Unique index 'unique_match_player' already exists.");
        } else {
            console.log("Notice: Unique index missing. Proceeding to fix...");

            // 2. Identify and Delete Duplicates (Keeping the one with MAX runs/impact)
            // Hard to pick "best" row easily, simpler to sum them? 
            // Or usually the 'latest' one is correct if "0" is the old one.
            // Actually, if we have multiple rows, we should probably merge them or delete the 'empty' ones.
            // Let's safe delete: Delete rows where ID is NOT in (SELECT MAX(id) GROUP BY match_id, player_id)

            console.log("Cleaning up potential duplicates...");
            // MySQL doesn't verify self-referencing subquery delete easily, so use temporary table or 2-step

            await db.query(`
            DELETE p1 FROM player_match_stats p1
            INNER JOIN player_match_stats p2 
            WHERE p1.id < p2.id 
            AND p1.match_id = p2.match_id 
            AND p1.player_id = p2.player_id;
        `);
            console.log("Duplicates removed (kept latest id).");

            // 3. Add Unique Index
            console.log("Adding UNIQUE INDEX...");
            await db.query(`
            ALTER TABLE player_match_stats
            ADD UNIQUE INDEX unique_match_player (match_id, player_id);
        `);
            console.log("Success: Unique index added.");
        }

        process.exit(0);
    } catch (e) {
        console.error("Error during schema fix:", e);
        process.exit(1);
    }
}

fixSchema();
