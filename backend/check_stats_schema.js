require('dotenv').config();
const { db } = require('./config/db');
const fs = require('fs');

async function checkSchema() {
    try {
        const [rows] = await db.query('DESCRIBE player_match_stats');
        fs.writeFileSync('schema_stats_output.json', JSON.stringify(rows, null, 2));
        console.log('Schema written to schema_stats_output.json');
        process.exit(0);
    } catch (error) {
        console.error(error);
        process.exit(1);
    }
}

checkSchema();
