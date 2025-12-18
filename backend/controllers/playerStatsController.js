const { db } = require("../config/db");
const { logDatabaseError } = require("../utils/safeLogger");

// ==========================================
// 📊 GLOBAL & TOURNAMENT STATISTICS
// ==========================================

/**
 * 📌 Get Top Run Scorers
 * Supports filtering by Tournament ID. If omitted, returns global stats.
 */
const getTopRunScorers = async (req, res) => {
  const { tournament_id } = req.query; // Changed to query param for flexibility (e.g. ?tournament_id=5)

  try {
    const params = [];
    let whereClause = "";

    if (tournament_id) {
      whereClause = "WHERE m.tournament_id = ?";
      params.push(tournament_id);
    }

    const sql = `
      SELECT 
        p.id AS player_id, 
        p.player_name, 
        p.player_image_url,
        t.team_name,
        SUM(ps.runs) AS total_runs,
        SUM(ps.balls_faced) AS balls_faced,
        SUM(ps.hundreds) AS hundreds,
        SUM(ps.fifties) AS fifties,
        -- Safe calculation for Strike Rate to avoid Divide by Zero
        CASE 
          WHEN SUM(ps.balls_faced) > 0 
          THEN ROUND((SUM(ps.runs) / SUM(ps.balls_faced)) * 100, 2) 
          ELSE 0.00 
        END AS strike_rate,
        -- Safe calculation for Batting Average (Runs / (Innings - Not Outs))
        -- Simplified here as Runs / Innings for general overview
        ROUND(AVG(ps.runs), 2) as average
      FROM player_match_stats ps
      JOIN players p ON ps.player_id = p.id
      JOIN matches m ON ps.match_id = m.id
      LEFT JOIN teams t ON p.team_id = t.id
      ${whereClause}
      GROUP BY p.id
      ORDER BY total_runs DESC
      LIMIT 10
    `;

    const [rows] = await db.query(sql, params);
    res.json(rows);

  } catch (err) {
    logDatabaseError(req.log, "getTopRunScorers", err, { tournament_id });
    res.status(500).json({ error: "Server error fetching batting stats" });
  }
};

/**
 * 📌 Get Top Wicket Takers
 * Supports filtering by Tournament ID.
 */
const getTopWicketTakers = async (req, res) => {
  const { tournament_id } = req.query;

  try {
    const params = [];
    let whereClause = "";

    if (tournament_id) {
      whereClause = "WHERE m.tournament_id = ?";
      params.push(tournament_id);
    }

    const sql = `
      SELECT 
        p.id AS player_id, 
        p.player_name,
        p.player_image_url,
        t.team_name,
        SUM(ps.wickets) AS total_wickets,
        SUM(ps.balls_bowled) AS balls_bowled,
        SUM(ps.runs_conceded) AS runs_conceded,
        -- Economy Rate: (Runs / Overs)
        CASE 
          WHEN SUM(ps.balls_bowled) > 0 
          THEN ROUND(SUM(ps.runs_conceded) / (SUM(ps.balls_bowled) / 6), 2)
          ELSE 0.00 
        END AS economy_rate,
        -- Bowling Average: (Runs / Wickets)
        CASE 
          WHEN SUM(ps.wickets) > 0 
          THEN ROUND(SUM(ps.runs_conceded) / SUM(ps.wickets), 2)
          ELSE 0.00 
        END AS bowling_avg
      FROM player_match_stats ps
      JOIN players p ON ps.player_id = p.id
      JOIN matches m ON ps.match_id = m.id
      LEFT JOIN teams t ON p.team_id = t.id
      ${whereClause}
      GROUP BY p.id
      ORDER BY total_wickets DESC, economy_rate ASC
      LIMIT 10
    `;

    const [rows] = await db.query(sql, params);
    res.json(rows);

  } catch (err) {
    logDatabaseError(req.log, "getTopWicketTakers", err, { tournament_id });
    res.status(500).json({ error: "Server error fetching bowling stats" });
  }
};

