const { db } = require("../config/db");
const { validateTeamLogoUrl } = require("../utils/urlValidation");
const { logDatabaseError } = require("../utils/safeLogger");

// ==========================================
// HELPER: Dynamic Update Query Builder
// ==========================================
const buildDynamicUpdate = (data, allowedFields) => {
  const updates = [];
  const values = [];

  Object.keys(data).forEach(key => {
    // Check if key is allowed and value is not undefined
    if (allowedFields.includes(key) && data[key] !== undefined) {
      updates.push(`${key} = ?`);
      values.push(data[key]);
    }
  });

  return {
    setClause: updates.join(', '),
    values: values
  };
};

// ==========================================
// CORE TEAM MANAGEMENT
// ==========================================

// 📌 Create Team (One per user)
const createMyTeam = async (req, res) => {
  const { team_name, team_location } = req.body;
  let { team_logo_url } = req.body;

  // 1. Input Validation
  if (!team_name || !team_location) {
    return res.status(400).json({ error: "Team name and location are required" });
  }
  if (String(team_name).length < 3) {
    return res.status(400).json({ error: "Team name must be at least 3 characters" });
  }

  // 2. Logo Validation (Handles URL & Local Paths)
  if (team_logo_url) {
    const logoCheck = validateTeamLogoUrl(team_logo_url);
    if (!logoCheck.isValid) {
      return res.status(400).json({ error: `Invalid logo: ${logoCheck.error}` });
    }
    team_logo_url = logoCheck.normalizedUrl;
  }

  try {
    // 3. Check Exclusion (One team per captain)
    const [existing] = await db.query("SELECT id FROM teams WHERE owner_id = ?", [req.user.id]);
    if (existing.length > 0) {
      return res.status(409).json({ error: "You already have a team. Only one team per user is allowed." });
    }

    // 4. Insert Team
    const [result] = await db.query(
      `INSERT INTO teams 
       (team_name, team_location, team_logo_url, owner_id, matches_played, matches_won, trophies) 
       VALUES (?, ?, ?, ?, 0, 0, 0)`,
      [team_name, team_location, team_logo_url || null, req.user.id]
    );

    // 5. Return Full Object
    const [newTeam] = await db.query(
      `SELECT t.*, u.phone_number AS owner_phone 
       FROM teams t 
       LEFT JOIN users u ON t.owner_id = u.id 
       WHERE t.id = ?`,
      [result.insertId]
    );

    res.status(201).json({ message: "Team created successfully", team: newTeam[0] });

  } catch (err) {
    logDatabaseError(req.log, "createMyTeam", err, { userId: req.user?.id });
    res.status(500).json({ error: "Server error creating team" });
  }
};

// 📌 Get My Team (Owner View)
const getMyTeam = async (req, res) => {
  try {
    const [teams] = await db.query(
      `SELECT t.*, u.phone_number AS owner_phone
       FROM teams t
       LEFT JOIN users u ON t.owner_id = u.id
       WHERE t.owner_id = ? LIMIT 1`,
      [req.user.id]
    );

    if (teams.length === 0) {
      return res.status(404).json({ error: "Team not found" });
    }

    const team = teams[0];

    // Fetch Players
    const [players] = await db.query(
      `SELECT * FROM players WHERE team_id = ? ORDER BY id DESC`,
      [team.id]
    );

    res.json({ ...team, players });

  } catch (err) {
    logDatabaseError(req.log, "getMyTeam", err, { userId: req.user?.id });
    res.status(500).json({ error: "Server error fetching team" });
  }
};

// 📌 Update Team (Transaction Safe)
const updateMyTeam = async (req, res) => {
  const {
    team_name, team_location,
    captain_player_id, vice_captain_player_id,
    clear_captain, clear_vice_captain
  } = req.body;

  let { team_logo_url } = req.body;

  // 1. Logo Validation
  if (team_logo_url) {
    const logoCheck = validateTeamLogoUrl(team_logo_url);
    if (!logoCheck.isValid) return res.status(400).json({ error: logoCheck.error });
    team_logo_url = logoCheck.normalizedUrl;
  }

  // 2. Captain/VC Logic Validation
  if (captain_player_id && vice_captain_player_id && captain_player_id === vice_captain_player_id) {
    return res.status(400).json({ error: "Captain and Vice Captain must be different players" });
  }

  // 3. Prepare Update Data
  const updateData = {};
  if (team_name) updateData.team_name = team_name;
  if (team_location) updateData.team_location = team_location;
  if (team_logo_url !== undefined) updateData.team_logo_url = team_logo_url;

  // Handle Special Role logic
  if (clear_captain) updateData.captain_player_id = null;
  else if (captain_player_id) updateData.captain_player_id = captain_player_id;

  if (clear_vice_captain) updateData.vice_captain_player_id = null;
  else if (vice_captain_player_id) updateData.vice_captain_player_id = vice_captain_player_id;

  // Check if there is anything to update
  const allowedFields = ['team_name', 'team_location', 'team_logo_url', 'captain_player_id', 'vice_captain_player_id'];
  const queryParts = buildDynamicUpdate(updateData, allowedFields);

  if (!queryParts) {
    return res.status(400).json({ error: "No valid fields provided for update" });
  }

  let conn;
  try {
    conn = await db.getConnection();
    await conn.beginTransaction();

    // 4. Get Team & Lock Row
    const [teams] = await conn.query(
      "SELECT id FROM teams WHERE owner_id = ? FOR UPDATE",
      [req.user.id]
    );

    if (teams.length === 0) {
      await conn.rollback();
      return res.status(404).json({ error: "Team not found" });
    }
    const teamId = teams[0].id;

    // 5. Verify Players belong to this team (if roles are being updated)
    if (captain_player_id || vice_captain_player_id) {
      const idsToCheck = [];
      if (captain_player_id) idsToCheck.push(captain_player_id);
      if (vice_captain_player_id) idsToCheck.push(vice_captain_player_id);

      // Count how many of these IDs belong to THIS team
      const [validPlayers] = await conn.query(
        "SELECT COUNT(*) as count FROM players WHERE team_id = ? AND id IN (?)",
        [teamId, idsToCheck]
      );

      if (validPlayers[0].count !== idsToCheck.length) {
        await conn.rollback();
        return res.status(400).json({ error: "Assigned Captain/Vice-Captain must belong to your team" });
      }
    }

    // 6. Execute Update
    const sql = `UPDATE teams SET ${queryParts.setClause} WHERE id = ?`;
    await conn.query(sql, [...queryParts.values, teamId]);

    // 7. Return Updated Data
    const [updatedTeam] = await conn.query("SELECT * FROM teams WHERE id = ?", [teamId]);

    await conn.commit();
    res.json({ message: "Team updated successfully", team: updatedTeam[0] });

  } catch (err) {
    if (conn) await conn.rollback();

    // Handle Unique Constraint on Captain (if one exists in DB schema)
    if (err.code === 'ER_DUP_ENTRY' && err.sqlMessage.includes('captain')) {
      return res.status(400).json({ error: "This player is already a captain" });
    }

    logDatabaseError(req.log, "updateMyTeam", err, { userId: req.user?.id });
    res.status(500).json({ error: "Server error updating team" });
  } finally {
    if (conn) conn.release();
  }
};

