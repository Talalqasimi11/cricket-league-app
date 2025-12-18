require('dotenv').config();
const { db } = require('../config/db');

async function migrate() {
    try {
        console.log('Adding is_temporary column to players table...');
        await db.query(`
      ALTER TABLE players 
      ADD COLUMN is_temporary BOOLEAN DEFAULT FALSE
    `);
        console.log('✅ Migration successful');
        process.exit(0);
    } catch (error) {
        if (error.code === 'ER_DUP_FIELDNAME') {
            console.log('⚠️ Column already exists');
            process.exit(0);
        }
        console.error('❌ Migration failed:', error);
        process.exit(1);
    }
}

migrate();
