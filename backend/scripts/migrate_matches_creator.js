const { db } = require('../config/db');

async function migrate() {
    console.log('🚀 Starting matches creator_id migration...');
    try {
        // 1. Add creator_id column
        await db.query(`
      ALTER TABLE matches 
      ADD COLUMN creator_id INT DEFAULT NULL 
      AFTER winner_team_id
    `);
        console.log('✅ Column creator_id added to matches table.');

        // 2. Add foreign key constraint
        await db.query(`
      ALTER TABLE matches 
      ADD CONSTRAINT fk_matches_creator 
      FOREIGN KEY (creator_id) REFERENCES users(id) ON DELETE SET NULL
    `);
        console.log('✅ Foreign key constraint fk_matches_creator added.');

        process.exit(0);
    } catch (err) {
        if (err.code === 'ER_DUP_COLUMN_NAME') {
            console.log('ℹ️ Column creator_id already exists.');
            process.exit(0);
        }
        console.error('❌ Migration failed:', err);
        process.exit(1);
    }
}

migrate();
