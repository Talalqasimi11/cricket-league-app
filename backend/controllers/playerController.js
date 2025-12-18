const { db } = require("../config/db");
const { validatePlayerImageUrl } = require("../utils/urlValidation");
const { logDatabaseError } = require("../utils/safeLogger");

// ==========================================
// CONFIGURATION & CONSTANTS
// ==========================================

const ALLOWED_ROLES = ["Batsman", "Bowler", "All-rounder", "Wicket-keeper"];

const ROLE_MAPPING = {
  "wicketkeeper": "Wicket-keeper",
  "wicket-keeper": "Wicket-keeper",
  "wicket keeper": "Wicket-keeper",
  "wk": "Wicket-keeper"
};

// ==========================================
// HELPER FUNCTIONS
// ==========================================

/**
 * Normalizes player role to standard format
 */
const normalizeRole = (role) => {
  if (!role) return null;
  const normalized = role.trim().toLowerCase();
  // Check mapping first, then check allowed list (case-insensitive)
  if (ROLE_MAPPING[normalized]) return ROLE_MAPPING[normalized];

  const found = ALLOWED_ROLES.find(r => r.toLowerCase() === normalized);
  return found || null;
};

/**
 * Dynamically builds SQL UPDATE clause
 * @param {Object} data - Key-value pairs to update
 * @param {Array} allowedFields - Whitelist of allowed columns
 * @returns {Object|null} - { setClause: string, values: Array }
 */
const buildDynamicUpdate = (data, allowedFields) => {
  const updates = [];
  const values = [];

  Object.keys(data).forEach(key => {
    if (allowedFields.includes(key) && data[key] !== undefined) {
      updates.push(`${key} = ?`);
      values.push(data[key]);
    }
  });

  if (updates.length === 0) return null;

  return {
    setClause: updates.join(', '),
    values: values
  };
};

// ==========================================
// CONTROLLER METHODS
// ==========================================

// 📌 Add new player
const addPlayer = async (req, res) => {
  const { player_name, player_role, team_id, is_temporary } = req.body;
  let { player_image_url } = req.body;

  // 1. Input Validation
  if (!player_name || !player_role) {
    return res.status(400).json({ error: "Player name and role are required" });
  }

  // 2. URL/Path Validation (Handles both remote URLs and /uploads/ paths)
  if (player_image_url) {
    const urlCheck = validatePlayerImageUrl(player_image_url);
    if (!urlCheck.isValid) {
      return res.status(400).json({ error: `Invalid image: ${urlCheck.error}` });
    }
    player_image_url = urlCheck.normalizedUrl;
  }

  // 3. Role Normalization
  const finalRole = normalizeRole(player_role);
  if (!finalRole) {
    return res.status(400).json({ error: `Invalid role. Allowed: ${ALLOWED_ROLES.join(", ")}` });
  }

  try {
    let targetTeamId;

    // 4. Determine Target Team
    if (team_id) {
      if (is_temporary) {
        // For temporary players, just verify team exists (Any authorized user can add)
        const [teamRows] = await db.query("SELECT id FROM teams WHERE id = ?", [team_id]);
        if (teamRows.length === 0) {
          return res.status(404).json({ error: "Team not found." });
        }
        targetTeamId = teamRows[0].id;
      } else {
        // For permanent players, require ownership
        const [teamRows] = await db.query(
          "SELECT id FROM teams WHERE id = ? AND owner_id = ?",
          [team_id, req.user.id]
        );
        if (teamRows.length === 0) {
          return res.status(403).json({ error: "Team not found or you do not have permission to add players to this team." });
        }
        targetTeamId = teamRows[0].id;
      }
    } else {
      // Fallback: Find user's first team (Legacy behavior)
      const [teamRows] = await db.query(
        "SELECT id FROM teams WHERE owner_id = ?",
        [req.user.id]
      );

      if (teamRows.length === 0) {
        return res.status(404).json({ error: "You must create a team before adding players." });
      }
      targetTeamId = teamRows[0].id;
    }

    // 5. Insert Operation
    const [result] = await db.query(
      `INSERT INTO players 
       (player_name, player_role, player_image_url, runs, matches_played, hundreds, fifties, batting_average, strike_rate, wickets, team_id, is_temporary, is_archived) 
       VALUES (?, ?, ?, 0, 0, 0, 0, 0, 0, 0, ?, ?, 0)`,
      [player_name.trim(), finalRole, player_image_url || null, targetTeamId, is_temporary ? 1 : 0]
    );

    // 6. Return Created Resource
    const [newPlayer] = await db.query("SELECT * FROM players WHERE id = ?", [result.insertId]);
    res.status(201).json(newPlayer[0]);

  } catch (err) {
    logDatabaseError(req.log, "addPlayer", err, { userId: req.user?.id });
    res.status(500).json({ error: "Server error while adding player." });
  }
};

