const { db } = require("../config/db");

const runMigration = async () => {
    try {
        console.log("Starting schema migration for match_innings...");

        // Add current_striker_id
        try {
            await db.query(`
        ALTER TABLE match_innings 
        ADD COLUMN current_striker_id INT DEFAULT NULL,
        ADD CONSTRAINT fk_mi_striker FOREIGN KEY (current_striker_id) REFERENCES players(id) ON DELETE SET NULL
      `);
            console.log("Added current_striker_id column.");
        } catch (err) {
            if (err.code === 'ER_DUP_FIELDNAME') {
                console.log("current_striker_id already exists.");
            } else {
                throw err;
            }
        }

        // Add current_non_striker_id
        try {
            await db.query(`
        ALTER TABLE match_innings 
        ADD COLUMN current_non_striker_id INT DEFAULT NULL,
        ADD CONSTRAINT fk_mi_non_striker FOREIGN KEY (current_non_striker_id) REFERENCES players(id) ON DELETE SET NULL
      `);
            console.log("Added current_non_striker_id column.");
        } catch (err) {
            if (err.code === 'ER_DUP_FIELDNAME') {
                console.log("current_non_striker_id already exists.");
            } else {
                throw err;
            }
        }

        // Add current_bowler_id
        try {
            await db.query(`
        ALTER TABLE match_innings 
        ADD COLUMN current_bowler_id INT DEFAULT NULL,
        ADD CONSTRAINT fk_mi_bowler FOREIGN KEY (current_bowler_id) REFERENCES players(id) ON DELETE SET NULL
      `);
            console.log("Added current_bowler_id column.");
        } catch (err) {
            if (err.code === 'ER_DUP_FIELDNAME') {
                console.log("current_bowler_id already exists.");
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
