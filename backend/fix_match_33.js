const { db } = require('./config/db');

async function fixMatch33() {
    try {
        await db.query("UPDATE tournament_matches SET status = 'planned' WHERE id = 33");
        console.log("Fixed match 33: status set to 'planned'");
        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

fixMatch33();
