const pool = require("../config/db");

/**
 * 📌 Create Tournament Matches (manual or auto)
 */
const createTournamentMatches = async (req, res) => {
  const { tournament_id, mode, matches } = req.body;

  if (!tournament_id || !mode) {
    return res.status(400).json({ error: "Tournament ID and mode are required" });
  }

  try {
    // ✅ Check tournament ownership
    const [tournament] = await pool.query(
      "SELECT * FROM tournaments WHERE id = ? AND created_by = ?",
      [tournament_id, req.user.id]
    );
    if (tournament.length === 0) {
      return res.status(403).json({ error: "Not allowed to modify this tournament" });
    }

    if (mode === "manual") {
      if (!matches || matches.length === 0) {
        return res.status(400).json({ error: "Matches data required for manual mode" });
      }

      for (let m of matches) {
        await pool.query(
          `INSERT INTO tournament_matches 
          (tournament_id, team1_id, team2_id, round, match_date, location, status) 
          VALUES (?, ?, ?, ?, ?, ?, 'upcoming')`,
          [
            tournament_id,
            m.team1_id || null,
            m.team2_id || null,
            m.round || "round_1",
            m.match_date || null,
            m.location || null,
          ]
        );
      }

      return res.json({ message: "Manual matches created successfully" });
    }

    if (mode === "auto") {
      // ✅ Fetch all teams of tournament
      const [teams] = await pool.query(
        "SELECT id, team_id, temp_team_name FROM tournament_teams WHERE tournament_id = ?",
        [tournament_id]
      );

      if (teams.length < 2) {
        return res.status(400).json({ error: "At least 2 teams required for auto draws" });
      }

      // shuffle teams
      const shuffled = teams.sort(() => 0.5 - Math.random());

      // auto pair teams into matches
      for (let i = 0; i < shuffled.length; i += 2) {
        if (shuffled[i + 1]) {
          await pool.query(
            `INSERT INTO tournament_matches 
            (tournament_id, team1_id, team2_id, round, status) 
            VALUES (?, ?, ?, ?, 'upcoming')`,
            [tournament_id, shuffled[i].team_id, shuffled[i + 1].team_id, "round_1"]
          );
        } else {
          // odd team out → auto-advance to next round
          await pool.query(
            `INSERT INTO tournament_matches 
            (tournament_id, team1_id, round, status, winner_id) 
            VALUES (?, ?, ?, 'finished', ?)`,
            [tournament_id, shuffled[i].team_id, "bye", shuffled[i].team_id]
          );
        }
      }

      return res.json({ message: "Auto matches created successfully" });
    }

    res.status(400).json({ error: "Invalid mode" });
  } catch (err) {
    console.error("❌ Error in createTournamentMatches:", err);
    res.status(500).json({ error: "Server error" });
  }
};

/**
 * 📌 Get Tournament Matches
 */
const getTournamentMatches = async (req, res) => {
  const { tournament_id } = req.params;

  try {
    const [rows] = await pool.query(
      `SELECT m.id, m.tournament_id, m.round, m.match_date, m.location, m.status, 
              t1.team_name AS team1_name, t2.team_name AS team2_name, 
              m.winner_id
       FROM tournament_matches m
       LEFT JOIN teams t1 ON m.team1_id = t1.id
       LEFT JOIN teams t2 ON m.team2_id = t2.id
       WHERE m.tournament_id = ?
       ORDER BY m.round, m.id ASC`,
      [tournament_id]
    );

    res.json(rows);
  } catch (err) {
    console.error("❌ Error in getTournamentMatches:", err);
    res.status(500).json({ error: "Server error" });
  }
};

/**
 * 📌 Update Tournament Match (before start)
 */
const updateTournamentMatch = async (req, res) => {
  const { id } = req.params;
  const { match_date, location, team1_id, team2_id } = req.body;

  try {
    // check ownership
    const [match] = await pool.query(
      `SELECT m.*, t.created_by FROM tournament_matches m 
       JOIN tournaments t ON m.tournament_id = t.id
       WHERE m.id = ? AND t.created_by = ?`,
      [id, req.user.id]
    );

    if (match.length === 0) {
      return res.status(403).json({ error: "Not allowed to update this match" });
    }

    if (match[0].status !== "upcoming") {
      return res.status(400).json({ error: "Cannot update after match started" });
    }

    await pool.query(
      `UPDATE tournament_matches 
       SET match_date = ?, location = ?, team1_id = ?, team2_id = ? 
       WHERE id = ?`,
      [match_date || null, location || null, team1_id || null, team2_id || null, id]
    );

    res.json({ message: "Match updated successfully" });
  } catch (err) {
    console.error("❌ Error in updateTournamentMatch:", err);
    res.status(500).json({ error: "Server error" });
  }
};

