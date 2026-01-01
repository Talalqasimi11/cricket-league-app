const { db } = require('../config/db');

async function migrate() {
    console.log('🚀 Starting lineup columns migration...');
    try {
        // 1. Add lineup columns to matches table
        await db.query(`
      ALTER TABLE matches 
      ADD COLUMN team1_lineup TEXT DEFAULT NULL,
      ADD COLUMN team2_lineup TEXT DEFAULT NULL
    `);
        console.log('✅ Lineup columns added to matches table.');

        // 2. Add lineup columns to tournament_matches table
        await db.query(`
      ALTER TABLE tournament_matches 
      ADD COLUMN team1_lineup TEXT DEFAULT NULL,
      ADD COLUMN team2_lineup TEXT DEFAULT NULL
    `);
        console.log('✅ Lineup columns added to tournament_matches table.');

        process.exit(0);
    } catch (err) {
        if (err.code === 'ER_DUP_COLUMN_NAME') {
            console.log('ℹ️ Lineup columns already exist.');
            process.exit(0);
        }
        console.error('❌ Migration failed:', err);
        process.exit(1);
    }
}

migrate();
