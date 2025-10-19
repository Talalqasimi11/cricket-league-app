const db = require("../config/db");
const { validateSingleNumericParam } = require("../utils/inputValidation");
const { validateTeamLogoUrl } = require("../utils/urlValidation");
const { logDatabaseError, logRequestError } = require("../utils/safeLogger");

// 📌 Get owner's own team (backward compatible with historical captain_id)
// API Contract Note: This endpoint returns owner_phone in the response for authenticated team owners.
// Public endpoints (getAllTeams, getTeamById) do not expose owner information for privacy.
const getMyTeam = async (req, res) => {
  try {
    if (!req.user || !req.user.id) {
      req.log?.warn("getMyTeam: No user in request");
      return res.status(401).json({ error: "Authentication required" });
    }

    if (process.env.LOG_LEVEL === 'debug') {
      req.log?.debug("getMyTeam: Fetching team for user", { userId: req.user.id });
    }

    const [rows] = await db.query(
      `SELECT 
         t.id,
         t.team_name,
         t.team_location,
         t.team_logo_url,
         t.matches_played,
         t.matches_won,
         t.trophies,
         t.captain_player_id,
         t.vice_captain_player_id,
         t.owner_id,
         u.phone_number AS owner_phone
       FROM teams t
       LEFT JOIN users u ON t.owner_id = u.id
       WHERE t.owner_id = ?
       LIMIT 1`,
      [req.user.id]
    );

    if (rows.length === 0) {
      req.log?.warn("getMyTeam: No team found for user", { userId: req.user.id });
      return res.status(404).json({ error: "Team not found" });
    }

    const team = rows[0];
    
    // Fetch players for this team
    const [playerRows] = await db.query(
      `SELECT 
         p.id, p.player_name, p.player_role, p.player_image_url, p.runs, p.matches_played, 
         p.hundreds, p.fifties, p.batting_average, p.strike_rate, p.wickets, p.team_id
       FROM players p WHERE p.team_id = ? ORDER BY id DESC`,
      [team.id]
    );

    if (process.env.LOG_LEVEL === 'debug') {
      req.log?.debug("getMyTeam: Successfully retrieved team with players", { 
        teamId: team.id, 
        playerCount: playerRows.length 
      });
    }

    res.json({ ...team, players: playerRows });
  } catch (err) {
    logDatabaseError(req.log, "getMyTeam", err, { userId: req.user?.id });
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Update team info (also sets captain/vice-captain players)
const updateMyTeam = async (req, res) => {
  const { team_name, team_location, captain_player_id, vice_captain_player_id, clear_captain, clear_vice_captain } = req.body;
  let { team_logo_url } = req.body; // Use let for team_logo_url to allow reassignment

  if (!team_name && !team_location && !captain_player_id && !vice_captain_player_id && 
      !clear_captain && !clear_vice_captain && team_logo_url === undefined) {
    return res.status(400).json({ error: "At least one field must be provided for update" });
  }

  // Validate team logo URL if provided
  if (team_logo_url !== undefined && team_logo_url !== null) {
    const urlValidation = validateTeamLogoUrl(team_logo_url);
    if (!urlValidation.isValid) {
      return res.status(400).json({ error: `Invalid team logo URL: ${urlValidation.error}` });
    }
    // Use normalized URL
    team_logo_url = urlValidation.normalizedUrl;
  }

  // Validate captain and vice captain are different if both provided
  if (captain_player_id && vice_captain_player_id && captain_player_id === vice_captain_player_id) {
    return res.status(400).json({ error: "Captain and Vice Captain must be different players" });
  }

  try {
    // First check if user owns a team
    const [teamRows] = await db.query(
      "SELECT id FROM teams WHERE owner_id = ?",
      [req.user.id]
    );

    if (teamRows.length === 0) {
      return res.status(404).json({ error: "Team not found" });
    }

    const teamId = teamRows[0].id;

    // Validate captain and vice captain belong to the team if provided
    if (captain_player_id) {
      const [captainRows] = await db.query(
        "SELECT id FROM players WHERE id = ? AND team_id = ?",
        [captain_player_id, teamId]
      );
      if (captainRows.length === 0) {
        return res.status(400).json({ error: "Captain must be a player on your team" });
      }
    }

    if (vice_captain_player_id) {
      const [viceRows] = await db.query(
        "SELECT id FROM players WHERE id = ? AND team_id = ?",
        [vice_captain_player_id, teamId]
      );
      if (viceRows.length === 0) {
        return res.status(400).json({ error: "Vice Captain must be a player on your team" });
      }
    }

    // Build dynamic UPDATE query to only update provided fields
    const updateFields = [];
    const updateValues = [];
    
    if (team_name !== undefined && team_name !== null && team_name !== '') {
      updateFields.push('team_name = ?');
      updateValues.push(team_name);
    }
    
    if (team_location !== undefined && team_location !== null && team_location !== '') {
      updateFields.push('team_location = ?');
      updateValues.push(team_location);
    }
    
    if (team_logo_url !== undefined) {
      updateFields.push('team_logo_url = ?');
      updateValues.push(team_logo_url);
    }
    
    // Only update captain/vice-captain if explicitly provided and valid
    if (captain_player_id !== undefined && captain_player_id !== null && captain_player_id !== '') {
      updateFields.push('captain_player_id = ?');
      updateValues.push(captain_player_id);
    } else if (clear_captain === true) {
      updateFields.push('captain_player_id = NULL');
    }
    
    if (vice_captain_player_id !== undefined && vice_captain_player_id !== null && vice_captain_player_id !== '') {
      updateFields.push('vice_captain_player_id = ?');
      updateValues.push(vice_captain_player_id);
    } else if (clear_vice_captain === true) {
      updateFields.push('vice_captain_player_id = NULL');
    }
    
    // Ensure at least one field is being updated
    if (updateFields.length === 0) {
      return res.status(400).json({ error: "No valid fields provided for update" });
    }
    
    updateValues.push(req.user.id);
    
    const [result] = await db.query(
      `UPDATE teams 
       SET ${updateFields.join(', ')}
       WHERE owner_id = ?`,
      updateValues
    );

    if (result.affectedRows === 0) {
      return res.status(500).json({ error: "Failed to update team" });
    }

    // Query the updated team row to return it
    const [updatedRows] = await db.query(
      `SELECT 
         t.id,
         t.team_name,
         t.team_location,
         t.team_logo_url,
         t.captain_player_id,
         t.vice_captain_player_id,
         t.matches_played,
         t.matches_won,
         t.trophies
       FROM teams t
       WHERE t.owner_id = ?
       LIMIT 1`,
      [req.user.id]
    );

    if (updatedRows.length === 0) {
      return res.status(500).json({ error: "Team updated but could not retrieve updated data" });
    }

    res.json({ 
      message: "Team updated successfully",
      team: updatedRows[0]
    });
  } catch (err) {
    logDatabaseError(req.log, "updateMyTeam", err, { userId: req.user?.id });
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Get all teams (public) with optional search
const getAllTeams = async (req, res) => {
  try {
    const { search, page = 1, limit = 50 } = req.query;
    
    // Validate pagination parameters
    const pageNum = Math.max(1, parseInt(page) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(limit) || 50)); // Cap at 100
    const offset = (pageNum - 1) * limitNum;
    
    let query = "SELECT id, team_name, team_location, team_logo_url, matches_played, matches_won, trophies FROM teams";
    let countQuery = "SELECT COUNT(*) as total FROM teams";
    const params = [];
    
    if (search && search.trim()) {
      const searchTerm = `%${search.trim()}%`;
      query += " WHERE team_name LIKE ? OR team_location LIKE ?";
      countQuery += " WHERE team_name LIKE ? OR team_location LIKE ?";
      params.push(searchTerm, searchTerm);
    }
    
    query += " ORDER BY team_name ASC";
    query += " LIMIT ? OFFSET ?";
    params.push(limitNum, offset);
    
    const [rows] = await db.query(query, params);
    const [countResult] = await db.query(countQuery, search && search.trim() ? [params[0], params[1]] : []);
    const total = countResult[0].total;
    
    res.json({
      teams: rows,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        pages: Math.ceil(total / limitNum)
      }
    });
  } catch (err) {
    logDatabaseError(req.log, "getAllTeams", err);
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Get public team by ID
const getTeamById = async (req, res) => {
  try {
    const id = req.params.id_validated; // Use validated parameter
    const [rows] = await db.query(
      "SELECT id, team_name, team_location, team_logo_url, matches_played, matches_won, trophies FROM teams WHERE id = ?", 
      [id]
    );
    if (rows.length === 0) return res.status(404).json({ error: "Team not found" });
    res.json(rows[0]);
  } catch (err) {
    logDatabaseError(req.log, "getTeamById", err, { teamId: req.params.id });
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Delete team (only if not participating in tournaments)
const deleteMyTeam = async (req, res) => {
  try {
    if (!req.user || !req.user.id) {
      req.log?.warn("deleteMyTeam: No user in request");
      return res.status(401).json({ error: "Authentication required" });
    }

    // Check if user owns a team
    const [teamRows] = await db.query(
      "SELECT id FROM teams WHERE owner_id = ?",
      [req.user.id]
    );

    if (teamRows.length === 0) {
      req.log?.warn("deleteMyTeam: No team found for user", { userId: req.user.id });
      return res.status(404).json({ error: "Team not found" });
    }

    const teamId = teamRows[0].id;

    // Check if team has any matches or tournament participation in a single optimized query
    const [constraintRows] = await db.query(
      `SELECT 
        (SELECT COUNT(*) FROM tournament_teams WHERE team_id = ?) as tournament_count,
        (SELECT COUNT(*) FROM matches WHERE team1_id = ? OR team2_id = ?) as match_count,
        (SELECT COUNT(*) FROM tournament_matches WHERE team1_id = ? OR team2_id = ?) as tournament_match_count`,
      [teamId, teamId, teamId, teamId, teamId]
    );

    const constraints = constraintRows[0];
    
    if (constraints.tournament_count > 0) {
      req.log?.warn("deleteMyTeam: Cannot delete team participating in tournaments", { 
        teamId, 
        tournamentCount: constraints.tournament_count 
      });
      return res.status(400).json({ 
        error: "Cannot delete team that is participating in tournaments. Please withdraw from all tournaments first." 
      });
    }

    if (constraints.match_count > 0) {
      req.log?.warn("deleteMyTeam: Cannot delete team with match history", { 
        teamId, 
        matchCount: constraints.match_count 
      });
      return res.status(400).json({ 
        error: "Cannot delete team that has match history." 
      });
    }

    if (constraints.tournament_match_count > 0) {
      req.log?.warn("deleteMyTeam: Cannot delete team with tournament match history", { 
        teamId, 
        tournamentMatchCount: constraints.tournament_match_count 
      });
      return res.status(400).json({ 
        error: "Cannot delete team that has tournament match history." 
      });
    }

    // Delete team (players will be deleted via CASCADE)
    await db.query("DELETE FROM teams WHERE id = ?", [teamId]);

    req.log?.info("deleteMyTeam: Successfully deleted team", { teamId, userId: req.user.id });
    res.json({ message: "Team deleted successfully" });
  } catch (err) {
    logDatabaseError(req.log, "deleteMyTeam", err, { userId: req.user?.id });
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = { getMyTeam, updateMyTeam, getAllTeams, getTeamById, deleteMyTeam };
