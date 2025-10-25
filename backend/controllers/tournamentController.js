const db = require("../config/db");
const { getValidationMessage, createErrorResponse, createSuccessResponse } = require("../utils/validationMessages");
const { sendSuccess, sendError, sendValidationError, sendAuthError, sendForbiddenError, sendServerError, sendCreated, sendUpdated, sendDeleted } = require("../utils/responseUtils");

// Create Tournament
const createTournament = async (req, res) => {
  const { tournament_name, start_date, location, overs, end_date } = req.body;

  if (!tournament_name || !start_date || !location) {
    return sendValidationError(res, getValidationMessage('REQUIRED_FIELDS', ['tournament_name', 'start_date', 'location']));
  }

  // Validate overs if provided
  if (overs !== undefined && (overs < 1 || overs > 50)) {
    return sendValidationError(res, "Overs must be between 1 and 50");
  }

  // Validate end_date if provided
  if (end_date && new Date(end_date) < new Date(start_date)) {
    return sendValidationError(res, "End date cannot be before start date");
  }

  // Check if user is authenticated
  if (!req.user || !req.user.id) {
    req.log?.error("createTournament: No authenticated user");
    return sendAuthError(res, getValidationMessage('UNAUTHORIZED'));
  }

  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();

    req.log?.info(`Creating tournament: ${tournament_name} by user ${req.user.id}`);

    const [result] = await conn.query(
      `INSERT INTO tournaments (tournament_name, start_date, location, created_by, status, overs, end_date)
       VALUES (?, ?, ?, ?, 'upcoming', ?, ?)`,
      [tournament_name, start_date, location, req.user.id, overs || 20, end_date || null]
    );

    await conn.commit();

    sendCreated(res, { tournament_id: result.insertId }, "Tournament created successfully");
  } catch (err) {
    await conn.rollback();
    req.log?.error("createTournament: Database error", { error: err.message, code: err.code, sqlState: err.sqlState, tournamentName: tournament_name });
    sendServerError(res, "Server error", err.message);
  } finally {
    conn.release();
  }
};

// Get all tournaments with details
const getTournaments = async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT t.*, u.phone_number AS creator_name,
             (SELECT COUNT(*) FROM tournament_teams tt WHERE tt.tournament_id = t.id) AS total_teams
      FROM tournaments t
      JOIN users u ON t.created_by = u.id
      ORDER BY t.start_date DESC
    `);
    sendSuccess(res, 200, "Tournaments retrieved successfully", rows);
  } catch (err) {
    req.log?.error("getTournaments: Database error", { error: err.message, code: err.code });
    sendServerError(res, "Server error");
  }
};

// Status transition validation
const validateStatusTransition = (currentStatus, newStatus) => {
  const validTransitions = {
    'upcoming': ['live', 'abandoned'],
    'live': ['completed', 'abandoned'],
    'completed': [], // No transitions from completed
    'abandoned': [] // No transitions from abandoned
  };

  if (!validTransitions[currentStatus] || !validTransitions[currentStatus].includes(newStatus)) {
    return false;
  }
  return true;
};

// Update Tournament
const updateTournament = async (req, res) => {
  const tournamentId = req.params.id || req.body.tournamentId;
  const { tournament_name, start_date, location, status, overs, end_date } = req.body;

  if (!tournamentId) {
    return sendValidationError(res, getValidationMessage('REQUIRED_FIELD', 'tournamentId'));
  }

  try {
    const [rows] = await db.query(
      "SELECT * FROM tournaments WHERE id = ? AND created_by = ?",
      [tournamentId, req.user.id]
    );

    if (rows.length === 0) {
      return sendForbiddenError(res, getValidationMessage('NOT_TOURNAMENT_OWNER'));
    }

    const currentTournament = rows[0];

    // Validate status transition if status is being updated
    if (status && status !== currentTournament.status) {
      if (!validateStatusTransition(currentTournament.status, status)) {
        return sendValidationError(res, getValidationMessage('INVALID_STATUS_TRANSITION', currentTournament.status, status));
      }
    }

    // Validate overs if provided
    if (overs !== undefined && (overs < 1 || overs > 50)) {
      return sendValidationError(res, "Overs must be between 1 and 50");
    }

    // Validate end_date if provided
    if (end_date && new Date(end_date) < new Date(start_date || currentTournament.start_date)) {
      return sendValidationError(res, "End date cannot be before start date");
    }

    const updates = [];
    const values = [];

    if (tournament_name) { updates.push("tournament_name = ?"); values.push(tournament_name); }
    if (start_date) { updates.push("start_date = ?"); values.push(start_date); }
    if (location) { updates.push("location = ?"); values.push(location); }
    if (status) { updates.push("status = ?"); values.push(status); }
    if (overs !== undefined) { updates.push("overs = ?"); values.push(overs); }
    if (end_date !== undefined) { updates.push("end_date = ?"); values.push(end_date); }

    if (updates.length === 0) {
      return sendValidationError(res, "No fields to update");
    }

    values.push(tournamentId);

    await db.query(
      `UPDATE tournaments SET ${updates.join(", ")} WHERE id = ?`,
      values
    );

    sendUpdated(res, null, "Tournament updated successfully");
  } catch (err) {
    req.log?.error("updateTournament: Database error", { error: err.message, code: err.code, tournamentId });
    sendServerError(res, "Server error");
  }
};

// Delete Tournament
const deleteTournament = async (req, res) => {
  const tournamentId = req.params.id || req.body.tournamentId;

  if (!tournamentId) {
    return sendValidationError(res, getValidationMessage('REQUIRED_FIELD', 'tournamentId'));
  }

  try {
    const [rows] = await db.query(
      "SELECT * FROM tournaments WHERE id = ? AND created_by = ?",
      [tournamentId, req.user.id]
    );

    if (rows.length === 0) {
      return sendForbiddenError(res, "Not allowed to delete this tournament");
    }

    await db.query("DELETE FROM tournaments WHERE id = ?", [tournamentId]);

    sendDeleted(res, "Tournament deleted successfully");
  } catch (err) {
    req.log?.error("deleteTournament: Database error", { error: err.message, code: err.code, tournamentId });
    sendServerError(res, "Server error");
  }
};

module.exports = {
  createTournament,
  getTournaments,
  updateTournament,
  deleteTournament,
};