// 📌 Get user's players
const getMyPlayers = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT p.* FROM players p 
       JOIN teams t ON p.team_id = t.id 
       WHERE t.owner_id = ? AND p.is_archived = 0
       ORDER BY p.id DESC`,
      [req.user.id]
    );
    res.json(rows);
  } catch (err) {
    logDatabaseError(req.log, "getMyPlayers", err, { userId: req.user?.id });
    res.status(500).json({ error: "Server error fetching players." });
  }
};

// 📌 Update player info (Refactored & Optimized)
const updatePlayer = async (req, res) => {
  const playerId = req.params.id_validated;
  const body = req.body;

  // 1. Prepare Update Data
  const dataToUpdate = {};

  // String Fields
  if (body.player_name !== undefined) {
    if (typeof body.player_name !== 'string' || !body.player_name.trim()) {
      return res.status(400).json({ error: "Player name cannot be empty" });
    }
    dataToUpdate.player_name = body.player_name.trim();
  }

  // Role Handling
  if (body.player_role !== undefined) {
    const role = normalizeRole(body.player_role);
    if (!role) return res.status(400).json({ error: "Invalid player role" });
    dataToUpdate.player_role = role;
  }

  // Image Handling (Robust Check)
  if (body.player_image_url !== undefined) {
    if (body.player_image_url === null) {
      dataToUpdate.player_image_url = null;
    } else {
      const urlCheck = validatePlayerImageUrl(body.player_image_url);
      if (!urlCheck.isValid) return res.status(400).json({ error: urlCheck.error });
      dataToUpdate.player_image_url = urlCheck.normalizedUrl;
    }
  }

  // Numeric Fields (Batch Validation)
  const numFields = ['runs', 'matches_played', 'hundreds', 'fifties', 'batting_average', 'strike_rate', 'wickets'];
  for (const field of numFields) {
    if (body[field] !== undefined) {
      const val = Number(body[field]);
      if (isNaN(val) || val < 0) return res.status(400).json({ error: `${field} must be a valid number` });
      dataToUpdate[field] = val;
    }
  }

  // 2. Build Query
  // Whitelist columns to prevent SQL injection via object keys
  const allowedColumns = ['player_name', 'player_role', 'player_image_url', ...numFields];
  const queryParts = buildDynamicUpdate(dataToUpdate, allowedColumns);

  if (!queryParts) {
    return res.status(400).json({ error: "No valid fields provided for update" });
  }

  let conn;
  try {
    conn = await db.getConnection();
    await conn.beginTransaction();

    // 3. Security Check: Ensure user owns the team this player belongs to
    // Using FOR UPDATE to lock row against race conditions
    const [playerCheck] = await conn.query(
      `SELECT p.id 
       FROM players p 
       JOIN teams t ON p.team_id = t.id 
       WHERE p.id = ? AND t.owner_id = ? 
       FOR UPDATE`,
      [playerId, req.user.id]
    );

    if (playerCheck.length === 0) {
      await conn.rollback();
      return res.status(403).json({ error: "Permission denied or player not found." });
    }

    // 4. Execute Update
    const sql = `UPDATE players SET ${queryParts.setClause} WHERE id = ?`;
    await conn.query(sql, [...queryParts.values, playerId]);

    // 5. Return Updated Entity
    const [updatedPlayer] = await conn.query("SELECT * FROM players WHERE id = ?", [playerId]);

    await conn.commit();
    res.json({ message: "Player updated", player: updatedPlayer[0] });

  } catch (err) {
    if (conn) await conn.rollback();
    logDatabaseError(req.log, "updatePlayer", err, { userId: req.user?.id, playerId });
    res.status(500).json({ error: "Server error updating player" });
  } finally {
    if (conn) conn.release();
  }
};

// 📌 Delete player
const deletePlayer = async (req, res) => {
  const playerId = req.params.id_validated;

  try {
    // Security check is implicitly handled by the WHERE clause in DELETE
    // BUT, we check existence first to return a friendly 404/403
    const [result] = await db.query(
      `DELETE p FROM players p 
       JOIN teams t ON p.team_id = t.id 
       WHERE p.id = ? AND t.owner_id = ?`,
      [playerId, req.user.id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Player not found or you do not have permission." });
    }

    res.json({ message: "Player deleted successfully" });
  } catch (err) {
    logDatabaseError(req.log, "deletePlayer", err, { userId: req.user?.id, playerId });
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Public: Get players by team ID
const getPlayersByTeamId = async (req, res) => {
  try {
    const teamId = req.params.team_id_validated;
    const [rows] = await db.query(
      "SELECT * FROM players WHERE team_id = ? AND is_archived = 0 ORDER BY id DESC",
      [teamId]
    );
    res.json(rows);
  } catch (err) {
    logDatabaseError(req.log, "getPlayersByTeamId", err, { teamId: req.params.team_id });
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Public: Get players with optional filters (e.g. team_id)
const getPlayers = async (req, res) => {
  try {
    const { team_id } = req.query;
    let query = "SELECT * FROM players WHERE is_archived = 0";
    const params = [];

    if (team_id) {
      query += " AND team_id = ?";
      params.push(team_id);
    }

    query += " ORDER BY id DESC";

    const [rows] = await db.query(query, params);
    res.json(rows);
  } catch (err) {
    logDatabaseError(req.log, "getPlayers", err, { query: req.query });
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = {
  addPlayer,
  getMyPlayers,
  updatePlayer,
  deletePlayer,
  getPlayersByTeamId,
  getPlayers
};