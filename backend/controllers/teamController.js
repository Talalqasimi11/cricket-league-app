const pool = require("../config/db");

// 📌 Get owner's own team (backward compatible with historical captain_id)
const getMyTeam = async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT 
         t.*, 
         COALESCE(u_owner.phone_number, u_cap.phone_number) AS owner_phone,
         COALESCE(u_owner.captain_name, u_cap.captain_name, u_owner.phone_number, u_cap.phone_number) AS owner_name,
         pc.player_name AS captain_name,
         pv.player_name AS vice_captain_name
       FROM teams t
       LEFT JOIN users u_owner ON t.owner_id = u_owner.id
       LEFT JOIN users u_cap ON t.captain_id = u_cap.id
       LEFT JOIN players pc ON t.captain_player_id = pc.id
       LEFT JOIN players pv ON t.vice_captain_player_id = pv.id
       WHERE (t.owner_id = ? OR t.captain_id = ?)
       LIMIT 1`,
      [req.user.id, req.user.id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: "No team found for this owner" });
    }

    res.json(rows[0]);
  } catch (err) {
    console.error("❌ Error in getMyTeam:", err);
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Update team info (also sets captain/vice-captain players)
const updateMyTeam = async (req, res) => {
  const { team_name, team_location, team_logo_url, captain_player_id, vice_captain_player_id } = req.body; // ✅ ADDED team_logo_url

  if (!team_name || !team_location) {
    return res.status(400).json({ error: "Team name and location are required" });
  }

  try {
    // ✅ Single UPDATE using ownership in WHERE and validating captain/vice via EXISTS; includes team_logo_url
    const [result] = await pool.query(
      `UPDATE teams t
       SET 
         t.team_name = ?,
         t.team_location = ?,
         t.team_logo_url = COALESCE(?, t.team_logo_url),
         t.captain_player_id = CASE 
            WHEN ? IS NULL THEN t.captain_player_id 
            WHEN EXISTS (SELECT 1 FROM players p WHERE p.id = ? AND p.team_id = t.id) THEN ?
            ELSE t.captain_player_id END,
         t.vice_captain_player_id = CASE 
            WHEN ? IS NULL THEN t.vice_captain_player_id 
            WHEN EXISTS (SELECT 1 FROM players p WHERE p.id = ? AND p.team_id = t.id) THEN ?
            ELSE t.vice_captain_player_id END
       WHERE (t.owner_id = ? OR t.captain_id = ?)
         AND ( ? IS NULL OR ? IS NULL OR ? <> ? )`,
      [
        team_name,
        team_location,
        team_logo_url,
        captain_player_id, captain_player_id, captain_player_id,
        vice_captain_player_id, vice_captain_player_id, vice_captain_player_id,
        req.user.id, req.user.id,
        captain_player_id, vice_captain_player_id, captain_player_id, vice_captain_player_id
      ]
    );

    if (result.affectedRows === 0) {
      return res.status(403).json({ error: "No team found or invalid captain/vice selection" });
    }

    res.json({ message: "Team updated successfully" });
  } catch (err) {
    console.error("❌ Error in updateMyTeam:", err);
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Get all teams (public)
const getAllTeams = async (req, res) => {
  try {
    const [rows] = await pool.query(
      "SELECT id, team_name, team_location, team_logo_url, matches_played, matches_won, trophies FROM teams" // ✅ ADDED team_logo_url
    );
    res.json(rows);
  } catch (err) {
    console.error("❌ Error in getAllTeams:", err);
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Get public team by ID
const getTeamById = async (req, res) => {
  try {
    const { id } = req.params;
    const [rows] = await pool.query("SELECT * FROM teams WHERE id = ?", [id]);
    if (rows.length === 0) return res.status(404).json({ error: "Team not found" });
    res.json(rows[0]);
  } catch (err) {
    console.error("❌ Error in getTeamById:", err);
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = { getMyTeam, updateMyTeam, getAllTeams, getTeamById };