const pool = require("../config/db");

// 📌 Create Tournament (captain only)
const createTournament = async (req, res) => {
  const { tournament_name, start_date, location } = req.body;

  if (!tournament_name || !start_date || !location) {
    return res.status(400).json({ error: "All fields are required" });
  }

  try {
    const [result] = await pool.query(
      `INSERT INTO tournaments (tournament_name, start_date, location, status, created_by)
       VALUES (?, ?, ?, 'ongoing', ?)`,
      [tournament_name, start_date, location, req.user.id]
    );

    res.status(201).json({
      message: "Tournament created successfully",
      tournamentId: result.insertId,
    });
  } catch (err) {
    console.error("❌ Error in createTournament:", err);
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Get all tournaments
const getTournaments = async (req, res) => {
  try {
    const [rows] = await pool.query("SELECT * FROM tournaments");
    res.json(rows);
  } catch (err) {
    console.error("❌ Error in getTournaments:", err);
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Update Tournament (only by creator)
const updateTournament = async (req, res) => {
  const { tournamentId, tournament_name, start_date, location } = req.body;

  if (!tournamentId) {
    return res.status(400).json({ error: "tournamentId is required" });
  }

  try {
    // check ownership
    const [rows] = await pool.query(
      "SELECT * FROM tournaments WHERE id = ? AND created_by = ?",
      [tournamentId, req.user.id]
    );

    if (rows.length === 0) {
      return res.status(403).json({ error: "Not allowed to update this tournament" });
    }

    await pool.query(
      "UPDATE tournaments SET tournament_name = ?, start_date = ?, location = ? WHERE id = ?",
      [tournament_name, start_date, location, tournamentId]
    );

    res.json({ message: "Tournament updated successfully" });
  } catch (err) {
    console.error("❌ Error in updateTournament:", err);
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Delete Tournament (only by creator)
const deleteTournament = async (req, res) => {
  const { tournamentId } = req.body;

  if (!tournamentId) {
    return res.status(400).json({ error: "tournamentId is required" });
  }

  try {
    // check ownership
    const [rows] = await pool.query(
      "SELECT * FROM tournaments WHERE id = ? AND created_by = ?",
      [tournamentId, req.user.id]
    );

    if (rows.length === 0) {
      return res.status(403).json({ error: "Not allowed to delete this tournament" });
    }

    await pool.query("DELETE FROM tournaments WHERE id = ?", [tournamentId]);

    res.json({ message: "Tournament deleted successfully" });
  } catch (err) {
    console.error("❌ Error in deleteTournament:", err);
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = {
  createTournament,
  getTournaments,
  updateTournament,
  deleteTournament,
};
