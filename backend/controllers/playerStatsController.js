const db = require("../config/db");

/**
 * 📌 Get Top Run Scorers (for a tournament or overall)
 */
const getTopRunScorers = async (req, res) => {
  const { tournament_id } = req.params;

  try {
    const [rows] = await db.query(
      `SELECT p.id AS player_id, p.player_name, 
              SUM(ps.runs) AS total_runs,
              SUM(ps.balls_faced) AS balls,
              ROUND(SUM(ps.runs) / SUM(ps.balls_faced) * 100, 2) AS strike_rate
       FROM player_match_stats ps
       JOIN players p ON ps.player_id = p.id
       JOIN matches m ON ps.match_id = m.id
       WHERE m.tournament_id = ?
       GROUP BY p.id
       ORDER BY total_runs DESC
       LIMIT 10`,
      [tournament_id]
    );

    res.json(rows);
  } catch (err) {
    console.error("❌ Error in getTopRunScorers:", err);
    res.status(500).json({ error: "Server error" });
  }
};

/**
 * 📌 Get Top Wicket Takers
 */
const getTopWicketTakers = async (req, res) => {
  const { tournament_id } = req.params;

  try {
    const [rows] = await db.query(
      `SELECT p.id AS player_id, p.player_name,
              SUM(ps.wickets) AS total_wickets,
              SUM(ps.balls_bowled) AS balls,
              ROUND(SUM(ps.runs_conceded) / (SUM(ps.wickets) + 0.0001), 2) AS bowling_avg
       FROM player_match_stats ps
       JOIN players p ON ps.player_id = p.id
       JOIN matches m ON ps.match_id = m.id
       WHERE m.tournament_id = ?
       GROUP BY p.id
       ORDER BY total_wickets DESC
       LIMIT 10`,
      [tournament_id]
    );

    res.json(rows);
  } catch (err) {
    console.error("❌ Error in getTopWicketTakers:", err);
    res.status(500).json({ error: "Server error" });
  }
};

/**
 * 📌 Get Player Full Stats in Tournament
 */
const getPlayerStats = async (req, res) => {
  const { tournament_id, player_id } = req.params;

  try {
    const [[stats]] = await db.query(
      `SELECT p.id AS player_id, p.player_name, p.player_role,
              SUM(ps.runs) AS runs,
              SUM(ps.balls_faced) AS balls,
              ROUND(SUM(ps.runs) / (SUM(ps.balls_faced) + 0.0001), 2) AS strike_rate,
              SUM(ps.hundreds) AS hundreds,
              SUM(ps.fifties) AS fifties,
              SUM(ps.wickets) AS wickets,
              SUM(ps.balls_bowled) AS balls_bowled,
              SUM(ps.runs_conceded) AS runs_conceded,
              ROUND(SUM(ps.runs_conceded) / (SUM(ps.wickets) + 0.0001), 2) AS bowling_avg
       FROM player_match_stats ps
       JOIN players p ON ps.player_id = p.id
       JOIN matches m ON ps.match_id = m.id
       WHERE m.tournament_id = ? AND ps.player_id = ?
       GROUP BY p.id`,
      [tournament_id, player_id]
    );

    if (!stats) return res.status(404).json({ error: "Player stats not found" });

    res.json(stats);
  } catch (err) {
    console.error("❌ Error in getPlayerStats:", err);
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = { getTopRunScorers, getTopWicketTakers, getPlayerStats };
