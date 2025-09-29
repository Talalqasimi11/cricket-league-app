const pool = require("../config/db");

// 📌 Add new player (captain only)
const addPlayer = async (req, res) => {
  const { player_name, player_role } = req.body;

  if (!player_name || !player_role) {
    return res.status(400).json({ error: "Player name and role are required" });
  }

  try {
    // get captain's team
    const [teamRows] = await pool.query(
      "SELECT id FROM teams WHERE captain_id = ?",
      [req.user.id]
    );

    if (teamRows.length === 0) {
      return res.status(404).json({ error: "No team found for this captain" });
    }

    const teamId = teamRows[0].id;

    // insert player
    const [result] = await pool.query(
      "INSERT INTO players (player_name, player_role, runs, matches_played, hundreds, fifties, team_id) VALUES (?, ?, 0, 0, 0, 0, ?)",
      [player_name, player_role, teamId]
    );

    res.status(201).json({ message: "Player added successfully", playerId: result.insertId });
  } catch (err) {
    console.error("❌ Error in addPlayer:", err);
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Get all players of captain's team
const getMyPlayers = async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT p.* 
       FROM players p 
       JOIN teams t ON p.team_id = t.id 
       WHERE t.captain_id = ?`,
      [req.user.id]
    );

    res.json(rows);
  } catch (err) {
    console.error("❌ Error in getMyPlayers:", err);
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Update player info
const updatePlayer = async (req, res) => {
  const { playerId, player_name, player_role, runs, matches_played, hundreds, fifties } = req.body;

  if (!playerId) {
    return res.status(400).json({ error: "playerId is required" });
  }

  try {
    // ensure player belongs to this captain
    const [rows] = await pool.query(
      `SELECT p.id 
       FROM players p 
       JOIN teams t ON p.team_id = t.id 
       WHERE p.id = ? AND t.captain_id = ?`,
      [playerId, req.user.id]
    );

    if (rows.length === 0) {
      return res.status(403).json({ error: "Not allowed to update this player" });
    }

    await pool.query(
      `UPDATE players 
       SET player_name = ?, player_role = ?, runs = ?, matches_played = ?, hundreds = ?, fifties = ? 
       WHERE id = ?`,
      [player_name, player_role, runs, matches_played, hundreds, fifties, playerId]
    );

    res.json({ message: "Player updated successfully" });
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
       WHERE p.id = ? AND t.captain_id = ?`,
      [playerId, req.user.id]
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

module.exports = { addPlayer, getMyPlayers, updatePlayer, deletePlayer };
