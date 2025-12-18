const { db } = require('../config/db');

async function checkPlayers() {
    try {
        const [teams] = await db.query("SELECT id, team_name FROM teams");
        console.log(`Found ${teams.length} teams.`);

        for (const team of teams) {
            const [players] = await db.query("SELECT COUNT(*) as count FROM players WHERE team_id = ?", [team.id]);
            console.log(`Team '${team.team_name}' (ID: ${team.id}) has ${players[0].count} players.`);

            if (players[0].count > 0) {
                const [somePlayers] = await db.query("SELECT id, player_name FROM players WHERE team_id = ? LIMIT 3", [team.id]);
                console.log("  Sample players:", somePlayers);
            }
        }
        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

checkPlayers();