/**
 * 📌 Start Tournament Match (Captain only)
 */
const startTournamentMatch = async (req, res) => {
  const { id } = req.params;

  try {
    // check ownership
    const [match] = await pool.query(
      `SELECT m.*, t.created_by FROM tournament_matches m 
       JOIN tournaments t ON m.tournament_id = t.id
       WHERE m.id = ? AND t.created_by = ?`,
      [id, req.user.id]
    );

    if (match.length === 0) {
      return res.status(403).json({ error: "Not allowed to start this match" });
    }

    if (match[0].status !== "upcoming") {
      return res.status(400).json({ error: "Match already started or finished" });
    }

    await pool.query(`UPDATE tournament_matches SET status = 'live' WHERE id = ?`, [id]);

    res.json({ message: "Match started, live scoring enabled" });
  } catch (err) {
    console.error("❌ Error in startTournamentMatch:", err);
    res.status(500).json({ error: "Server error" });
  }
};

/**
 * 📌 End Tournament Match (Captain only) + Progression
 */
const endTournamentMatch = async (req, res) => {
  const { id } = req.params;
  const { winner_id } = req.body;

  if (!winner_id) {
    return res.status(400).json({ error: "Winner ID is required" });
  }

  try {
    // check ownership
    const [match] = await pool.query(
      `SELECT m.*, t.created_by FROM tournament_matches m 
       JOIN tournaments t ON m.tournament_id = t.id
       WHERE m.id = ? AND t.created_by = ?`,
      [id, req.user.id]
    );

    if (match.length === 0) {
      return res.status(403).json({ error: "Not allowed to end this match" });
    }

    if (match[0].status !== "live") {
      return res.status(400).json({ error: "Match must be live to end" });
    }

    await pool.query(
      `UPDATE tournament_matches 
       SET status = 'finished', winner_id = ? 
       WHERE id = ?`,
      [winner_id, id]
    );

    // ✅ Knockout progression
    const round = match[0].round;
    if (round.startsWith("round_")) {
      const nextRound = `round_${parseInt(round.split("_")[1]) + 1}`;

      // find if next round already exists with empty slot
      const [nextMatch] = await pool.query(
        `SELECT * FROM tournament_matches 
         WHERE tournament_id = ? AND round = ? AND (team1_id IS NULL OR team2_id IS NULL)
         LIMIT 1`,
        [match[0].tournament_id, nextRound]
      );

      if (nextMatch.length > 0) {
        // fill empty slot
        if (!nextMatch[0].team1_id) {
          await pool.query(`UPDATE tournament_matches SET team1_id = ? WHERE id = ?`, [
            winner_id,
            nextMatch[0].id,
          ]);
        } else {
          await pool.query(`UPDATE tournament_matches SET team2_id = ? WHERE id = ?`, [
            winner_id,
            nextMatch[0].id,
          ]);
        }
      } else {
        // create new match
        await pool.query(
          `INSERT INTO tournament_matches (tournament_id, team1_id, round, status) 
           VALUES (?, ?, ?, 'upcoming')`,
          [match[0].tournament_id, winner_id, nextRound]
        );
      }
    }

    res.json({ message: "Match ended successfully, progression updated" });
  } catch (err) {
    console.error("❌ Error in endTournamentMatch:", err);
    res.status(500).json({ error: "Server error" });
  }
};

/**
 * 📌 Delete Tournament Match (only if not started)
 */
const deleteTournamentMatch = async (req, res) => {
  const { id } = req.params;

  try {
    // check ownership
    const [match] = await pool.query(
      `SELECT m.*, t.created_by FROM tournament_matches m 
       JOIN tournaments t ON m.tournament_id = t.id
       WHERE m.id = ? AND t.created_by = ?`,
      [id, req.user.id]
    );

    if (match.length === 0) {
      return res.status(403).json({ error: "Not allowed to delete this match" });
    }

    if (match[0].status !== "upcoming") {
      return res.status(400).json({ error: "Cannot delete after match started" });
    }

    await pool.query("DELETE FROM tournament_matches WHERE id = ?", [id]);

    res.json({ message: "Match deleted successfully" });
  } catch (err) {
    console.error("❌ Error in deleteTournamentMatch:", err);
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = {
  createTournamentMatches,
  getTournamentMatches,
  updateTournamentMatch,
  startTournamentMatch,
  endTournamentMatch,
  deleteTournamentMatch,
};