/**
 * 📌 Get Comprehensive Player Stats (Profile View)
 * Aggregates stats specific to a tournament or career (if tournament_id omitted)
 */
const getPlayerStats = async (req, res) => {
  const { player_id } = req.params;
  const { tournament_id } = req.query;

  if (!player_id) {
    return res.status(400).json({ error: "Player ID is required" });
  }

  try {
    const params = [player_id];
    let whereClause = "WHERE ps.player_id = ?";

    if (tournament_id) {
      whereClause += " AND m.tournament_id = ?";
      params.push(tournament_id);
    }

    const sql = `
      SELECT 
        p.id AS player_id, 
        p.player_name, 
        p.player_role,
        p.player_image_url,
        t.team_name,
        COUNT(DISTINCT ps.match_id) as matches_played,
        
        -- Batting
        SUM(ps.runs) AS total_runs,
        SUM(ps.balls_faced) AS balls_faced,
        SUM(ps.hundreds) AS hundreds,
        SUM(ps.fifties) AS fifties,
        MAX(ps.runs) as highest_score,
        CASE 
          WHEN SUM(ps.balls_faced) > 0 
          THEN ROUND((SUM(ps.runs) / SUM(ps.balls_faced)) * 100, 2) 
          ELSE 0.00 
        END AS batting_strike_rate,
        
        -- Bowling
        SUM(ps.wickets) AS total_wickets,
        SUM(ps.balls_bowled) AS balls_bowled,
        SUM(ps.runs_conceded) AS runs_conceded,
        CASE 
          WHEN SUM(ps.wickets) > 0 
          THEN ROUND(SUM(ps.runs_conceded) / SUM(ps.wickets), 2)
          ELSE 0.00 
        END AS bowling_average,
        CASE 
          WHEN SUM(ps.balls_bowled) > 0 
          THEN ROUND(SUM(ps.runs_conceded) / (SUM(ps.balls_bowled) / 6), 2)
          ELSE 0.00 
        END AS economy_rate

      FROM player_match_stats ps
      JOIN players p ON ps.player_id = p.id
      JOIN matches m ON ps.match_id = m.id
      LEFT JOIN teams t ON p.team_id = t.id
      ${whereClause}
      GROUP BY p.id
    `;

    const [rows] = await db.query(sql, params);

    if (rows.length === 0) {
      // Return basic player info if no stats exist yet
      const [playerBasic] = await db.query("SELECT * FROM players WHERE id = ?", [player_id]);
      if (playerBasic.length === 0) return res.status(404).json({ error: "Player not found" });
      
      // Return zeroed stats structure
      return res.json({
        player_id: playerBasic[0].id,
        player_name: playerBasic[0].player_name,
        player_role: playerBasic[0].player_role,
        player_image_url: playerBasic[0].player_image_url,
        matches_played: 0,
        total_runs: 0,
        total_wickets: 0,
        batting_strike_rate: 0,
        economy_rate: 0
      });
    }

    res.json(rows[0]);

  } catch (err) {
    logDatabaseError(req.log, "getPlayerStats", err, { player_id, tournament_id });
    res.status(500).json({ error: "Server error fetching player stats" });
  }
};

/**
 * 📌 Get General Overview Stats (For Admin/Home Dashboard)
 */
const getOverviewStats = async (req, res) => {
  try {
    const [[matches]] = await db.query("SELECT COUNT(*) as total FROM matches");
    const [[tournaments]] = await db.query("SELECT COUNT(*) as total FROM tournaments WHERE status = 'ongoing'");
    const [[teams]] = await db.query("SELECT COUNT(*) as total FROM teams");
    const [[players]] = await db.query("SELECT COUNT(*) as total FROM players");

    res.json({
      total_matches: matches.total,
      active_tournaments: tournaments.total,
      total_teams: teams.total,
      total_players: players.total
    });
  } catch (err) {
    logDatabaseError(req.log, "getOverviewStats", err);
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = { 
  getTopRunScorers, 
  getTopWicketTakers, 
  getPlayerStats,
  getOverviewStats
};