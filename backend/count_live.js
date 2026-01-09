const { db } = require('./config/db');

async function countLiveMatches() {
    try {
        const [mRows] = await db.query("SELECT COUNT(*) as count FROM matches WHERE status = 'live'");
        console.log('Live matches in `matches`: ', mRows[0].count);

        const [tmRows] = await db.query("SELECT COUNT(*) as count FROM tournament_matches WHERE status = 'live'");
        console.log('Live matches in `tournament_matches`: ', tmRows[0].count);

        // Also list IDs if count > 0
        if (mRows[0].count > 0) {
            const [ids] = await db.query("SELECT id FROM matches WHERE status = 'live'");
            console.log('IDs in matches:', ids);
        }
        if (tmRows[0].count > 0) {
            const [ids] = await db.query("SELECT id FROM tournament_matches WHERE status = 'live'");
            console.log('IDs in tournament_matches:', ids);
        }

        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

countLiveMatches();
