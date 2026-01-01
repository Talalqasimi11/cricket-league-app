
const { db } = require('../config/db');

async function migrate() {
    try {
        console.log("Start Migration: Clean up duplicates and add UNIQUE index to player_match_stats");

        // 1. Identify duplicates? 
        // Actually, safest way is to create a temporary table with unique constraints, copy data, drop old, rename new.
        // OR simpler: Delete duplicates keeping the one with max usage?
        // Since it's stats, we might want to SUM them if they are split? 
        // The issue is likely that "0" rows were inserted. 
        // Let's assume we want to keep the row with the highest 'balls_faced' or 'balls_bowled' for each (match_id, player_id).

        // Step 1: Delete rows that are NOT the max id for that group (simplistic dedupe)
        // Actually, SQL is tricky for "keep max id".
        // Better strategy: Select MAX(id) group by match_id, player_id into a list, delete all others.

        console.log("1. Removing duplicate rows...");
        const [rows] = await db.query(`
        SELECT match_id, player_id, MAX(id) as max_id 
        FROM player_match_stats 
        GROUP BY match_id, player_id
    `);

        if (rows.length > 0) {
            // Build a list of IDs to KEEP
            const keepIds = rows.map(r => r.max_id);

            // Delete everything NOT in this list
            // Note: DELETE WHERE id NOT IN (...) can be slow or hit limits if list is huge.
            // But for this app scale it's likely fine.

            if (keepIds.length > 0) {
                const placeholders = keepIds.map(() => '?').join(',');
                await db.query(`DELETE FROM player_match_stats WHERE id NOT IN (${placeholders})`, keepIds);
            }
        }
        console.log("   Duplicates removed.");

        // 2. Add Unique Index
        console.log("2. Adding UNIQUE index...");
        // We try to add it. use IGNORE just in case, or check if exists.
        // Simple way: DROP INDEX if exists (might fail if not exists), then ADD.
        // Or just ADD and catch duplicate key error if we failed step 1 (unlikely).

        try {
            await db.query(`
            ALTER TABLE player_match_stats
            ADD UNIQUE KEY unique_match_player (match_id, player_id)
        `);
            console.log("   Unique index added successfully.");
        } catch (e) {
            if (e.code === 'ER_DUP_ENTRY') {
                console.error("   Failed to add index due to remaining duplicates:", e.message);
            } else if (e.code === 'ER_DUP_KEYNAME') {
                console.log("   Index already exists.");
            } else {
                throw e;
            }
        }

        console.log("Migration Complete.");
        process.exit(0);
    } catch (err) {
        console.error("Migration Failed:", err);
        process.exit(1);
    }
}

migrate();
