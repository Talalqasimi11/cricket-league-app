const db = require("../config/db");

/**
 * 📌 Get player stats by match
 */
const getPlayerStatsByMatch = async (req, res) => {
  const { match_id } = req.params;

  try {
    const [rows] = await db.query(
      `SELECT pms.*, p.player_name, p.team_id, t.team_name
       FROM player_match_stats pms
       JOIN players p ON pms.player_id = p.id
       LEFT JOIN teams t ON p.team_id = t.id
       WHERE pms.match_id = ?
       ORDER BY pms.runs DESC, pms.wickets DESC`,
      [match_id]
    );

    res.json({ success: true, data: rows });
  } catch (err) {
    console.error("❌ Error in getPlayerStatsByMatch:", err);
    res.status(500).json({ success: false, error: "Server error" });
  }
};

/**
 * 📌 Get player stats by tournament (aggregated across all matches in tournament)
 */
const getPlayerStatsByTournament = async (req, res) => {
  const { tournament_id } = req.params;

  try {
    const [rows] = await db.query(
      `SELECT 
         p.id AS player_id,
         p.player_name,
         p.team_id,
         t.team_name,
         COUNT(DISTINCT pms.match_id) AS matches_played,
         SUM(pms.runs) AS total_runs,
         SUM(pms.balls_faced) AS total_balls_faced,
         SUM(pms.fours) AS total_fours,
         SUM(pms.sixes) AS total_sixes,
         SUM(pms.balls_bowled) AS total_balls_bowled,
         SUM(pms.runs_conceded) AS total_runs_conceded,
         SUM(pms.wickets) AS total_wickets,
         SUM(pms.catches) AS total_catches,
         SUM(pms.runouts) AS total_runouts,
         ROUND(
           CASE 
             WHEN SUM(pms.balls_faced) > 0 
             THEN (SUM(pms.runs) * 100.0) / SUM(pms.balls_faced) 
             ELSE 0 
           END, 
           2
         ) AS strike_rate,
         ROUND(
           CASE 
             WHEN SUM(pms.balls_bowled) > 0 
             THEN (SUM(pms.runs_conceded) * 6.0) / SUM(pms.balls_bowled) 
             ELSE 0 
           END, 
           2
         ) AS economy_rate
       FROM player_match_stats pms
       JOIN players p ON pms.player_id = p.id
       LEFT JOIN teams t ON p.team_id = t.id
       JOIN matches m ON pms.match_id = m.id
       WHERE m.tournament_id = ?
       GROUP BY p.id, p.player_name, p.team_id, t.team_name
       ORDER BY total_runs DESC, total_wickets DESC`,
      [tournament_id]
    );

    res.json({ success: true, data: rows });
  } catch (err) {
    console.error("❌ Error in getPlayerStatsByTournament:", err);
    res.status(500).json({ success: false, error: "Server error" });
  }
};

module.exports = {
  getPlayerStatsByMatch,
  getPlayerStatsByTournament,
};

