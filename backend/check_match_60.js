const { db } = require('./config/db');

async function checkMatch() {
    try {
        const [matches] = await db.query("SELECT * FROM matches WHERE id = 60");
        console.log("Match 60:", matches[0]);

        const [innings] = await db.query("SELECT * FROM match_innings WHERE match_id = 60");
        console.log("Innings for Match 60:", innings);

        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}

checkMatch();
