require('dotenv').config({ path: 'backend/.env' });
const { db } = require('./config/db');
const fs = require('fs');

async function checkSchema() {
    try {
        const [rows] = await db.query("DESCRIBE matches");
        console.log(JSON.stringify(rows, null, 2));
        fs.writeFileSync('matches_schema.json', JSON.stringify(rows, null, 2));
        process.exit(0);
    } catch (error) {
        console.error(error);
        process.exit(1);
    }
}

checkSchema();
