const { db } = require("../config/db");
const { getValidationMessage } = require("../utils/validationMessages");
const {
  sendSuccess, sendError, sendValidationError, sendAuthError,
  sendForbiddenError, sendServerError, sendCreated, sendUpdated, sendDeleted
} = require("../utils/responseUtils");

// ========================
// HELPERS
// ========================

/**
 * Validates tournament status transitions
 */
const validateStatusTransition = (currentStatus, newStatus) => {
  const validTransitions = {
    'upcoming': ['live', 'abandoned'],
    'live': ['completed', 'abandoned'],
    'completed': [],
    'abandoned': []
  };
  return validTransitions[currentStatus]?.includes(newStatus) ?? false;
};

/**
 * Helper to build dynamic SQL update query
 */
const buildDynamicUpdate = (data, allowedFields) => {
  const updates = [];
  const values = [];

  Object.keys(data).forEach(key => {
    if (allowedFields.includes(key) && data[key] !== undefined) {
      updates.push(`${key} = ?`);
      values.push(data[key]);
    }
  });

  return {
    setClause: updates.join(', '),
    values: values
  };
};

// ========================
// CONTROLLERS
// ========================

// Create Tournament
const createTournament = async (req, res) => {
  const { tournament_name, start_date, location, overs, end_date } = req.body;

  // 1. Validation
  if (!tournament_name || !start_date || !location) {
    return sendValidationError(res, getValidationMessage('REQUIRED_FIELDS', ['tournament_name', 'start_date', 'location']));
  }

  if (overs !== undefined && (overs < 1 || overs > 50)) {
    return sendValidationError(res, "Overs must be between 1 and 50");
  }

  if (end_date && new Date(end_date) < new Date(start_date)) {
    return sendValidationError(res, "End date cannot be before start date");
  }

  if (!req.user || !req.user.id) {
    return sendAuthError(res, getValidationMessage('UNAUTHORIZED'));
  }

  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();

    const [result] = await conn.query(
      `INSERT INTO tournaments (tournament_name, start_date, location, created_by, status, overs, end_date)
       VALUES (?, ?, ?, ?, 'upcoming', ?, ?)`,
      [tournament_name, start_date, location, req.user.id, overs || 20, end_date || null]
    );

    await conn.commit();
    sendCreated(res, { tournament_id: result.insertId }, "Tournament created successfully");

  } catch (err) {
    await conn.rollback();
    req.log?.error("createTournament: Database error", { error: err.message });
    sendServerError(res, "Server error", err.message);
  } finally {
    conn.release();
  }
};

