const db = require("../config/db");
const live = require("./liveScoreController");

// Insert a new delivery
exports.addDelivery = async (req, res, next) => {
  // Delegate to live scoring controller to keep single write path
  try {
    const body = req.body || {};
    req.body = {
      match_id: body.match_id,
      inning_id: body.innings_id, // adapter: innings_id -> inning_id
      over_number: body.over_number,
      ball_number: body.ball_number,
      batsman_id: body.batsman_id,
      bowler_id: body.bowler_id,
      runs: body.runs_scored,
      extras: body.extra_type,
      wicket_type: body.is_wicket ? (body.dismissal_type || 'wicket') : null,
      out_player_id: body.fielder_id || null,
    };
    return live.addBall(req, res, next);
  } catch (err) {
    console.error("Error adapting delivery:", err);
    return res.status(500).json({ error: "Failed to record delivery" });
  }
};

// Get all deliveries of a match
exports.getDeliveriesByMatch = async (req, res) => {
  const { match_id } = req.params;

  try {
    const [rows] = await db.query(
      `SELECT b.*, 
              p1.player_name AS batsman_name,
              p2.player_name AS bowler_name,
              p3.player_name AS fielder_name
       FROM ball_by_ball b
       LEFT JOIN players p1 ON b.batsman_id = p1.id
       LEFT JOIN players p2 ON b.bowler_id = p2.id
       LEFT JOIN players p3 ON COALESCE(b.out_player_id, b.fielder_id) = p3.id
       WHERE b.match_id = ?
       ORDER BY COALESCE(b.inning_id, b.innings_id), b.over_number, b.ball_number ASC`,
      [match_id]
    );

    res.json(rows);
  } catch (err) {
    console.error("Error fetching deliveries:", err);
    res.status(500).json({ error: "Failed to fetch deliveries" });
  }
};

// Get deliveries of a specific innings
exports.getDeliveriesByInnings = async (req, res) => {
  const { innings_id } = req.params;

  try {
    const [rows] = await db.query(
      `SELECT b.*, 
              p1.player_name AS batsman_name,
              p2.player_name AS bowler_name,
              p3.player_name AS fielder_name
       FROM ball_by_ball b
       LEFT JOIN players p1 ON b.batsman_id = p1.id
       LEFT JOIN players p2 ON b.bowler_id = p2.id
       LEFT JOIN players p3 ON COALESCE(b.out_player_id, b.fielder_id) = p3.id
       WHERE COALESCE(b.inning_id, b.innings_id) = ?
       ORDER BY b.over_number, b.ball_number ASC`,
      [innings_id]
    );

    res.json(rows);
  } catch (err) {
    console.error("Error fetching deliveries:", err);
    res.status(500).json({ error: "Failed to fetch deliveries" });
  }
};

// Delete a delivery (for admin/debug only)
exports.deleteDelivery = async (req, res) => {
  const { delivery_id } = req.params;

  try {
    await db.query(`DELETE FROM ball_by_ball WHERE id = ?`, [delivery_id]);
    res.json({ message: "Delivery deleted successfully" });
  } catch (err) {
    console.error("Error deleting delivery:", err);
    res.status(500).json({ error: "Failed to delete delivery" });
  }
};
