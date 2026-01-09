const { db } = require('./config/db');

async function checkIds() {
    try {
        const ids = [105, 107];
        const [rows] = await db.query(`SELECT id, status, match_id FROM tournament_matches WHERE id IN (?)`, [ids]);
        console.log('Tournament Matches with IDs 105, 107:', JSON.stringify(rows, null, 2));

        const [matches] = await db.query(`SELECT id, status, tournament_id FROM matches WHERE id IN (?)`, [ids]);
        console.log('Matches with IDs 105, 107:', JSON.stringify(matches, null, 2));

        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

checkIds();
