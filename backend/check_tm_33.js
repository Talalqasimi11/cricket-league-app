const { db } = require('./config/db');

async function checkTournamentMatches() {
    try {
        const [rows] = await db.query('SELECT * FROM tournament_matches WHERE id = 33 OR match_id = 33');
        console.log('--- RESULT START ---');
        console.log(JSON.stringify(rows, null, 2));
        console.log('--- RESULT END ---');
        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

checkTournamentMatches();
