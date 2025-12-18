const { db } = require("../config/db");
const { logDatabaseError } = require("../utils/safeLogger");

// ==========================================
// HELPER: Validate Tournament Access
// ==========================================
const validateTournamentAccess = async (tournamentId, userId, requireUpcoming = true) => {
  const [tournament] = await db.query(
    "SELECT id, status, created_by FROM tournaments WHERE id = ?",
    [tournamentId]
  );

  if (tournament.length === 0) {
    return { valid: false, status: 404, error: "Tournament not found" };
  }

  if (tournament[0].created_by !== userId) {
    return { valid: false, status: 403, error: "Not allowed to modify this tournament" };
  }

  if (requireUpcoming && tournament[0].status !== "upcoming") {
    return { valid: false, status: 400, error: `Cannot modify teams. Tournament status is '${tournament[0].status}'` };
  }

  return { valid: true, tournament: tournament[0] };
};

// ==========================================
// CONTROLLER METHODS
// ==========================================

// 📌 Add a SINGLE team (Registered OR Temporary)
const addTournamentTeam = async (req, res) => {
  const { tournament_id, team_id, temp_team_name, temp_team_location } = req.body;

  if (!tournament_id || (!team_id && (!temp_team_name || !temp_team_location))) {
    return res.status(400).json({
      success: false,
      error: "Tournament ID and either team_id OR (temp_team_name + temp_team_location) are required",
    });
  }

  try {
    // 1. Validate Access
    const access = await validateTournamentAccess(tournament_id, req.user.id);
    if (!access.valid) return res.status(access.status).json({ success: false, error: access.error });

    // 2. Registered Team Logic
    if (team_id) {
      const [teamExists] = await db.query("SELECT id FROM teams WHERE id = ?", [team_id]);
      if (teamExists.length === 0) return res.status(404).json({ success: false, error: "Team not found" });

      const [exists] = await db.query(
        "SELECT id FROM tournament_teams WHERE tournament_id = ? AND team_id = ?",
        [tournament_id, team_id]
      );
      if (exists.length > 0) return res.status(400).json({ success: false, error: "Team already added" });
    }

    // 3. Temporary Team Logic
    if (temp_team_name && temp_team_location) {
      const [exists] = await db.query(
        "SELECT id FROM tournament_teams WHERE tournament_id = ? AND LOWER(temp_team_name) = LOWER(?) AND LOWER(temp_team_location) = LOWER(?)",
        [tournament_id, temp_team_name.trim(), temp_team_location.trim()]
      );
      if (exists.length > 0) return res.status(400).json({ success: false, error: "Temporary team already exists" });
    }

    // 4. Insert
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
    logDatabaseError(req.log, "addTournamentTeam", err, { tournamentId: tournament_id });
    res.status(500).json({ success: false, error: "Server error" });
  }
};

// 📌 Get all teams of a tournament
const getTournamentTeams = async (req, res) => {
  const { tournament_id } = req.params;

  try {
    const [rows] = await db.query(
      `SELECT tt.id, tt.tournament_id, tt.team_id,
              t.team_name, t.team_location, t.team_logo_url,
              tt.temp_team_name, tt.temp_team_location
       FROM tournament_teams tt
       LEFT JOIN teams t ON tt.team_id = t.id
       WHERE tt.tournament_id = ?
       ORDER BY tt.id ASC`,
      [tournament_id]
    );

    res.json({ success: true, data: rows });
  } catch (err) {
    logDatabaseError(req.log, "getTournamentTeams", err, { tournamentId: tournament_id });
    res.status(500).json({ success: false, error: "Server error" });
  }
};

// 📌 Update tournament team (Temporary teams only)
const updateTournamentTeam = async (req, res) => {
  const { id, tournament_id, temp_team_name, temp_team_location } = req.body;

  if (!id || !tournament_id) return res.status(400).json({ success: false, error: "ID and Tournament ID required" });

  try {
    const access = await validateTournamentAccess(tournament_id, req.user.id);
    if (!access.valid) return res.status(access.status).json({ success: false, error: access.error });

    // Check if valid temporary team
    const [team] = await db.query("SELECT * FROM tournament_teams WHERE id = ? AND tournament_id = ?", [id, tournament_id]);

    if (team.length === 0) return res.status(404).json({ success: false, error: "Team not found in tournament" });
    if (team[0].team_id) return res.status(400).json({ success: false, error: "Cannot edit registered teams here" });

    // Check duplicates
    const [exists] = await db.query(
      `SELECT id FROM tournament_teams 
       WHERE tournament_id = ? AND temp_team_name = ? AND temp_team_location = ? AND id != ?`,
      [tournament_id, temp_team_name, temp_team_location, id]
    );
    if (exists.length > 0) return res.status(400).json({ success: false, error: "Duplicate temporary team details" });

    await db.query(
      "UPDATE tournament_teams SET temp_team_name = ?, temp_team_location = ? WHERE id = ?",
      [temp_team_name, temp_team_location, id]
    );

    res.json({ success: true, message: "Team updated successfully" });

  } catch (err) {
    logDatabaseError(req.log, "updateTournamentTeam", err, { tournamentId: tournament_id });
    res.status(500).json({ success: false, error: "Server error" });
  }
};

