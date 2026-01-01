const { db } = require("./config/db");
const fs = require('fs');

async function checkSchema() {
    try {
        const results = {};
        const tables = ['matches', 'match_innings', 'player_match_stats', 'ball_by_ball'];
        for (const table of tables) {
            try {
                const [columns] = await db.query(`DESCRIBE ${table}`);
                results[table] = columns;
            } catch (err) {
                results[table] = { error: err.message };
            }
        }
        fs.writeFileSync('full_schema_check.json', JSON.stringify(results, null, 2));
        console.log("Results written to full_schema_check.json");
        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

checkSchema();