// Get all tournaments
const getTournaments = async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT 
        t.*, 
        u.phone_number AS creator_phone,
        (SELECT COUNT(*) FROM tournament_teams tt WHERE tt.tournament_id = t.id) AS total_teams
      FROM tournaments t
      JOIN users u ON t.created_by = u.id
      ORDER BY t.start_date DESC
    `);
    sendSuccess(res, 200, "Tournaments retrieved successfully", rows);
  } catch (err) {
    req.log?.error("getTournaments: Database error", { error: err.message });
    sendServerError(res, "Server error");
  }
};

// Get Single Tournament by ID (Detailed)
const getTournamentById = async (req, res) => {
  const tournamentId = req.params.id;

  try {
    // 1. Fetch Tournament Details
    const [rows] = await db.query(`
      SELECT t.*, u.phone_number AS creator_phone, wt.team_name AS winner_name
      FROM tournaments t
      JOIN users u ON t.created_by = u.id
      LEFT JOIN teams wt ON t.winner_team_id = wt.id
      WHERE t.id = ?
    `, [tournamentId]);

    if (rows.length === 0) {
      return sendValidationError(res, "Tournament not found");
    }
    const tournament = rows[0];

    // 2. Fetch Teams
    const [teams] = await db.query(`
      SELECT tt.id, tt.team_id,
             COALESCE(t.team_name, tt.temp_team_name) as name,
             COALESCE(t.team_location, tt.temp_team_location) as location,
             t.team_logo_url
      FROM tournament_teams tt
      LEFT JOIN teams t ON tt.team_id = t.id
      WHERE tt.tournament_id = ?
    `, [tournamentId]);

    // 3. Fetch Matches
    const [matches] = await db.query(`
      SELECT m.id, m.round, m.match_date, m.location, m.status,
             COALESCE(t1.team_name, tt1.temp_team_name) AS teamA,
             COALESCE(t2.team_name, tt2.temp_team_name) AS teamB,
             m.team1_id AS teamAId, m.team2_id AS teamBId,
             m.winner_id,
             wt.team_name AS winner_name,
             m.parent_match_id
      FROM tournament_matches m
      LEFT JOIN teams t1 ON m.team1_id = t1.id
      LEFT JOIN teams t2 ON m.team2_id = t2.id
      LEFT JOIN tournament_teams tt1 ON m.team1_tt_id = tt1.id
      LEFT JOIN tournament_teams tt2 ON m.team2_tt_id = tt2.id
      LEFT JOIN teams wt ON m.winner_id = wt.id
      WHERE m.tournament_id = ?
      ORDER BY m.round, m.match_date ASC
    `, [tournamentId]);

    // Construct Response
    const responseData = {
      ...tournament,
      teams: teams.map(t => ({
        id: t.id,
        name: t.name,
        location: t.location,
        logo: t.team_logo_url
      })),
      matches: matches.map(m => ({
        id: m.id,
        teamA: m.teamA,
        teamB: m.teamB,
        teamAId: m.teamAId,
        teamBId: m.teamBId,
        status: m.status,
        round: m.round,
        scheduledAt: m.match_date,
        winner: m.winner_name,
        parentMatchId: m.parent_match_id
      }))
    };

    sendSuccess(res, 200, "Tournament details retrieved", responseData);

  } catch (err) {
    req.log?.error("getTournamentById: Database error", { error: err.message });
    sendServerError(res, "Server error");
  }
};

// Update Tournament
const updateTournament = async (req, res) => {
  const tournamentId = req.params.id;
  const { tournament_name, start_date, location, status, overs, end_date } = req.body;

  if (!tournamentId) return sendValidationError(res, "Tournament ID required");

  try {
    // 1. Check Ownership & Existence
    const [rows] = await db.query(
      "SELECT * FROM tournaments WHERE id = ? AND created_by = ?",
      [tournamentId, req.user.id]
    );

    if (rows.length === 0) {
      return sendForbiddenError(res, getValidationMessage('NOT_TOURNAMENT_OWNER'));
    }
    const currentTournament = rows[0];

    // 2. Validate Status Transition
    if (status && status !== currentTournament.status) {
      if (!validateStatusTransition(currentTournament.status, status)) {
        return sendValidationError(res, `Invalid status change from ${currentTournament.status} to ${status}`);
      }
    }

    // 3. Additional Validation
    if (end_date && new Date(end_date) < new Date(start_date || currentTournament.start_date)) {
      return sendValidationError(res, "End date cannot be before start date");
    }

    // 4. Dynamic Update
    const updateData = { tournament_name, start_date, location, status, overs, end_date };
    const allowedFields = ['tournament_name', 'start_date', 'location', 'status', 'overs', 'end_date'];

    const queryParts = buildDynamicUpdate(updateData, allowedFields);

    if (!queryParts.setClause) {
      return sendValidationError(res, "No fields to update");
    }

    await db.query(
      `UPDATE tournaments SET ${queryParts.setClause} WHERE id = ?`,
      [...queryParts.values, tournamentId]
    );

    sendUpdated(res, null, "Tournament updated successfully");

  } catch (err) {
    req.log?.error("updateTournament: Database error", { error: err.message });
    sendServerError(res, "Server error");
  }
};

// Start Tournament (Specific Action)
const startTournament = async (req, res) => {
  const tournamentId = req.params.id;

  try {
    // 1. Fetch Tournament
    const [rows] = await db.query("SELECT * FROM tournaments WHERE id = ?", [tournamentId]);
    if (rows.length === 0) return sendValidationError(res, "Tournament not found");

    const tournament = rows[0];

    // 2. Authorization Check
    if (tournament.created_by !== req.user.id) {
      return sendForbiddenError(res, "Only the creator can start this tournament");
    }

    // 3. Validate State
    if (!validateStatusTransition(tournament.status, 'live')) {
      return sendValidationError(res, `Cannot start tournament from status: ${tournament.status}`);
    }

    // 4. Validate Teams Count (Need at least 2 teams)
    const [[{ count }]] = await db.query(
      "SELECT COUNT(*) as count FROM tournament_teams WHERE tournament_id = ?",
      [tournamentId]
    );

    if (count < 2) {
      return sendValidationError(res, "Tournament must have at least 2 teams to start");
    }

    // 5. Update Status
    await db.query("UPDATE tournaments SET status = 'live' WHERE id = ?", [tournamentId]);
    sendUpdated(res, null, "Tournament started successfully");

  } catch (err) {
    req.log?.error("startTournament: Database error", { error: err.message });
    sendServerError(res, "Server error");
  }
};

// Delete Tournament
const deleteTournament = async (req, res) => {
  const tournamentId = req.params.id;

  try {
    const [rows] = await db.query(
      "SELECT * FROM tournaments WHERE id = ? AND created_by = ?",
      [tournamentId, req.user.id]
    );

    if (rows.length === 0) {
      return sendForbiddenError(res, "Not allowed to delete this tournament");
    }

    // Note: Foreign keys should be set to CASCADE for matches/teams, 
    // otherwise you need to manually delete dependent records here first.
    await db.query("DELETE FROM tournaments WHERE id = ?", [tournamentId]);

    sendDeleted(res, "Tournament deleted successfully");
  } catch (err) {
    req.log?.error("deleteTournament: Database error", { error: err.message });
    sendServerError(res, "Server error");
  }
};

module.exports = {
  createTournament,
  getTournaments,
  getTournamentById,
  updateTournament,
  deleteTournament,
  startTournament,
};