const { db } = require("../config/db");
const live = require("./liveScoreController");
const { logDatabaseError } = require("../utils/safeLogger");

// ==========================================
// 🏏 BALL BY BALL CONTROLLER
// ==========================================

/**
 * 📌 Add Delivery (Adapter)
 * Delegates logic to the live scoring controller to maintain a single "Write" path for match state.
 * Transforms legacy/simplified payload into the structure expected by liveScoreController.
 */
const addDelivery = async (req, res, next) => {
  try {
    const body = req.body || {};

    // Adapt payload: Map frontend fields to LiveScoreController fields
    req.body = {
      match_id: body.match_id,
      inning_id: body.innings_id, // handle naming mismatch (innings_id vs inning_id)
      over_number: body.over_number,
      ball_number: body.ball_number,
      batsman_id: body.batsman_id,
      bowler_id: body.bowler_id,
      runs: body.runs_scored,
      extras: body.extra_type, 
      wicket_type: body.is_wicket ? (body.dismissal_type || 'wicket') : null,
      out_player_id: body.fielder_id || null,
    };

    // Delegate execution to LiveScoreController
    return live.addBall(req, res, next);

  } catch (err) {
    logDatabaseError(req.log, "addDelivery (Adapter)", err);
    return res.status(500).json({ error: "Failed to record delivery via adapter" });
  }
};

/**
 * 📌 Get All Deliveries for a Match
 * Returns chronological list of every ball bowled in the match.
 */
const getDeliveriesByMatch = async (req, res) => {
  const { match_id } = req.params;

  try {
    const [rows] = await db.query(
      `SELECT 
         b.*, 
         p1.player_name AS batsman_name,
         p2.player_name AS bowler_name,
         p3.player_name AS fielder_name
       FROM ball_by_ball b
       LEFT JOIN players p1 ON b.batsman_id = p1.id
       LEFT JOIN players p2 ON b.bowler_id = p2.id
       LEFT JOIN players p3 ON COALESCE(b.out_player_id, b.fielder_id) = p3.id
       WHERE b.match_id = ?
       ORDER BY COALESCE(b.inning_id, b.innings_id) ASC, b.over_number ASC, b.ball_number ASC`,
      [match_id]
    );

    res.json(rows);
  } catch (err) {
    logDatabaseError(req.log, "getDeliveriesByMatch", err, { match_id });
    res.status(500).json({ error: "Failed to fetch deliveries" });
  }
};

/**
 * 📌 Get Deliveries by Innings
 * Useful for rendering a specific inning's timeline or worm graph.
 */
const getDeliveriesByInnings = async (req, res) => {
  const { innings_id } = req.params;

  try {
    const [rows] = await db.query(
      `SELECT 
         b.*, 
         p1.player_name AS batsman_name,
         p2.player_name AS bowler_name,
         p3.player_name AS fielder_name
       FROM ball_by_ball b
       LEFT JOIN players p1 ON b.batsman_id = p1.id
       LEFT JOIN players p2 ON b.bowler_id = p2.id
       LEFT JOIN players p3 ON COALESCE(b.out_player_id, b.fielder_id) = p3.id
       WHERE COALESCE(b.inning_id, b.innings_id) = ?
       ORDER BY b.over_number ASC, b.ball_number ASC`,
      [innings_id]
    );

    res.json(rows);
  } catch (err) {
    logDatabaseError(req.log, "getDeliveriesByInnings", err, { innings_id });
    res.status(500).json({ error: "Failed to fetch deliveries" });
  }
};

/**
 * 📌 Delete Delivery
 * Used for correcting scoring errors (Admin/Scorer only).
 */
const deleteDelivery = async (req, res) => {
  const { delivery_id } = req.params;

  try {
    const [result] = await db.query("DELETE FROM ball_by_ball WHERE id = ?", [delivery_id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Delivery not found" });
    }

    res.json({ message: "Delivery deleted successfully" });
  } catch (err) {
    logDatabaseError(req.log, "deleteDelivery", err, { delivery_id });
    res.status(500).json({ error: "Failed to delete delivery" });
  }
};

module.exports = {
  addDelivery,
  getDeliveriesByMatch,
  getDeliveriesByInnings,
  deleteDelivery
};