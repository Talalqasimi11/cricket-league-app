const { db } = require("../config/db");
const { logDatabaseError } = require("../utils/safeLogger");

// ==========================================
// HELPER: Reusable Match Query Builder
// ==========================================
const getMatchData = async (whereClause, params) => {
  const sql = `
    SELECT 
      m.id, m.status, m.match_datetime as match_date, m.venue, m.overs as max_overs,
      m.creator_id, m.team1_lineup, m.team2_lineup,
      
      -- Tournament Info
      tr.id as tournament_id, tr.tournament_name,
      
      -- Team 1 Info
      t1.id as team1_id, t1.team_name as team1_name, t1.team_logo_url as team1_logo,
      
      -- Team 2 Info
      t2.id as team2_id, t2.team_name as team2_name, t2.team_logo_url as team2_logo,
      
      -- Inning 1 Data
      i1.id as i1_id, i1.batting_team_id as i1_batting_team, i1.runs as i1_runs, 
      i1.wickets as i1_wickets, i1.overs_decimal as i1_overs, i1.status as i1_status,
      
      -- Inning 2 Data
      i2.id as i2_id, i2.batting_team_id as i2_batting_team, i2.runs as i2_runs, 
      i2.wickets as i2_wickets, i2.overs_decimal as i2_overs, i2.status as i2_status,

      -- Current Status Helper
      CASE 
        WHEN m.status = 'completed' THEN 'Match Ended'
        WHEN i2.status = 'in_progress' THEN '2nd Innings'
        WHEN i1.status = 'in_progress' THEN '1st Innings'
        ELSE 'Not Started'
      END as match_phase

    FROM matches m
    LEFT JOIN teams t1 ON m.team1_id = t1.id
    LEFT JOIN teams t2 ON m.team2_id = t2.id
    LEFT JOIN tournaments tr ON m.tournament_id = tr.id
    -- Join specific innings based on inning_number
    LEFT JOIN match_innings i1 ON m.id = i1.match_id AND i1.inning_number = 1
    LEFT JOIN match_innings i2 ON m.id = i2.match_id AND i2.inning_number = 2
    ${whereClause}
    ORDER BY m.match_datetime DESC, m.id DESC
  `;

  const [rows] = await db.query(sql, params);

  // Format the flat SQL rows into a structured JSON object
  return rows.map(row => ({
    id: row.id,
    status: row.status,
    match_phase: row.match_phase,
    venue: row.venue,
    date: row.match_date,
    max_overs: row.max_overs,
    creator_id: row.creator_id,
    team1_lineup: row.team1_lineup ? JSON.parse(row.team1_lineup) : null,
    team2_lineup: row.team2_lineup ? JSON.parse(row.team2_lineup) : null,

    // FLATTEN TEAM NAMES for frontend compatibility
    team1_name: row.team1_name,
    team2_name: row.team2_name,

    tournament: {
      id: row.tournament_id,
      name: row.tournament_name
    },
    team1: {
      id: row.team1_id,
      name: row.team1_name,
      logo: row.team1_logo
    },
    team2: {
      id: row.team2_id,
      name: row.team2_name,
      logo: row.team2_logo
    },
    score: {
      inning1: row.i1_id ? {
        batting_team_id: row.i1_batting_team,
        runs: row.i1_runs,
        wickets: row.i1_wickets,
        overs: row.i1_overs,
        status: row.i1_status
      } : null,
      inning2: row.i2_id ? {
        batting_team_id: row.i2_batting_team,
        runs: row.i2_runs,
        wickets: row.i2_wickets,
        overs: row.i2_overs,
        status: row.i2_status
      } : null
    }
  }));
};

// ==========================================
// CONTROLLER METHODS
// ==========================================

/**
 * 📌 Get Live Matches
 * Returns all matches currently in progress
 */
const getLiveMatches = async (req, res) => {
  try {
    const matches = await getMatchData("WHERE m.status = ?", ['live']);
    res.json({ matches });
  } catch (err) {
    logDatabaseError(req.log, "getLiveMatches", err);
    res.status(500).json({ error: "Server error fetching live matches" });
  }
};

/**
 * 📌 Get Match By ID
 * Returns detailed info for a single match
 */
const getMatchById = async (req, res) => {
  const { id } = req.params;

  if (!id) return res.status(400).json({ error: "Match ID is required" });

  try {
    const matches = await getMatchData("WHERE m.id = ?", [id]);

    if (matches.length === 0) {
      return res.status(404).json({ error: "Match not found" });
    }

    res.json({ match: matches[0] });
  } catch (err) {
    logDatabaseError(req.log, "getMatchById", err, { matchId: id });
    res.status(500).json({ error: "Server error fetching match details" });
  }
};

