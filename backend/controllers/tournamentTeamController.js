const pool = require("../config/db");

// 📌 Add a team to a tournament (registered OR temporary)
const addTournamentTeam = async (req, res) => {
  const { tournament_id, team_id, temp_team_name, temp_team_location } = req.body;

  if (!tournament_id || (!team_id && !temp_team_name)) {
    return res.status(400).json({ error: "Tournament ID and either team_id or temp_team_name are required" });
  }

  try {
    // ✅ Check ownership (only tournament creator can add teams)
    const [tournament] = await pool.query(
      "SELECT * FROM tournaments WHERE id = ? AND created_by = ?",
      [tournament_id, req.user.id]
    );
    if (tournament.length === 0) {
      return res.status(403).json({ error: "Not allowed to modify this tournament" });
    }

    // ✅ Prevent duplicate registered team
    if (team_id) {
      const [exists] = await pool.query(
        "SELECT * FROM tournament_teams WHERE tournament_id = ? AND team_id = ?",
        [tournament_id, team_id]
      );
      if (exists.length > 0) {
        return res.status(400).json({ error: "This team is already added to the tournament" });
      }
    }

    // ✅ Prevent duplicate temporary team (by name+location)
    if (temp_team_name) {
      const [exists] = await pool.query(
        "SELECT * FROM tournament_teams WHERE tournament_id = ? AND temp_team_name = ? AND temp_team_location = ?",
        [tournament_id, temp_team_name, temp_team_location]
      );
      if (exists.length > 0) {
        return res.status(400).json({ error: "This temporary team is already added" });
      }
    }

    // ✅ Insert
    const [result] = await pool.query(
      `INSERT INTO tournament_teams (tournament_id, team_id, temp_team_name, temp_team_location) 
       VALUES (?, ?, ?, ?)`,
      [tournament_id, team_id || null, temp_team_name || null, temp_team_location || null]
    );

    res.status(201).json({ message: "Team added successfully", id: result.insertId });
  } catch (err) {
    console.error("❌ Error in addTournamentTeam:", err);
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Get all teams of a tournament
const getTournamentTeams = async (req, res) => {
  const { tournament_id } = req.params;

  try {
    const [rows] = await pool.query(
      `SELECT tt.id, 
              tt.tournament_id, 
              t.team_name, 
              t.team_location, 
              tt.temp_team_name, 
              tt.temp_team_location
       FROM tournament_teams tt
       LEFT JOIN teams t ON tt.team_id = t.id
       WHERE tt.tournament_id = ?`,
      [tournament_id]
    );

    res.json(rows);
  } catch (err) {
    console.error("❌ Error in getTournamentTeams:", err);
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Update tournament team (for temporary teams only)
const updateTournamentTeam = async (req, res) => {
  const { id, tournament_id, temp_team_name, temp_team_location } = req.body;

  if (!id || !tournament_id) {
    return res.status(400).json({ error: "Tournament team id and tournament_id are required" });
  }

  try {
    // ✅ Check ownership (only creator can update)
    const [tournament] = await pool.query(
      "SELECT * FROM tournaments WHERE id = ? AND created_by = ?",
      [tournament_id, req.user.id]
    );
    if (tournament.length === 0) {
      return res.status(403).json({ error: "Not allowed to update this tournament" });
    }

    // ✅ Ensure it's a temporary team (registered teams cannot be updated)
    const [team] = await pool.query(
      "SELECT * FROM tournament_teams WHERE id = ? AND tournament_id = ?",
      [id, tournament_id]
    );
    if (team.length === 0) {
      return res.status(404).json({ error: "Tournament team not found" });
    }
    if (team[0].team_id) {
      return res.status(400).json({ error: "Registered teams cannot be updated" });
    }

    // ✅ Prevent duplicate name+location
    const [exists] = await pool.query(
      `SELECT * FROM tournament_teams 
       WHERE tournament_id = ? AND temp_team_name = ? AND temp_team_location = ? AND id != ?`,
      [tournament_id, temp_team_name, temp_team_location, id]
    );
    if (exists.length > 0) {
      return res.status(400).json({ error: "Another temporary team with same name & location exists" });
    }

    // ✅ Update team
    await pool.query(
      "UPDATE tournament_teams SET temp_team_name = ?, temp_team_location = ? WHERE id = ?",
      [temp_team_name, temp_team_location, id]
    );

    res.json({ message: "Tournament team updated successfully" });
  } catch (err) {
    console.error("❌ Error in updateTournamentTeam:", err);
    res.status(500).json({ error: "Server error" });
  }
};



// 📌 Delete a team from tournament (only creator)
const deleteTournamentTeam = async (req, res) => {
  const { id, tournament_id } = req.body;

  if (!id || !tournament_id) {
    return res.status(400).json({ error: "Tournament team id and tournament_id are required" });
  }

  try {
    // ✅ Ownership check
    const [tournament] = await pool.query(
      "SELECT * FROM tournaments WHERE id = ? AND created_by = ?",
      [tournament_id, req.user.id]
    );
    if (tournament.length === 0) {
      return res.status(403).json({ error: "Not allowed to delete from this tournament" });
    }

    await pool.query("DELETE FROM tournament_teams WHERE id = ?", [id]);

    res.json({ message: "Tournament team deleted successfully" });
  } catch (err) {
    console.error("❌ Error in deleteTournamentTeam:", err);
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = {
  addTournamentTeam,
  getTournamentTeams,
  deleteTournamentTeam,
  updateTournamentTeam, // ✅ export new method
};