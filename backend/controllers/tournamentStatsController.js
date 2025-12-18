const { db } = require("../config/db");
const { logDatabaseError } = require("../utils/safeLogger");

// ==========================================
// 📊 TOURNAMENT STATS CONTROLLER
// ==========================================

/**
 * 🏏 Get Top Scorers (Orange Cap Contenders)
 */
const getTopScorers = async (req, res) => {
  const { tournamentId } = req.params;

  try {
    const sql = `
      SELECT 
        p.id AS player_id,
        p.player_name,
        p.player_image_url,
        t.team_name,
        SUM(pms.runs) AS total_runs,
        SUM(pms.balls_faced) AS balls_faced,
        MAX(pms.runs) AS highest_score,
        COUNT(DISTINCT pms.match_id) AS matches_played,
        CASE 
          WHEN SUM(pms.balls_faced) > 0 
          THEN ROUND((SUM(pms.runs) / SUM(pms.balls_faced)) * 100, 2) 
          ELSE 0.00 
        END AS strike_rate
      FROM player_match_stats pms
      JOIN players p ON pms.player_id = p.id
      JOIN matches m ON pms.match_id = m.id
      LEFT JOIN teams t ON p.team_id = t.id
      WHERE m.tournament_id = ?
      GROUP BY p.id, p.player_name, t.team_name
      ORDER BY total_runs DESC
      LIMIT 10
    `;

    const [rows] = await db.query(sql, [tournamentId]);
    res.json({ success: true, data: rows });

  } catch (err) {
    logDatabaseError(req.log, "getTopScorers", err, { tournamentId });
    res.status(500).json({ success: false, error: "Server error retrieving top scorers" });
  }
};

/**
 * 🎯 Get Top Wicket Takers (Purple Cap Contenders)
 */
const getTopWicketTakers = async (req, res) => {
  const { tournamentId } = req.params;

  try {
    const sql = `
      SELECT 
        p.id AS player_id,
        p.player_name,
        p.player_image_url,
        t.team_name,
        SUM(pms.wickets) AS total_wickets,
        SUM(pms.runs_conceded) AS runs_conceded,
        SUM(pms.balls_bowled) AS balls_bowled,
        COUNT(DISTINCT pms.match_id) AS matches_played,
        CASE 
          WHEN SUM(pms.balls_bowled) > 0 
          THEN ROUND((SUM(pms.runs_conceded) / SUM(pms.balls_bowled)) * 6, 2) 
          ELSE 0.00 
        END AS economy_rate
      FROM player_match_stats pms
      JOIN players p ON pms.player_id = p.id
      JOIN matches m ON pms.match_id = m.id
      LEFT JOIN teams t ON p.team_id = t.id
      WHERE m.tournament_id = ?
      GROUP BY p.id, p.player_name, t.team_name
      ORDER BY total_wickets DESC
      LIMIT 10
    `;

    const [rows] = await db.query(sql, [tournamentId]);
    res.json({ success: true, data: rows });

  } catch (err) {
    logDatabaseError(req.log, "getTopWicketTakers", err, { tournamentId });
    res.status(500).json({ success: false, error: "Server error retrieving top wicket takers" });
  }
};

/**
 * 💥 Get Sixes Leaderboard
 */
const getSixesLeaderboard = async (req, res) => {
  const { tournamentId } = req.params;

  try {
    const sql = `
      SELECT 
        p.id AS player_id,
        p.player_name,
        p.player_image_url,
        t.team_name,
        SUM(pms.sixes) AS total_sixes,
        SUM(pms.runs) AS total_runs,
        COUNT(DISTINCT pms.match_id) AS matches_played
      FROM player_match_stats pms
      JOIN players p ON pms.player_id = p.id
      JOIN matches m ON pms.match_id = m.id
      LEFT JOIN teams t ON p.team_id = t.id
      WHERE m.tournament_id = ?
      GROUP BY p.id, p.player_name, t.team_name
      ORDER BY total_sixes DESC
      LIMIT 10
    `;

    const [rows] = await db.query(sql, [tournamentId]);
    res.json({ success: true, data: rows });

  } catch (err) {
    logDatabaseError(req.log, "getSixesLeaderboard", err, { tournamentId });
    res.status(500).json({ success: false, error: "Server error retrieving sixes leaderboard" });
  }
};

/**
 * 📈 Get Tournament Summary Stats
 */
const getTournamentSummary = async (req, res) => {
  const { tournamentId } = req.params;

  try {
    const sql = `
      SELECT 
        COUNT(DISTINCT m.id) AS total_matches,
        SUM(pms.runs) AS total_runs,
        SUM(pms.wickets) AS total_wickets,
        SUM(pms.sixes) AS total_sixes,
        SUM(pms.fours) AS total_fours,
        COUNT(DISTINCT CASE WHEN pms.runs >= 50 AND pms.runs < 100 THEN pms.id END) AS total_fifties,
        COUNT(DISTINCT CASE WHEN pms.runs >= 100 THEN pms.id END) AS total_hundreds
      FROM matches m
      LEFT JOIN player_match_stats pms ON m.id = pms.match_id
      WHERE m.tournament_id = ?
    `;

    const [rows] = await db.query(sql, [tournamentId]);
    res.json({ success: true, data: rows[0] });

  } catch (err) {
    logDatabaseError(req.log, "getTournamentSummary", err, { tournamentId });
    res.status(500).json({ success: false, error: "Server error retrieving tournament summary" });
  }
};

module.exports = {
  getTopScorers,
  getTopWicketTakers,
  getSixesLeaderboard,
  getTournamentSummary,
};