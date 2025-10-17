const db = require("../config/db");

// Create Tournament
const createTournament = async (req, res) => {
  const { tournament_name, start_date, location } = req.body;

  if (!tournament_name || !start_date || !location) {
    return res.status(400).json({ error: "All fields are required" });
  }

  // Check if user is authenticated
  if (!req.user || !req.user.id) {
    console.error("❌ No authenticated user in createTournament");
    return res.status(401).json({ error: "Authentication required" });
  }

  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();

    console.log(`Creating tournament: ${tournament_name} by user ${req.user.id}`);

    const [result] = await conn.query(
      `INSERT INTO tournaments (tournament_name, start_date, location, created_by)
       VALUES (?, ?, ?, ?)`,
      [tournament_name, start_date, location, req.user.id]
    );

    await conn.commit();

    res.status(201).json({
      message: "Tournament created successfully",
      tournamentId: result.insertId,
    });
  } catch (err) {
    await conn.rollback();
    console.error("❌ Error in createTournament:", err);
    console.error("❌ Error details:", err.message);
    console.error("❌ SQL State:", err.sqlState);
    res.status(500).json({ error: "Server error", details: err.message });
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
    res.json(rows);
  } catch (err) {
    console.error("❌ Error in getTournaments:", err);
    res.status(500).json({ error: "Server error" });
  }
};

// Update Tournament
const updateTournament = async (req, res) => {
  const { tournamentId, tournament_name, start_date, location } = req.body;

  if (!tournamentId) {
    return res.status(400).json({ error: "tournamentId is required" });
  }

  try {
    const [rows] = await db.query(
      "SELECT * FROM tournaments WHERE id = ? AND created_by = ?",
      [tournamentId, req.user.id]
    );

    if (rows.length === 0) {
      return res.status(403).json({ error: "Not allowed to update this tournament" });
    }

    const updates = [];
    const values = [];

    if (tournament_name) { updates.push("tournament_name = ?"); values.push(tournament_name); }
    if (start_date) { updates.push("start_date = ?"); values.push(start_date); }
    if (location) { updates.push("location = ?"); values.push(location); }

    if (updates.length === 0) {
      return res.status(400).json({ error: "No fields to update" });
    }

    values.push(tournamentId);

    await db.query(
      `UPDATE tournaments SET ${updates.join(", ")} WHERE id = ?`,
      values
    );

    res.json({ message: "Tournament updated successfully" });
  } catch (err) {
    console.error("❌ Error in updateTournament:", err);
    res.status(500).json({ error: "Server error" });
  }
};

// Delete Tournament
const deleteTournament = async (req, res) => {
  const { tournamentId } = req.body;

  if (!tournamentId) {
    return res.status(400).json({ error: "tournamentId is required" });
  }

  try {
    const [rows] = await db.query(
      "SELECT * FROM tournaments WHERE id = ? AND created_by = ?",
      [tournamentId, req.user.id]
    );

    if (rows.length === 0) {
      return res.status(403).json({ error: "Not allowed to delete this tournament" });
    }

    await db.query("DELETE FROM tournaments WHERE id = ?", [tournamentId]);

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
