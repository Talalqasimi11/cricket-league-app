const pool = require("../config/db");

/**
 * 📌 Get live score of a match (for viewers)
 */
const getLiveScoreViewer = async (req, res) => {
  const { match_id } = req.params;

  try {
    // Innings info
    const [innings] = await pool.query(
      `SELECT mi.id, mi.inning_number, mi.batting_team_id, mi.bowling_team_id, 
              mi.runs, mi.wickets, mi.overs,
              bt.team_name AS batting_team_name,
              blt.team_name AS bowling_team_name,
              mi.status
       FROM match_innings mi
       LEFT JOIN teams bt ON mi.batting_team_id = bt.id
       LEFT JOIN teams blt ON mi.bowling_team_id = blt.id
       WHERE mi.match_id = ?
       ORDER BY mi.inning_number ASC`,
      [match_id]
    );

    // Ball-by-ball info
    const [balls] = await pool.query(
      `SELECT b.id, b.over_number, b.ball_number, b.runs, b.extras, b.wicket_type,
              bats.player_name AS batsman_name,
              bowl.player_name AS bowler_name,
              outp.player_name AS out_player_name
       FROM ball_by_ball b
       LEFT JOIN players bats ON b.batsman_id = bats.id
       LEFT JOIN players bowl ON b.bowler_id = bowl.id
       LEFT JOIN players outp ON b.out_player_id = outp.id
       WHERE b.match_id = ?
       ORDER BY b.id ASC`,
      [match_id]
    );

    // Player stats
    const [players] = await pool.query(
      `SELECT pms.player_id, p.player_name, p.player_role,
              pms.runs, pms.balls_faced, pms.wickets, pms.balls_bowled, pms.runs_conceded
       FROM player_match_stats pms
       JOIN players p ON pms.player_id = p.id
       WHERE pms.match_id = ?`,
      [match_id]
    );

    res.json({ innings, balls, players });
  } catch (err) {
    console.error("❌ Error in getLiveScoreViewer:", err);
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = { getLiveScoreViewer };
