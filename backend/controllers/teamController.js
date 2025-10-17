const db = require("../config/db");

// 📌 Get owner's own team (backward compatible with historical captain_id)
const getMyTeam = async (req, res) => {
  console.log("🚀 getMyTeam called!");
  try {
    if (!req.user || !req.user.id) {
      console.log("❌ No user in request:", req.user);
      return res.status(401).json({ error: "Authentication required" });
    }

    console.log("🔍 getMyTeam - User ID:", req.user.id, "Type:", typeof req.user.id);
    console.log("🔍 getMyTeam - User object:", req.user);

    const [rows] = await db.query(
      `SELECT 
         t.*, 
         u.phone_number AS owner_phone
       FROM teams t
       LEFT JOIN users u ON t.owner_id = u.id
       WHERE t.owner_id = ?
       LIMIT 1`,
      [req.user.id]
    );

    console.log("🔍 getMyTeam - Query result length:", rows.length);
    console.log("🔍 getMyTeam - Query result:", rows);

    if (rows.length === 0) {
      console.log("❌ No team found for user ID:", req.user.id);
      return res.status(404).json({ error: "Team not found" });
    }

    console.log("✅ Team found for user ID:", req.user.id);
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
    const [result] = await db.query(
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
    const [rows] = await db.query(
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
    const [rows] = await db.query("SELECT * FROM teams WHERE id = ?", [id]);
    if (rows.length === 0) return res.status(404).json({ error: "Team not found" });
    res.json(rows[0]);
  } catch (err) {
    console.error("❌ Error in getTeamById:", err);
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = { getMyTeam, updateMyTeam, getAllTeams, getTeamById };
