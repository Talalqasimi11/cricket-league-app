const pool = require("../config/db");

// 📌 Create a match (only tournament creator)
const createMatch = async (req, res) => {
  const { tournamentId, team1_id, team2_id, match_date, overs } = req.body;

  if (!tournamentId || !team1_id || !team2_id || !match_date) {
    return res.status(400).json({ error: "tournamentId, team1_id, team2_id, and match_date are required" });
  }

  if (team1_id === team2_id) {
    return res.status(400).json({ error: "A team cannot play against itself" });
  }

  try {
    // 1️⃣ Check if tournament belongs to captain
    const [tournamentRows] = await pool.query(
      "SELECT * FROM tournaments WHERE id = ? AND created_by = ?",
      [tournamentId, req.user.id]
    );
    if (tournamentRows.length === 0) {
      return res.status(403).json({ error: "You are not allowed to add matches to this tournament" });
    }

    // 2️⃣ Prevent duplicate matches
    const [existing] = await pool.query(
      `SELECT * FROM matches 
       WHERE tournament_id = ? 
         AND ((team1_id = ? AND team2_id = ?) OR (team1_id = ? AND team2_id = ?)) 
         AND match_date = ?`,
      [tournamentId, team1_id, team2_id, team2_id, team1_id, match_date]
    );

    if (existing.length > 0) {
      return res.status(409).json({ error: "This match already exists for the given date" });
    }

    // 3️⃣ Insert new match
    const [result] = await pool.query(
      "INSERT INTO matches (tournament_id, team1_id, team2_id, match_date, overs, status) VALUES (?, ?, ?, ?, ?, 'upcoming')",
      [tournamentId, team1_id, team2_id, match_date, overs || null]
    );

    res.status(201).json({
      message: "Match created successfully",
      matchId: result.insertId
    });
  } catch (err) {
    console.error("❌ Error in createMatch:", err);
    res.status(500).json({ error: "Server error" });
  }
};

// 👇 THIS WAS MISSING
module.exports = { createMatch };