/**
 * 📌 Get Upcoming Matches
 * (Bonus: Usually needed for dashboards)
 */
const getUpcomingMatches = async (req, res) => {
  try {
    const matches = await getMatchData("WHERE m.status = ?", ['scheduled']);
    res.json({ matches });
  } catch (err) {
    logDatabaseError(req.log, "getUpcomingMatches", err);
    res.status(500).json({ error: "Server error" });
  }
};

/**
 * 📌 Get Recent Results
 * (Bonus: Usually needed for dashboards)
 */
const getCompletedMatches = async (req, res) => {
  try {
    // Limit to last 10 results
    const matches = await getMatchData("WHERE m.status = ? LIMIT 10", ['completed']);
    res.json({ matches });
  } catch (err) {
    logDatabaseError(req.log, "getCompletedMatches", err);
    res.status(500).json({ error: "Server error" });
  }
};

/**
 * 📌 Get All Matches
 * Returns all matches (can be filtered by query params if needed later)
 */
const getAllMatches = async (req, res) => {
  try {
    // By default fetch all, or we could add pagination/filtering here
    const matches = await getMatchData("", []);
    res.json({ matches });
  } catch (err) {
    logDatabaseError(req.log, "getAllMatches", err);
    res.status(500).json({ error: "Server error fetching matches" });
  }
};

/**
 * 📌 Create Match (Friendly/Custom)
 */
const createMatch = async (req, res) => {
  const { team1_id, team2_id, match_datetime, venue, overs, team1_lineup, team2_lineup } = req.body;

  if (!team1_id || !team2_id || !match_datetime || !venue || !overs) {
    return res.status(400).json({ error: "All fields are required" });
  }

  try {
    const formattedDate = new Date(match_datetime).toISOString().slice(0, 19).replace('T', ' ');
    const [result] = await db.query(
      `INSERT INTO matches (team1_id, team2_id, match_datetime, venue, overs, status, creator_id, team1_lineup, team2_lineup) 
       VALUES (?, ?, ?, ?, ?, 'not_started', ?, ?, ?)`,
      [team1_id, team2_id, formattedDate, venue, overs, req.user.id,
        team1_lineup ? JSON.stringify(team1_lineup) : null,
        team2_lineup ? JSON.stringify(team2_lineup) : null]
    );

    const matchId = result.insertId;
    // Return the created match structure
    const matches = await getMatchData("WHERE m.id = ?", [matchId]);
    res.status(201).json(matches[0]); // Return the single match object

  } catch (err) {
    logDatabaseError(req.log, "createMatch", err);
    res.status(500).json({ error: "Server error creating match" });
  }
};

/**
 * 📌 Get My Matches
 * Returns matches where the authenticated user is the owner of either team or the tournament creator
 */
const getMyMatches = async (req, res) => {
  const userId = req.user.id;
  try {
    const whereClause = `
      WHERE m.team1_id IN (SELECT id FROM teams WHERE owner_id = ?)
         OR m.team2_id IN (SELECT id FROM teams WHERE owner_id = ?)
         OR m.tournament_id IN (SELECT id FROM tournaments WHERE created_by = ?)
         OR m.creator_id = ?
    `;
    const matches = await getMatchData(whereClause, [userId, userId, userId, userId]);
    res.json({ matches });
  } catch (err) {
    logDatabaseError(req.log, "getMyMatches", err);
    res.status(500).json({ error: "Server error fetching your matches" });
  }
};

/**
 * 📌 Delete Match
 */
const deleteMatch = async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  try {
    // Check ownership/permission
    const [match] = await db.query(`
      SELECT m.id FROM matches m
      LEFT JOIN teams t1 ON m.team1_id = t1.id
      LEFT JOIN teams t2 ON m.team2_id = t2.id
      LEFT JOIN tournaments tr ON m.tournament_id = tr.id
      WHERE m.id = ? AND (t1.owner_id = ? OR t2.owner_id = ? OR tr.created_by = ? OR m.creator_id = ?)
    `, [id, userId, userId, userId, userId]);

    if (match.length === 0) {
      return res.status(403).json({ error: "Unauthorized or match not found" });
    }

    await db.query("DELETE FROM matches WHERE id = ?", [id]);
    res.json({ message: "Match deleted successfully" });
  } catch (err) {
    logDatabaseError(req.log, "deleteMatch", err);
    res.status(500).json({ error: "Server error deleting match" });
  }
};

module.exports = {
  getLiveMatches,
  getMatchById,
  getUpcomingMatches,
  getCompletedMatches,
  getAllMatches,
  createMatch,
  getMyMatches,
  deleteMatch
};