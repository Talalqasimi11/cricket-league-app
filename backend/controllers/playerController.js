const db = require("../config/db");
const { validateSingleNumericParam } = require("../utils/inputValidation");
const { validatePlayerImageUrl } = require("../utils/urlValidation");
const { logDatabaseError } = require("../utils/safeLogger");

// Allowed cricket roles (to avoid DB enum/length errors)
const ALLOWED_ROLES = ["Batsman", "Bowler", "All-rounder", "Wicket-keeper"];

// Map legacy role values to canonical DB values
const ROLE_MAPPING = {
  "Wicketkeeper": "Wicket-keeper",
  "wicketkeeper": "Wicket-keeper",
  "wicket-keeper": "Wicket-keeper",
  "Wicket keeper": "Wicket-keeper"
};

// Normalize role to canonical DB value
const normalizeRole = (role) => {
  if (!role) return null;
  const normalized = role.trim();
  return ROLE_MAPPING[normalized] || normalized;
};

// 📌 Add new player (captain only)
const addPlayer = async (req, res) => {
  const { player_name, player_role } = req.body;
  let { player_image_url } = req.body; // Use let for player_image_url to allow reassignment

  if (!player_name || !player_role) {
    return res.status(400).json({ error: "Player name and role are required" });
  }

  // Validate player image URL if provided
  if (player_image_url !== undefined && player_image_url !== null) {
    const urlValidation = validatePlayerImageUrl(player_image_url);
    if (!urlValidation.isValid) {
      return res.status(400).json({ error: `Invalid player image URL: ${urlValidation.error}` });
    }
    // Use normalized URL
    player_image_url = urlValidation.normalizedUrl;
  }

  const normalizedRole = normalizeRole(player_role);
  // Case-insensitive normalization
  const roleToCheck = ALLOWED_ROLES.find(role => 
    role.toLowerCase() === normalizedRole.toLowerCase()
  );
  
  if (!roleToCheck) {
    return res.status(400).json({
      error: `Invalid player role. Allowed roles: ${ALLOWED_ROLES.join(", ")}`,
    });
  }

  try {
    // get user's team (only owner can add players)
    const [teamRows] = await db.query(
      "SELECT id FROM teams WHERE owner_id = ?",
      [req.user.id]
    );

    if (teamRows.length === 0) {
      return res.status(404).json({ error: "No team found for this user" });
    }

    const teamId = teamRows[0].id;

    // insert player (all stats default 0)
    // ✅ ADDED player_image_url to INSERT statement
    const [result] = await db.query(
      `INSERT INTO players 
       (player_name, player_role, player_image_url, runs, matches_played, hundreds, fifties, batting_average, strike_rate, wickets, team_id) 
       VALUES (?, ?, ?, 0, 0, 0, 0, 0, 0, 0, ?)`,
      [player_name, roleToCheck, player_image_url || null, teamId]
    );

    // ✅ Return full created player object for RESTful response
    const [rows] = await db.query(
      `SELECT 
         id, player_name, player_role, player_image_url, runs, matches_played, 
         hundreds, fifties, batting_average, strike_rate, wickets, team_id
       FROM players WHERE id = ?`, 
      [result.insertId]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    logDatabaseError(req.log, "addPlayer", err, { userId: req.user?.id });
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Get all players of user's team
const getMyPlayers = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT 
         p.id, p.player_name, p.player_role, p.player_image_url, p.runs, p.matches_played, 
         p.hundreds, p.fifties, p.batting_average, p.strike_rate, p.wickets, p.team_id
       FROM players p 
       JOIN teams t ON p.team_id = t.id 
       WHERE t.owner_id = ?`,
      [req.user.id]
    );

    res.json(rows);
  } catch (err) {
    logDatabaseError(req.log, "getMyPlayers", err, { userId: req.user?.id });
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Update player info
const updatePlayer = async (req, res) => {
  const playerId = req.params.id_validated; // Use validated parameter
  const { player_name, runs, matches_played, hundreds, fifties, batting_average, strike_rate, wickets } = req.body;
  let { player_image_url } = req.body; // Use let for player_image_url to allow reassignment
  let { player_role } = req.body; // Use let for player_role to allow reassignment

  // Validate numeric fields if provided
  const numericFields = { runs, matches_played, hundreds, fifties, batting_average, strike_rate, wickets };
  for (const [field, value] of Object.entries(numericFields)) {
    if (value !== undefined && (isNaN(Number(value)) || Number(value) < 0)) {
      return res.status(400).json({ error: `${field} must be a non-negative number` });
    }
  }

  // Validate string lengths if provided
  if (player_name !== undefined && (typeof player_name !== 'string' || player_name.trim().length === 0)) {
    return res.status(400).json({ error: "Player name must be a non-empty string" });
  }

  // Validate player image URL if provided
  if (player_image_url !== undefined && player_image_url !== null) {
    const urlValidation = validatePlayerImageUrl(player_image_url);
    if (!urlValidation.isValid) {
      return res.status(400).json({ error: `Invalid player image URL: ${urlValidation.error}` });
    }
    // Use normalized URL
    player_image_url = urlValidation.normalizedUrl;
  }

  // If role is provided, validate it against allowed list
  let roleToUse = player_role;
  if (roleToUse !== undefined) {
    roleToUse = normalizeRole(roleToUse);
    const roleToCheck = ALLOWED_ROLES.find(role => 
      role.toLowerCase() === roleToUse.toLowerCase()
    );
    
    if (!roleToCheck) {
      return res.status(400).json({
        error: `Invalid player role. Allowed roles: ${ALLOWED_ROLES.join(", ")}`,
      });
    }
    roleToUse = roleToCheck;
  }

  try {
    // Build dynamic UPDATE query with only provided fields
    const updateFields = [];
    const updateValues = [];
    
    if (player_name !== undefined) {
      updateFields.push('p.player_name = ?');
      updateValues.push(player_name.trim());
    }
    
    if (roleToUse !== undefined) {
      updateFields.push('p.player_role = ?');
      updateValues.push(roleToUse);
    }
    
    if (player_image_url !== undefined) {
      updateFields.push('p.player_image_url = ?');
      updateValues.push(player_image_url);
    }
    
    if (runs !== undefined) {
      updateFields.push('p.runs = ?');
      updateValues.push(Number(runs));
    }
    
    if (matches_played !== undefined) {
      updateFields.push('p.matches_played = ?');
      updateValues.push(Number(matches_played));
    }
    
    if (hundreds !== undefined) {
      updateFields.push('p.hundreds = ?');
      updateValues.push(Number(hundreds));
    }
    
    if (fifties !== undefined) {
      updateFields.push('p.fifties = ?');
      updateValues.push(Number(fifties));
    }
    
    if (batting_average !== undefined) {
      updateFields.push('p.batting_average = ?');
      updateValues.push(Number(batting_average));
    }
    
    if (strike_rate !== undefined) {
      updateFields.push('p.strike_rate = ?');
      updateValues.push(Number(strike_rate));
    }
    
    if (wickets !== undefined) {
      updateFields.push('p.wickets = ?');
      updateValues.push(Number(wickets));
    }

    if (updateFields.length === 0) {
      return res.status(400).json({ error: "No valid fields provided for update" });
    }

    updateValues.push(playerId, req.user.id);

    // Execute dynamic UPDATE with ownership check
    const [result] = await db.query(
      `UPDATE players p
       JOIN teams t ON p.team_id = t.id
       SET ${updateFields.join(', ')}
       WHERE p.id = ? AND t.owner_id = ?`,
      updateValues
    );

    if (result.affectedRows === 0) {
      return res.status(403).json({ error: "Not allowed to update this player or player not found" });
    }

    // Return updated player data
    const [updated] = await db.query(
      `SELECT 
         p.id, p.player_name, p.player_role, p.player_image_url, p.runs, p.matches_played, 
         p.hundreds, p.fifties, p.batting_average, p.strike_rate, p.wickets, p.team_id
       FROM players p 
       JOIN teams t ON p.team_id = t.id 
       WHERE p.id = ? AND t.owner_id = ?`,
      [playerId, req.user.id]
    );

    res.json({ message: "Player updated successfully", player: updated[0] });
  } catch (err) {
    logDatabaseError(req.log, "updatePlayer", err, { userId: req.user?.id, playerId });
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Delete player
const deletePlayer = async (req, res) => {
  const playerId = req.params.id_validated; // Use validated parameter

  try {
    const [rows] = await db.query(
      `SELECT p.id 
       FROM players p 
       JOIN teams t ON p.team_id = t.id 
       WHERE p.id = ? AND t.owner_id = ?`,
      [playerId, req.user.id]
    );

    if (rows.length === 0) {
      return res.status(403).json({ error: "Not allowed to delete this player" });
    }

    await db.query("DELETE FROM players WHERE id = ?", [playerId]);

    res.json({ message: "Player deleted successfully" });
  } catch (err) {
    logDatabaseError(req.log, "deletePlayer", err, { userId: req.user?.id, playerId });
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Public: Get players by team_id
const getPlayersByTeamId = async (req, res) => {
  try {
    const team_id = req.params.team_id_validated; // Use validated parameter
    const [rows] = await db.query(
      `SELECT 
         id, player_name, player_role, player_image_url, runs, matches_played, 
         hundreds, fifties, batting_average, strike_rate, wickets, team_id
       FROM players WHERE team_id = ? ORDER BY id DESC`,
      [team_id]
    );
    res.json(rows);
  } catch (err) {
    logDatabaseError(req.log, "getPlayersByTeamId", err, { teamId: req.params.team_id });
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = { addPlayer, getMyPlayers, updatePlayer, deletePlayer, getPlayersByTeamId };
