const db = require("../config/db");
const { logDatabaseError } = require("../utils/safeLogger");

// 📌 Add a team to a tournament (registered OR temporary)
const addTournamentTeam = async (req, res) => {
  const { tournament_id, team_id, temp_team_name, temp_team_location } = req.body;

  if (!tournament_id || (!team_id && (!temp_team_name || !temp_team_location))) {
    return res.status(400).json({
      success: false,
      error: "Tournament ID and either team_id OR (temp_team_name + temp_team_location) are required",
    });
  }

  try {
    // ✅ Check ownership
    const [tournament] = await db.query(
      "SELECT * FROM tournaments WHERE id = ? AND created_by = ?",
      [tournament_id, req.user.id]
    );
    if (tournament.length === 0) {
      return res.status(403).json({ success: false, error: "Not allowed to modify this tournament" });
    }

    // ✅ Status restriction
    if (tournament[0].status !== "upcoming") {
      return res.status(400).json({ success: false, error: "Cannot add teams once tournament has started" });
    }

    // ✅ Prevent duplicate registered team and validate team exists
    if (team_id) {
      // First validate that the team exists
      const [teamExists] = await db.query(
        "SELECT id FROM teams WHERE id = ?",
        [team_id]
      );
      if (teamExists.length === 0) {
        return res.status(404).json({ success: false, error: "Team not found" });
      }

      // Then check for duplicates
      const [exists] = await db.query(
        "SELECT id FROM tournament_teams WHERE tournament_id = ? AND team_id = ?",
        [tournament_id, team_id]
      );
      if (exists.length > 0) {
        return res.status(400).json({ success: false, error: "This team is already added" });
      }
    }

    // ✅ Prevent duplicate temporary team (case-insensitive)
    if (temp_team_name && temp_team_location) {
      const [exists] = await db.query(
        "SELECT id FROM tournament_teams WHERE tournament_id = ? AND LOWER(temp_team_name) = LOWER(?) AND LOWER(temp_team_location) = LOWER(?)",
        [tournament_id, temp_team_name.trim(), temp_team_location.trim()]
      );
      if (exists.length > 0) {
        return res.status(400).json({ success: false, error: "This temporary team already exists" });
      }
    }

    // ✅ Insert (normalize temp team data)
    const [result] = await db.query(
      `INSERT INTO tournament_teams (tournament_id, team_id, temp_team_name, temp_team_location) 
       VALUES (?, ?, ?, ?)`,
      [tournament_id, team_id || null, temp_team_name?.trim() || null, temp_team_location?.trim() || null]
    );

    res.status(201).json({
      success: true,
      message: "Team added successfully",
      id: result.insertId,
    });
  } catch (err) {
    logDatabaseError(req.log, "addTournamentTeam", err, { tournamentId: tournament_id, teamId: team_id });
    res.status(500).json({ success: false, error: "Server error" });
  }
};

// 📌 Get all teams of a tournament
const getTournamentTeams = async (req, res) => {
  const { tournament_id } = req.params;

  try {
    const [rows] = await db.query(
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

    res.json({ success: true, data: rows });
  } catch (err) {
    logDatabaseError(req.log, "getTournamentTeams", err, { tournamentId: tournament_id });
    res.status(500).json({ success: false, error: "Server error" });
  }
};

// 📌 Update tournament team (temporary only)
const updateTournamentTeam = async (req, res) => {
  const { id, tournament_id, temp_team_name, temp_team_location } = req.body;

  if (!id || !tournament_id) {
    return res.status(400).json({ success: false, error: "Tournament team id and tournament_id are required" });
  }

  try {
    // ✅ Ownership
    const [tournament] = await db.query(
      "SELECT * FROM tournaments WHERE id = ? AND created_by = ?",
      [tournament_id, req.user.id]
    );
    if (tournament.length === 0) {
      return res.status(403).json({ success: false, error: "Not allowed to update this tournament" });
    }
    if (tournament[0].status !== "upcoming") {
      return res.status(400).json({ success: false, error: "Cannot update teams once tournament has started" });
    }

    // ✅ Ensure team exists & is temporary
    const [team] = await db.query(
      "SELECT * FROM tournament_teams WHERE id = ? AND tournament_id = ?",
      [id, tournament_id]
    );
    if (team.length === 0) {
      return res.status(404).json({ success: false, error: "Tournament team not found" });
    }
    if (team[0].team_id) {
      return res.status(400).json({ success: false, error: "Registered teams cannot be updated" });
    }

    // ✅ Prevent duplicates
    const [exists] = await db.query(
      `SELECT id FROM tournament_teams 
       WHERE tournament_id = ? AND temp_team_name = ? AND temp_team_location = ? AND id != ?`,
      [tournament_id, temp_team_name, temp_team_location, id]
    );
    if (exists.length > 0) {
      return res.status(400).json({ success: false, error: "Another temporary team with same name & location exists" });
    }

    await db.query(
      "UPDATE tournament_teams SET temp_team_name = ?, temp_team_location = ? WHERE id = ?",
      [temp_team_name, temp_team_location, id]
    );

    res.json({ success: true, message: "Tournament team updated successfully" });
  } catch (err) {
    logDatabaseError(req.log, "updateTournamentTeam", err, { tournamentId: tournament_id, teamId: id });
    res.status(500).json({ success: false, error: "Server error" });
  }
};

// 📌 Delete a team from tournament
const deleteTournamentTeam = async (req, res) => {
  const { id, tournament_id } = req.body;

  if (!id || !tournament_id) {
    return res.status(400).json({ success: false, error: "Tournament team id and tournament_id are required" });
  }

  try {
    // ✅ Ownership
    const [tournament] = await db.query(
      "SELECT * FROM tournaments WHERE id = ? AND created_by = ?",
      [tournament_id, req.user.id]
    );
    if (tournament.length === 0) {
      return res.status(403).json({ success: false, error: "Not allowed to delete from this tournament" });
    }
    if (tournament[0].status !== "upcoming") {
      return res.status(400).json({ success: false, error: "Cannot delete teams once tournament has started" });
    }

    // ✅ Prevent deletion if team already in tournament matches
    const [used] = await db.query(
      "SELECT id FROM tournament_matches WHERE (team1_tt_id = ? OR team2_tt_id = ?) AND tournament_id = ? LIMIT 1",
      [id, id, tournament_id]
    );
    if (used.length > 0) {
      return res.status(400).json({ success: false, error: "Cannot delete team, matches already exist" });
    }

    await db.query("DELETE FROM tournament_teams WHERE id = ?", [id]);

    res.json({ success: true, message: "Tournament team deleted successfully" });
  } catch (err) {
    logDatabaseError(req.log, "deleteTournamentTeam", err, { tournamentId: tournament_id, teamId: id });
    res.status(500).json({ success: false, error: "Server error" });
  }
};

module.exports = {
  addTournamentTeam,
  getTournamentTeams,
  updateTournamentTeam,
  deleteTournamentTeam,
};
