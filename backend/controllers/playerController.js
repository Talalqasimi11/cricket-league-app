const pool = require("../config/db");

// Allowed cricket roles (to avoid DB enum/length errors)
const ALLOWED_ROLES = ["Batsman", "Bowler", "All-rounder", "Wicket-keeper", "Wicketkeeper"];

// 📌 Add new player (captain only)
const addPlayer = async (req, res) => {
  const { player_name, player_role, player_image_url } = req.body; // ✅ ADDED player_image_url

  if (!player_name || !player_role) {
    return res.status(400).json({ error: "Player name and role are required" });
  }

  const normalizedRole = String(player_role).trim();
  if (!ALLOWED_ROLES.includes(normalizedRole)) {
    return res.status(400).json({
      error: `Invalid player role. Allowed roles: ${ALLOWED_ROLES.join(", ")}`,
    });
  }

  try {
    // get captain's team
    const [teamRows] = await pool.query(
      "SELECT id FROM teams WHERE owner_id = ? OR captain_id = ?",
      [req.user.id, req.user.id]
    );

    if (teamRows.length === 0) {
      return res.status(404).json({ error: "No team found for this captain" });
    }

    const teamId = teamRows[0].id;

    // insert player (all stats default 0)
    // ✅ ADDED player_image_url to INSERT statement
    const [result] = await pool.query(
      `INSERT INTO players 
       (player_name, player_role, player_image_url, runs, matches_played, hundreds, fifties, batting_average, strike_rate, wickets, team_id) 
       VALUES (?, ?, ?, 0, 0, 0, 0, 0, 0, 0, ?)`,
      [player_name, normalizedRole, player_image_url || null, teamId]
    );

    // ✅ Return full created player object for RESTful response
    const [rows] = await pool.query(`SELECT * FROM players WHERE id = ?`, [result.insertId]);
    res.status(201).json(rows[0]);
  } catch (err) {
    console.error("❌ Error in addPlayer:", err);
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Get all players of captain's team
const getMyPlayers = async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT p.* FROM players p 
       JOIN teams t ON p.team_id = t.id 
       WHERE (t.owner_id = ? OR t.captain_id = ?)`,
      [req.user.id, req.user.id]
    );

    res.json(rows);
  } catch (err) {
    console.error("❌ Error in getMyPlayers:", err);
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Update player info
const updatePlayer = async (req, res) => {
  const { playerId, player_name, player_role, player_image_url, runs, matches_played, hundreds, fifties, batting_average, strike_rate, wickets } = req.body; // ✅ ADDED player_image_url

  if (!playerId) {
    return res.status(400).json({ error: "playerId is required" });
  }

  // If role is provided, validate it against allowed list
  let roleToUse = player_role;
  if (roleToUse !== undefined) {
    roleToUse = String(roleToUse).trim();
    if (!ALLOWED_ROLES.includes(roleToUse)) {
      return res.status(400).json({
        error: `Invalid player role. Allowed roles: ${ALLOWED_ROLES.join(", ")}`,
      });
    }
  }

  try {
    // ✅ Single UPDATE with ownership check via JOIN; also updates player_image_url
    const [result] = await pool.query(
      `UPDATE players p
       JOIN teams t ON p.team_id = t.id
       SET p.player_name = ?, p.player_role = ?, p.player_image_url = ?, p.runs = ?, p.matches_played = ?, 
           p.hundreds = ?, p.fifties = ?, p.batting_average = ?, p.strike_rate = ?, p.wickets = ? 
       WHERE p.id = ? AND (t.owner_id = ? OR t.captain_id = ?)`,
      [player_name, roleToUse, player_image_url, runs, matches_played, hundreds, fifties, batting_average, strike_rate, wickets, playerId, req.user.id, req.user.id]
    );

    if (result.affectedRows === 0) {
      return res.status(403).json({ error: "Not allowed to update this player or player not found" });
    }

    const [updated] = await pool.query(
      `SELECT p.* FROM players p JOIN teams t ON p.team_id = t.id WHERE p.id = ? AND (t.owner_id = ? OR t.captain_id = ?)`,
      [playerId, req.user.id, req.user.id]
    );

    res.json({ message: "Player updated successfully", player: updated[0] });
  } catch (err) {
    console.error("❌ Error in updatePlayer:", err);
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Delete player
const deletePlayer = async (req, res) => {
  const { playerId } = req.body;

  if (!playerId) {
    return res.status(400).json({ error: "playerId is required" });
  }

  try {
    const [rows] = await pool.query(
      `SELECT p.id 
       FROM players p 
       JOIN teams t ON p.team_id = t.id 
       WHERE p.id = ? AND (t.owner_id = ? OR t.captain_id = ?)`,
      [playerId, req.user.id, req.user.id]
    );

    if (rows.length === 0) {
      return res.status(403).json({ error: "Not allowed to delete this player" });
    }

    await pool.query("DELETE FROM players WHERE id = ?", [playerId]);

    res.json({ message: "Player deleted successfully" });
  } catch (err) {
    console.error("❌ Error in deletePlayer:", err);
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Public: Get players by team_id
const getPlayersByTeamId = async (req, res) => {
  try {
    const { team_id } = req.params;
    const [rows] = await pool.query(
      `SELECT * FROM players WHERE team_id = ? ORDER BY id DESC`,
      [team_id]
    );
    res.json(rows);
  } catch (err) {
    console.error("❌ Error in getPlayersByTeamId:", err);
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = { addPlayer, getMyPlayers, updatePlayer, deletePlayer, getPlayersByTeamId };