const { db } = require('./config/db');

async function checkStatus() {
    try {
        const [rows] = await db.query('SELECT id, status, parent_match_id FROM tournament_matches WHERE id = 33');
        console.log(rows);
        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

checkStatus();
