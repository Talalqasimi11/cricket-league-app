const { db } = require('./config/db');

async function describeTable() {
    try {
        const [rows] = await db.query("SHOW COLUMNS FROM tournament_matches LIKE 'status'");
        console.log(rows);
        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

describeTable();