// 📌 Delete team from tournament
const deleteTournamentTeam = async (req, res) => {
  const { id, tournament_id } = req.body;

  if (!id || !tournament_id) return res.status(400).json({ success: false, error: "Missing required fields" });

  try {
    const access = await validateTournamentAccess(tournament_id, req.user.id);
    if (!access.valid) return res.status(access.status).json({ success: false, error: access.error });

    // Check usage in matches
    const [used] = await db.query(
      "SELECT id FROM tournament_matches WHERE (team1_tt_id = ? OR team2_tt_id = ?) AND tournament_id = ? LIMIT 1",
      [id, id, tournament_id]
    );

    if (used.length > 0) return res.status(400).json({ success: false, error: "Cannot delete team; matches already scheduled" });

    await db.query("DELETE FROM tournament_teams WHERE id = ?", [id]);

    res.json({ success: true, message: "Team removed from tournament" });

  } catch (err) {
    logDatabaseError(req.log, "deleteTournamentTeam", err, { tournamentId: tournament_id });
    res.status(500).json({ success: false, error: "Server error" });
  }
};

// 📌 Bulk Add Teams (Optimized Batch Insert)
const addBulkTournamentTeams = async (req, res) => {
  const { tournament_id, team_ids } = req.body;

  if (!tournament_id || !Array.isArray(team_ids) || team_ids.length === 0) {
    return res.status(400).json({ success: false, error: "Invalid payload" });
  }

  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();

    // 1. Validate Access (Manual check since we are inside transaction)
    const [tournament] = await conn.query(
      "SELECT status, created_by FROM tournaments WHERE id = ?",
      [tournament_id]
    );

    if (tournament.length === 0) {
      await conn.rollback();
      return res.status(404).json({ success: false, error: "Tournament not found" });
    }
    if (tournament[0].created_by !== req.user.id) {
      await conn.rollback();
      return res.status(403).json({ success: false, error: "Permission denied" });
    }
    if (tournament[0].status !== "upcoming") {
      await conn.rollback();
      return res.status(400).json({ success: false, error: "Tournament already started" });
    }

    // 2. Filter out existing teams to prevent duplicates
    const [existing] = await conn.query(
      "SELECT team_id FROM tournament_teams WHERE tournament_id = ?",
      [tournament_id]
    );
    // Convert to strings for consistent comparison
    const existingIds = new Set(existing.map(e => String(e.team_id)));

    // 3. Filter invalid team IDs (that don't exist in teams table)
    const placeholders = team_ids.map(() => '?').join(',');
    const [validTeams] = await conn.query(`SELECT id FROM teams WHERE id IN (${placeholders})`, team_ids);
    // Convert to strings for consistent comparison
    const validIdsSet = new Set(validTeams.map(t => String(t.id)));

    // 4. Prepare Bulk Insert Data
    const teamstoInsert = [];
    team_ids.forEach(tid => {
      const tidStr = String(tid);
      if (validIdsSet.has(tidStr) && !existingIds.has(tidStr)) {
        teamstoInsert.push([tournament_id, tid, null, null]); // [tourn_id, team_id, temp_name, temp_loc]
      }
    });

    if (teamstoInsert.length > 0) {
      await conn.query(
        `INSERT INTO tournament_teams (tournament_id, team_id, temp_team_name, temp_team_location) VALUES ?`,
        [teamstoInsert]
      );
    }

    await conn.commit();

    res.json({
      success: true,
      message: `Added ${teamstoInsert.length} teams successfully`,
      added: teamstoInsert.length,
      skipped: team_ids.length - teamstoInsert.length
    });

  } catch (err) {
    if (conn) await conn.rollback();
    logDatabaseError(req.log, "addBulkTournamentTeams", err, { tournamentId: tournament_id });
    res.status(500).json({ success: false, error: "Server error" });
  } finally {
    if (conn) conn.release();
  }
};

module.exports = {
  addTournamentTeam,
  getTournamentTeams,
  updateTournamentTeam,
  deleteTournamentTeam,
  addBulkTournamentTeams,
};