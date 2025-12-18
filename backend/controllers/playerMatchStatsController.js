const { db } = require("../config/db");
const { logDatabaseError } = require("../utils/safeLogger");

// ==========================================
// 🏏 PLAYER MATCH STATISTICS CONTROLLER
// ==========================================

/**
 * 📌 Get Player Stats for a Specific Match
 * Used for Match Scorecards or Post-Match Summary
 */
const getPlayerStatsByMatch = async (req, res) => {
  const { match_id } = req.params;

  try {
    const sql = `
      SELECT 
        pms.id,
        pms.player_id,
        p.player_name,
        p.player_role,
        p.player_image_url,
        p.team_id,
        t.team_name,
        
        -- Batting Stats
        pms.runs,
        pms.balls_faced,
        pms.fours,
        pms.sixes,
        CASE 
          WHEN pms.balls_faced > 0 
          THEN ROUND((pms.runs / pms.balls_faced) * 100, 2) 
          ELSE 0.00 
        END AS strike_rate,
        pms.is_out,
        
        -- Bowling Stats
        pms.overs_bowled,
        pms.balls_bowled,
        pms.maiden_overs,
        pms.runs_conceded,
        pms.wickets,
        CASE 
          WHEN pms.balls_bowled > 0 
          THEN ROUND((pms.runs_conceded / pms.balls_bowled) * 6, 2) 
          ELSE 0.00 
        END AS economy_rate,
        
        -- Fielding Stats
        pms.catches,
        pms.runouts,
        pms.stumpings

      FROM player_match_stats pms
      JOIN players p ON pms.player_id = p.id
      LEFT JOIN teams t ON p.team_id = t.id
      WHERE pms.match_id = ?
      ORDER BY p.team_id, pms.runs DESC
    `;

    const [rows] = await db.query(sql, [match_id]);

    res.json({ 
      success: true, 
      count: rows.length, 
      data: rows 
    });

  } catch (err) {
    logDatabaseError(req.log, "getPlayerStatsByMatch", err, { match_id });
    res.status(500).json({ success: false, error: "Server error retrieving match stats" });
  }
};

/**
 * 📌 Get Aggregated Player Stats by Tournament
 * Used for Leaderboards (Orange Cap, Purple Cap, MVP)
 */
const getPlayerStatsByTournament = async (req, res) => {
  const { tournament_id } = req.params;

  try {
    const sql = `
      SELECT 
        p.id AS player_id,
        p.player_name,
        p.player_role,
        p.player_image_url,
        t.id AS team_id,
        t.team_name,
        t.team_logo_url,
        
        -- General
        COUNT(DISTINCT pms.match_id) AS matches_played,
        
        -- Batting Aggregates
        SUM(pms.runs) AS total_runs,
        SUM(pms.balls_faced) AS total_balls_faced,
        SUM(pms.fours) AS total_fours,
        SUM(pms.sixes) AS total_sixes,
        MAX(pms.runs) AS highest_score,
        SUM(CASE WHEN pms.runs >= 50 AND pms.runs < 100 THEN 1 ELSE 0 END) AS fifties,
        SUM(CASE WHEN pms.runs >= 100 THEN 1 ELSE 0 END) AS hundreds,
        
        -- Batting Strike Rate
        CASE 
          WHEN SUM(pms.balls_faced) > 0 
          THEN ROUND((SUM(pms.runs) / SUM(pms.balls_faced)) * 100, 2) 
          ELSE 0.00 
        END AS batting_strike_rate,

        -- Batting Average (Runs / (Innings - Not Outs))
        -- Simplified here as Runs / Innings where balls faced > 0
        CASE
           WHEN COUNT(CASE WHEN pms.balls_faced > 0 THEN 1 END) > 0
           THEN ROUND(SUM(pms.runs) / COUNT(CASE WHEN pms.balls_faced > 0 THEN 1 END), 2)
           ELSE 0.00
        END AS batting_average,
        
        -- Bowling Aggregates
        SUM(pms.wickets) AS total_wickets,
        SUM(pms.balls_bowled) AS total_balls_bowled,
        SUM(pms.runs_conceded) AS total_runs_conceded,
        SUM(pms.maiden_overs) AS total_maidens,
        
        -- Bowling Economy
        CASE 
          WHEN SUM(pms.balls_bowled) > 0 
          THEN ROUND((SUM(pms.runs_conceded) / SUM(pms.balls_bowled)) * 6, 2) 
          ELSE 0.00 
        END AS economy_rate,

        -- Bowling Average (Runs / Wickets)
        CASE 
          WHEN SUM(pms.wickets) > 0 
          THEN ROUND(SUM(pms.runs_conceded) / SUM(pms.wickets), 2) 
          ELSE 0.00 
        END AS bowling_average,
        
        -- Fielding
        SUM(pms.catches) AS total_catches,
        SUM(pms.runouts) AS total_runouts,
        SUM(pms.stumpings) AS total_stumpings

      FROM player_match_stats pms
      JOIN players p ON pms.player_id = p.id
      LEFT JOIN teams t ON p.team_id = t.id
      JOIN matches m ON pms.match_id = m.id
      WHERE m.tournament_id = ?
      GROUP BY p.id, p.player_name, p.team_id, t.team_name
      ORDER BY total_runs DESC, total_wickets DESC
    `;

    const [rows] = await db.query(sql, [tournament_id]);

    res.json({ 
      success: true, 
      count: rows.length, 
      data: rows 
    });

  } catch (err) {
    logDatabaseError(req.log, "getPlayerStatsByTournament", err, { tournament_id });
    res.status(500).json({ success: false, error: "Server error retrieving tournament stats" });
  }
};

module.exports = {
  getPlayerStatsByMatch,
  getPlayerStatsByTournament,
};