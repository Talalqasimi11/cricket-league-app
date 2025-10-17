const db = require("../config/db");

/**
 * 📌 Get complete match scorecard (after match)
 */
const getMatchScorecard = async (req, res) => {
  const match_id = Number(req.params.match_id);
  
  if (!match_id || isNaN(match_id)) {
    return res.status(400).json({ error: "Invalid match_id" });
  }

  try {
    // 1️⃣ Get match info
    const [match] = await db.query(
      `SELECT m.id, m.team1_id, t1.team_name AS team1_name,
              m.team2_id, t2.team_name AS team2_name,
              m.overs, m.status, m.winner_team_id,
              tw.team_name AS winner_team_name
       FROM matches m
       LEFT JOIN teams t1 ON m.team1_id = t1.id
       LEFT JOIN teams t2 ON m.team2_id = t2.id
       LEFT JOIN teams tw ON m.winner_team_id = tw.id
       WHERE m.id = ?`,
      [match_id]
    );

    if (match.length === 0) return res.status(404).json({ error: "Match not found" });
    const matchInfo = match[0];

    // 2️⃣ Get innings info
    const [innings] = await db.query(
      `SELECT mi.id, mi.inning_number, mi.batting_team_id, bt.team_name AS batting_team_name,
              mi.bowling_team_id, blt.team_name AS bowling_team_name,
              mi.runs, mi.wickets, mi.overs
       FROM match_innings mi
       LEFT JOIN teams bt ON mi.batting_team_id = bt.id
       LEFT JOIN teams blt ON mi.bowling_team_id = blt.id
       WHERE mi.match_id = ?
       ORDER BY mi.inning_number ASC`,
      [match_id]
    );

    // 3️⃣ Get batting stats per innings
    const [battingStats] = await db.query(
      `SELECT pms.match_id, pms.player_id, p.player_name, pms.runs, pms.balls_faced, pms.fours, pms.sixes
       FROM player_match_stats pms
       JOIN players p ON p.id = pms.player_id
       WHERE pms.match_id = ?`,
      [match_id]
    );

    // 4️⃣ Get bowling stats per innings
    const [bowlingStats] = await db.query(
      `SELECT pms.match_id, pms.player_id, p.player_name, pms.balls_bowled, pms.runs_conceded, pms.wickets
       FROM player_match_stats pms
       JOIN players p ON p.id = pms.player_id
       WHERE pms.match_id = ?`,
      [match_id]
    );

    // 5️⃣ Organize scorecard
    const scorecard = innings.map((inn) => {
      // Filter batting and bowling stats by innings teams for accuracy
      const batting = battingStats.filter((b) => Number(b.match_id) === match_id && b.player_id);
      const bowling = bowlingStats.filter((b) => Number(b.match_id) === match_id && b.player_id);
      return {
        inning_number: inn.inning_number,
        batting_team: inn.batting_team_name,
        bowling_team: inn.bowling_team_name,
        runs: inn.runs,
        wickets: inn.wickets,
        overs: inn.overs,
        batting: batting,
        bowling: bowling,
      };
    });

    res.json({
      match: {
        ...matchInfo,
        winner_team_id: matchInfo.winner_team_id || null,
        winner_team_name: matchInfo.winner_team_name || null,
      },
      scorecard,
    });
  } catch (err) {
    console.error("❌ Error in getMatchScorecard:", err);
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = { getMatchScorecard };
