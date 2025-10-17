const db = require("../config/db");

/**
 * 📌 Get all innings of a match
 */
const getInningsByMatch = async (req, res) => {
  const { match_id } = req.params;

  try {
    const [innings] = await db.query(
      "SELECT * FROM match_innings WHERE match_id = ? ORDER BY inning_number ASC",
      [match_id]
    );

    if (innings.length === 0) {
      return res.status(404).json({ error: "No innings found for this match" });
    }

    res.json(innings);
  } catch (err) {
    console.error("❌ Error in getInningsByMatch:", err);
    res.status(500).json({ error: "Server error" });
  }
};

/**
 * 📌 Get a single innings by ID
 */
const getInningById = async (req, res) => {
  const { id } = req.params;

  try {
    const [[inning]] = await db.query("SELECT * FROM match_innings WHERE id = ?", [id]);

    if (!inning) {
      return res.status(404).json({ error: "Innings not found" });
    }

    res.json(inning);
  } catch (err) {
    console.error("❌ Error in getInningById:", err);
    res.status(500).json({ error: "Server error" });
  }
};

/**
 * 📌 Update innings manually (useful for corrections)
 */
const updateInnings = async (req, res) => {
  const { id } = req.params;
  const { runs, wickets, overs, status } = req.body;

  try {
    const [result] = await db.query(
      `UPDATE match_innings 
       SET runs = ?, wickets = ?, overs = ?, status = ? 
       WHERE id = ?`,
      [runs, wickets, overs, status, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Innings not found to update" });
    }

    res.json({ message: "Innings updated successfully" });
  } catch (err) {
    console.error("❌ Error in updateInnings:", err);
    res.status(500).json({ error: "Server error" });
  }
};

/**
 * 📌 Delete innings (rare, admin use only)
 */
const deleteInnings = async (req, res) => {
  const { id } = req.params;

  try {
    const [result] = await db.query("DELETE FROM match_innings WHERE id = ?", [id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Innings not found to delete" });
    }

    res.json({ message: "Innings deleted successfully" });
  } catch (err) {
    console.error("❌ Error in deleteInnings:", err);
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = {
  getInningsByMatch,
  getInningById,
  updateInnings,
  deleteInnings,
};
