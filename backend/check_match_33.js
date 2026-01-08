const { db } = require('./config/db');

async function checkMatch() {
    try {
        const [rows] = await db.query('SELECT * FROM matches WHERE id = 33');
        if (rows.length === 0) {
            console.log('Match 33 NOT FOUND');
        } else {
            console.log('Match 33 FOUND:', rows[0]);
        }
        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

checkMatch();
