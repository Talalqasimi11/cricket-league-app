const { db } = require('./config/db');

async function listMatches() {
    try {
        const [rows] = await db.query('SELECT id, status FROM matches ORDER BY id DESC LIMIT 20');
        console.log('Matches:', rows);
        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

listMatches();
