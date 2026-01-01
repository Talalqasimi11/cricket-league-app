const { db } = require("../config/db");
const { logDatabaseError } = require("../utils/safeLogger");
const { canScoreForInnings } = require("./liveScoreController");

// ==========================================
// 🏏 INNINGS MANAGEMENT CONTROLLER
// ==========================================

/**
 * 📌 Get All Innings for a Match
 * Returns innings ordered by sequence with team names populated.
 */
const getInningsByMatch = async (req, res) => {
  const { match_id } = req.params;

  if (!match_id) return res.status(400).json({ error: "Match ID is required" });

  try {
    const [innings] = await db.query(
      `SELECT 
         mi.*,
         bt.team_name AS batting_team_name,
         bt.team_logo_url AS batting_team_logo,
         blt.team_name AS bowling_team_name,
         blt.team_logo_url AS bowling_team_logo
       FROM match_innings mi
       LEFT JOIN teams bt ON mi.batting_team_id = bt.id
       LEFT JOIN teams blt ON mi.bowling_team_id = blt.id
       WHERE mi.match_id = ? 
       ORDER BY mi.inning_number ASC`,
      [match_id]
    );

    if (innings.length === 0) {
      // Friendly 404 or empty array? Empty array is usually better for lists.
      return res.json([]);
    }

    res.json(innings);
  } catch (err) {
    logDatabaseError(req.log, "getInningsByMatch", err, { match_id });
    res.status(500).json({ error: "Server error retrieving innings" });
  }
};

/**
 * 📌 Get Single Inning by ID
 * Useful for specific scorecard views.
 */
const getInningById = async (req, res) => {
  const { id } = req.params;

  try {
    const [rows] = await db.query(
      `SELECT 
         mi.*,
         bt.team_name AS batting_team_name,
         blt.team_name AS bowling_team_name
       FROM match_innings mi
       LEFT JOIN teams bt ON mi.batting_team_id = bt.id
       LEFT JOIN teams blt ON mi.bowling_team_id = blt.id
       WHERE mi.id = ?`,
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: "Innings not found" });
    }

    res.json(rows[0]);
  } catch (err) {
    logDatabaseError(req.log, "getInningById", err, { inningId: id });
    res.status(500).json({ error: "Server error" });
  }
};

/**
 * 📌 Update Innings (Correction Tool)
 * Supports partial updates (e.g., just fixing the status or score).
 */
const updateInnings = async (req, res) => {
  const { id } = req.params;
  const { runs, wickets, overs, overs_decimal, status, legal_balls } = req.body;
  const userId = req.user.id;

  try {
    // 0. Authorization Check
    const authorized = await canScoreForInnings(userId, id);
    if (!authorized) {
      return res.status(403).json({ error: "Unauthorized" });
    }

    // 1. Dynamic Query Builder
    const updates = [];
    const values = [];

    if (runs !== undefined) { updates.push("runs = ?"); values.push(runs); }
    if (wickets !== undefined) { updates.push("wickets = ?"); values.push(wickets); }
    if (overs !== undefined) { updates.push("overs = ?"); values.push(overs); }
    if (overs_decimal !== undefined) { updates.push("overs_decimal = ?"); values.push(overs_decimal); }
    if (legal_balls !== undefined) { updates.push("legal_balls = ?"); values.push(legal_balls); }
    if (status !== undefined) {
      updates.push("status = ?");
      values.push(status);
    }

    if (updates.length === 0) {
      return res.status(400).json({ error: "No valid fields provided for update" });
    }

    values.push(id); // Add ID for WHERE clause

    // 2. Execute Update
    const [result] = await db.query(
      `UPDATE match_innings SET ${updates.join(", ")} WHERE id = ?`,
      values
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Innings not found" });
    }

    res.json({ message: "Innings updated successfully" });

  } catch (err) {
    logDatabaseError(req.log, "updateInnings", err, { inningId: id });
    res.status(500).json({ error: "Server error updating innings" });
  }
};

/**
 * 📌 Delete Innings (Admin Only)
 * Safety Check: Prevents deleting innings if ball-by-ball data exists.
 */
const deleteInnings = async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  try {
    // 0. Authorization Check
    const authorized = await canScoreForInnings(userId, id);
    if (!authorized) {
      return res.status(403).json({ error: "Unauthorized" });
    }

    // 1. Safety Check
    const [[check]] = await db.query(
      "SELECT COUNT(*) as count FROM ball_by_ball WHERE inning_id = ?",
      [id]
    );

    if (check.count > 0) {
      return res.status(400).json({
        error: "Cannot delete innings with existing ball data. Delete the balls first or use a hard reset."
      });
    }

    // 2. Delete
    const [result] = await db.query("DELETE FROM match_innings WHERE id = ?", [id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Innings not found" });
    }

    res.json({ message: "Innings deleted successfully" });
  } catch (err) {
    logDatabaseError(req.log, "deleteInnings", err, { inningId: id });
    res.status(500).json({ error: "Server error deleting innings" });
  }
};

module.exports = {
  getInningsByMatch,
  getInningById,
  updateInnings,
  deleteInnings,
};