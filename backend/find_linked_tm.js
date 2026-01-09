const { db } = require('./config/db');

async function findLinkedTm() {
    try {
        const matchIds = [105, 107];
        // Find tournament_matches that point to these match_ids
        const [rows] = await db.query(`SELECT id, status, match_id FROM tournament_matches WHERE match_id IN (?)`, [matchIds]);
        console.log('Linked Tournament Matches:', JSON.stringify(rows, null, 2));

        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

findLinkedTm();
