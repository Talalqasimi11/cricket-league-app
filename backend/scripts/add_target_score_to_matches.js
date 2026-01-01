const { db } = require("../config/db");

const runMigration = async () => {
    try {
        console.log("Starting schema migration for matches (target_score)...");

        try {
            await db.query(`
                ALTER TABLE matches 
                ADD COLUMN target_score INT DEFAULT NULL
            `);
            console.log("Added target_score column to matches table.");
        } catch (err) {
            if (err.code === 'ER_DUP_FIELDNAME') {
                console.log("target_score already exists.");
            } else {
                throw err;
            }
        }

        console.log("Migration completed successfully.");
        process.exit(0);
    } catch (err) {
        console.error("Migration failed:", err);
        process.exit(1);
    }
};

runMigration();
