require('dotenv').config();
const { db } = require('./config/db');

const fs = require('fs');

async function checkSchema() {
    try {
        const [rows] = await db.query('DESCRIBE players');
        fs.writeFileSync('schema_output.json', JSON.stringify(rows, null, 2));
        console.log('Schema written to schema_output.json');
        process.exit(0);
    } catch (error) {
        console.error(error);
        process.exit(1);
    }
}

checkSchema();
