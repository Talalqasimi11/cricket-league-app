const pool = require("../config/db");

// 📌 Get captain's own team
const getMyTeam = async (req, res) => {
  try {
    const [rows] = await pool.query(
      "SELECT * FROM teams WHERE captain_id = ?",
      [req.user.id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: "No team found for this captain" });
    }

    res.json(rows[0]);
  } catch (err) {
    console.error("❌ Error in getMyTeam:", err);
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Update team info
const updateMyTeam = async (req, res) => {
  const { team_name, team_location } = req.body;

  if (!team_name || !team_location) {
    return res.status(400).json({ error: "Team name and location are required" });
  }

  try {
    const [result] = await pool.query(
      "UPDATE teams SET team_name = ?, team_location = ? WHERE captain_id = ?",
      [team_name, team_location, req.user.id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "No team found to update" });
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
      "SELECT id, team_name, team_location, matches_played, matches_won, trophies FROM teams"
    );
    res.json(rows);
  } catch (err) {
    console.error("❌ Error in getAllTeams:", err);
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = { getMyTeam, updateMyTeam, getAllTeams };
