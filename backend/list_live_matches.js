const { db } = require('./config/db');

async function listLiveMatches() {
  try {
    const [rows] = await db.query("SELECT id, status, team1_id, team2_id, match_datetime, tournament_id FROM matches WHERE status = 'live'");
    console.log('Live Matches in `matches` table:', JSON.stringify(rows, null, 2));

    const [tmRows] = await db.query("SELECT id, status, match_id, tournament_id FROM tournament_matches WHERE status = 'live'");
    console.log('Live Matches in `tournament_matches` table:', JSON.stringify(tmRows, null, 2));
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

listLiveMatches();