// 📌 Delete My Team (Safety Checks)
const deleteMyTeam = async (req, res) => {
  try {
    const [teams] = await db.query("SELECT id FROM teams WHERE owner_id = ?", [req.user.id]);
    if (teams.length === 0) return res.status(404).json({ error: "Team not found" });

    const teamId = teams[0].id;

    // Constraint Check: Active Tournament or Matches?
    const [checks] = await db.query(`
      SELECT 
        (SELECT COUNT(*) FROM tournament_teams WHERE team_id = ?) as tournaments,
        (SELECT COUNT(*) FROM matches WHERE team1_id = ? OR team2_id = ?) as matches
    `, [teamId, teamId, teamId]);

    if (checks[0].tournaments > 0) {
      return res.status(400).json({ error: "Cannot delete team while in a tournament. Withdraw first." });
    }
    if (checks[0].matches > 0) {
      return res.status(400).json({ error: "Cannot delete team with match history. Contact support." });
    }

    await db.query("DELETE FROM teams WHERE id = ?", [teamId]);
    res.json({ message: "Team deleted successfully" });

  } catch (err) {
    logDatabaseError(req.log, "deleteMyTeam", err, { userId: req.user?.id });
    res.status(500).json({ error: "Server error" });
  }
};

// ==========================================
// PUBLIC / SYSTEM TEAM ROUTES
// ==========================================

// 📌 Create Temporary Team (Admin/System use)
const createTemporaryTeam = async (req, res) => {
  const { team_name, team_location } = req.body;
  if (!team_name) return res.status(400).json({ error: "Team name is required" });

  try {
    const [result] = await db.query(
      `INSERT INTO teams (team_name, team_location, owner_id, matches_played, matches_won, trophies) 
       VALUES (?, ?, ?, 0, 0, 0)`,
      [team_name, team_location || null, req.user.id]
    );

    res.status(201).json({
      message: "Temporary team created",
      id: result.insertId,
      team_name,
      team_location
    });
  } catch (err) {
    logDatabaseError(req.log, "createTemporaryTeam", err);
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Public: Get All Teams (Paginated)
const getAllTeams = async (req, res) => {
  try {
    const { search, page = 1, limit = 50 } = req.query;
    const pageNum = Math.max(1, parseInt(page));
    const limitNum = Math.min(100, Math.max(1, parseInt(limit)));
    const offset = (pageNum - 1) * limitNum;

    let query = "SELECT id, team_name, team_location, team_logo_url, matches_played, matches_won, trophies FROM teams";
    const params = [];

    if (search) {
      query += " WHERE team_name LIKE ? OR team_location LIKE ?";
      params.push(`%${search}%`, `%${search}%`);
    }

    // Get Total Count
    const countQuery = query.replace("SELECT id, team_name, team_location, team_logo_url, matches_played, matches_won, trophies", "SELECT COUNT(*) as total");
    const [countRes] = await db.query(countQuery, params);

    // Get Data
    query += " ORDER BY team_name ASC LIMIT ? OFFSET ?";
    params.push(limitNum, offset);
    const [rows] = await db.query(query, params);

    res.json({
      teams: rows,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total: countRes[0].total,
        pages: Math.ceil(countRes[0].total / limitNum)
      }
    });
  } catch (err) {
    logDatabaseError(req.log, "getAllTeams", err);
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Public: Get Team By ID
const getTeamById = async (req, res) => {
  try {
    const id = req.params.id_validated;
    const [rows] = await db.query(
      "SELECT id, team_name, team_location, team_logo_url, matches_played, matches_won, trophies FROM teams WHERE id = ?",
      [id]
    );
    if (rows.length === 0) return res.status(404).json({ error: "Team not found" });

    // Fetch Players
    const [players] = await db.query(
      "SELECT * FROM players WHERE team_id = ? ORDER BY id DESC",
      [id]
    );

    res.json({ ...rows[0], players });
  } catch (err) {
    logDatabaseError(req.log, "getTeamById", err, { teamId: req.params.id });
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = {
  createMyTeam,
  getMyTeam,
  updateMyTeam,
  deleteMyTeam,
  createTemporaryTeam,
  getAllTeams,
  getTeamById
};