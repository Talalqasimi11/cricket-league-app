const { db } = require('../config/db');

async function addcolumn() {
    try {
        await db.query(`
      ALTER TABLE match_innings
      ADD COLUMN legal_balls INT DEFAULT 0;
    `);
        console.log("Added legal_balls column to match_innings");
    } catch (err) {
        if (err.code === 'ER_DUP_FIELDNAME') {
            console.log("Column already exists");
        } else {
            console.error("Error adding column:", err);
        }
    }
    process.exit();
}

addcolumn();
