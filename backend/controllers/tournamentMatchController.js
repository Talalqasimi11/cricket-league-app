const { db } = require("../config/db");

/**
 * Helper to determine the next round name
 */
const getNextRoundName = (currentRound) => {
  if (currentRound === 'quarter_final') return 'semi_final';
  if (currentRound === 'semi_final') return 'final';
  if (currentRound === 'final') return null; // Tournament over

  // Handle numeric rounds (round_1 -> round_2)
  if (currentRound.startsWith("round_")) {
    const num = parseInt(currentRound.split("_")[1]);
    return `round_${num + 1}`;
  }

  return null;
};

/**
 * List ALL Tournament Matches (across tournaments)
 */
const getAllTournamentMatches = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT m.id, m.tournament_id, t.tournament_name, m.round, m.match_date, m.location, m.status,
              COALESCE(t1.team_name, tt1.temp_team_name) AS team1_name,
              COALESCE(t2.team_name, tt2.temp_team_name) AS team2_name,
              m.winner_id,
              m.parent_match_id,
              m.match_id
       FROM tournament_matches m
       LEFT JOIN teams t1 ON m.team1_id = t1.id
       LEFT JOIN teams t2 ON m.team2_id = t2.id
       LEFT JOIN tournament_teams tt1 ON m.team1_tt_id = tt1.id
       LEFT JOIN tournament_teams tt2 ON m.team2_tt_id = tt2.id
       LEFT JOIN tournaments t ON m.tournament_id = t.id
       ORDER BY (m.match_date IS NULL), m.match_date ASC, m.id DESC`
    );
    res.json(rows);
  } catch (err) {
    console.error("❌ Error in getAllTournamentMatches:", err);
    res.status(500).json({ error: "Server error" });
  }
};

/**
 * 📌 Create Tournament Matches (manual or auto)
 */
const createTournamentMatches = async (req, res) => {
  const { tournament_id, mode, matches } = req.body;

  if (!tournament_id || !mode) {
    return res.status(400).json({ error: "Tournament ID and mode are required" });
  }

  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();

    // ✅ Check tournament ownership
    const [tournament] = await conn.query(
      "SELECT * FROM tournaments WHERE id = ? AND created_by = ?",
      [tournament_id, req.user.id]
    );
    if (tournament.length === 0) {
      await conn.rollback();
      return res.status(403).json({ error: "Not allowed to modify this tournament" });
    }

    if (mode === "manual") {
      if (!matches || matches.length === 0) {
        await conn.rollback();
        return res.status(400).json({ error: "Matches data required for manual mode" });
      }

      for (let m of matches) {
        await conn.query(
          `INSERT INTO tournament_matches 
          (tournament_id, team1_id, team2_id, team1_tt_id, team2_tt_id, round, match_date, location, status) 
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'upcoming')`,
          [
            tournament_id,
            m.team1_id || null,
            m.team2_id || null,
            m.team1_tt_id || null,
            m.team2_tt_id || null,
            m.round || "round_1",
            m.match_date || null,
            m.location || 'Unknown',
          ]
        );
      }

      await conn.commit();
      return res.json({ message: "Manual matches created successfully" });
    }

    if (mode === "auto") {
      // ✅ Fetch all teams of tournament
      const [teams] = await conn.query(
        "SELECT id, team_id, temp_team_name FROM tournament_teams WHERE tournament_id = ?",
        [tournament_id]
      );

      if (teams.length < 2) {
        await conn.rollback();
        return res.status(400).json({ error: "At least 2 teams required for auto draws" });
      }

      // shuffle teams
      const shuffled = teams.sort(() => 0.5 - Math.random());

      // auto pair teams into matches
      for (let i = 0; i < shuffled.length; i += 2) {
        if (shuffled[i + 1]) {
          await conn.query(
            `INSERT INTO tournament_matches 
            (tournament_id, team1_id, team2_id, team1_tt_id, team2_tt_id, round, location, status) 
            VALUES (?, ?, ?, ?, ?, ?, 'Unknown', 'upcoming')`,
            [tournament_id, shuffled[i].team_id, shuffled[i + 1].team_id, shuffled[i].id, shuffled[i + 1].id, "round_1"]
          );
        } else {
          // odd team out → auto-advance to next round
          await conn.query(
            `INSERT INTO tournament_matches 
            (tournament_id, team1_id, team1_tt_id, round, location, status, winner_id) 
            VALUES (?, ?, ?, ?, 'Unknown', 'finished', ?)`,
            [tournament_id, shuffled[i].team_id, shuffled[i].id, "bye", shuffled[i].team_id]
          );
        }
      }

      await conn.commit();
      return res.json({ message: "Auto matches created successfully" });
    }

    await conn.rollback();
    res.status(400).json({ error: "Invalid mode" });

  } catch (err) {
    await conn.rollback();
    console.error("❌ Error in createTournamentMatches:", err);
    res.status(500).json({ error: "Server error" });
  } finally {
    conn.release();
  }
};

/**
 * 📌 Get Tournament Matches
 */
const getTournamentMatches = async (req, res) => {
  const { tournament_id } = req.params;

  try {
    const [rows] = await db.query(
      `SELECT m.id, m.tournament_id, m.round, m.match_date, m.location, m.status,
              COALESCE(t1.team_name, tt1.temp_team_name) AS team1_name,
              COALESCE(t2.team_name, tt2.temp_team_name) AS team2_name,
              m.winner_id,
              m.parent_match_id,
              m.match_id
       FROM tournament_matches m
       LEFT JOIN teams t1 ON m.team1_id = t1.id
       LEFT JOIN teams t2 ON m.team2_id = t2.id
       LEFT JOIN tournament_teams tt1 ON m.team1_tt_id = tt1.id
       LEFT JOIN tournament_teams tt2 ON m.team2_tt_id = tt2.id
       WHERE m.tournament_id = ?
       ORDER BY m.round, COALESCE(m.match_date, '9999-12-31') ASC, m.id ASC`,
      [tournament_id]
    );

    res.json(rows);
  } catch (err) {
    console.error("❌ Error in getTournamentMatches:", err);
    res.status(500).json({ error: "Server error" });
  }
};

/**
 * 📌 Get Tournament Match By ID
 */
const getTournamentMatchById = async (req, res) => {
  const { id } = req.params;

  try {
    const [rows] = await db.query(
      `SELECT m.id, m.tournament_id, t.tournament_name, m.round, m.match_date, m.location, m.status,
              COALESCE(t1.team_name, tt1.temp_team_name) AS team1_name,
              COALESCE(t2.team_name, tt2.temp_team_name) AS team2_name,
              m.winner_id,
              m.parent_match_id,
              m.match_id
       FROM tournament_matches m
       LEFT JOIN teams t1 ON m.team1_id = t1.id
       LEFT JOIN teams t2 ON m.team2_id = t2.id
       LEFT JOIN tournament_teams tt1 ON m.team1_tt_id = tt1.id
       LEFT JOIN tournament_teams tt2 ON m.team2_tt_id = tt2.id
       LEFT JOIN tournaments t ON m.tournament_id = t.id
       WHERE m.id = ?`,
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: "Match not found" });
    }

    res.json(rows[0]);
  } catch (err) {
    console.error("❌ Error in getTournamentMatchById:", err);
    res.status(500).json({ error: "Server error" });
  }
};


/**
 * 📌 Update Tournament Match (before start)
 */
const updateTournamentMatch = async (req, res) => {
  const { id } = req.params;
  const { match_date, location, team1_id, team2_id, team1_tt_id, team2_tt_id } = req.body;

  try {
    // check ownership
    const [match] = await db.query(
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

    // Check if there are dependent matches that reference this match's teams
    const [dependentMatches] = await db.query(
      `SELECT COUNT(*) as count FROM tournament_matches 
       WHERE tournament_id = ? AND (team1_id = ? OR team2_id = ? OR team1_tt_id = ? OR team2_tt_id = ?)
       AND id != ?`,
      [match[0].tournament_id, match[0].team1_id, match[0].team2_id, match[0].team1_tt_id, match[0].team2_tt_id, id]
    );

    if (dependentMatches[0].count > 0) {
      return res.status(400).json({
        error: "Cannot change teams after dependent matches have been created that reference these teams"
      });
    }

    await db.query(
      `UPDATE tournament_matches 
       SET match_date = ?, location = ?, team1_id = ?, team2_id = ?, team1_tt_id = ?, team2_tt_id = ? 
       WHERE id = ?`,
      [
        match_date || null,
        location || 'Unknown', // ✅ Default to 'Unknown' if not provided
        team1_id || null,
        team2_id || null,
        team1_tt_id || null,
        team2_tt_id || null,
        id
      ]
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
    // check ownership or team owner
    const [match] = await db.query(
      `SELECT m.*, t.created_by, t.id as tournament_id, t.start_date as tournament_start_date,
              t1.owner_id as team1_owner, t2.owner_id as team2_owner
       FROM tournament_matches m 
       JOIN tournaments t ON m.tournament_id = t.id
       LEFT JOIN teams t1 ON m.team1_id = t1.id
       LEFT JOIN teams t2 ON m.team2_id = t2.id
       WHERE m.id = ? AND (
         t.created_by = ? OR 
         t1.owner_id = ? OR 
         t2.owner_id = ?
       )`,
      [id, req.user.id, req.user.id, req.user.id]
    );

    if (match.length === 0) {
      return res.status(403).json({ error: "Not allowed to start this match" });
    }

    const row = match[0];
    if (row.status !== "upcoming") {
      return res.status(400).json({ error: "Match already started or finished" });
    }

    // Validate match date against tournament start date
    if (row.match_date) {
      const matchDate = new Date(row.match_date);
      const tournamentStartDate = new Date(row.tournament_start_date);

      if (matchDate < tournamentStartDate) {
        return res.status(400).json({
          error: `Match cannot be started before tournament start date (${row.tournament_start_date})`
        });
      }
    }

    // Require registered teams for live match
    if (!row.team1_id || !row.team2_id) {
      return res.status(400).json({ error: "Cannot start live match for temporary teams. Register both teams first." });
    }

    // Create actual match record for live scoring
    // Get tournament configuration for overs
    const [[tournament]] = await db.query(
      `SELECT id, overs FROM tournaments WHERE id = ?`,
      [row.tournament_id]
    );

    const oversDefault = tournament?.overs || 20;

    const [ins] = await db.query(
      `INSERT INTO matches (team1_id, team2_id, overs, status, tournament_id, match_datetime, venue) VALUES (?, ?, ?, 'live', ?, ?, ?)`,
      [row.team1_id, row.team2_id, oversDefault, row.tournament_id, new Date(), row.location || 'Unknown']
    );

    const createdMatchId = ins.insertId;

    await db.query(`UPDATE tournament_matches SET status = 'live', match_id = ? WHERE id = ? `, [createdMatchId, id]);

    // ✅ Auto-start first innings (Assume Team 1 bats first for now)
    await db.query(
      `INSERT INTO match_innings 
       (match_id, team_id, batting_team_id, bowling_team_id, inning_number, runs, wickets, overs, status) 
       VALUES (?, ?, ?, ?, 1, 0, 0, 0, 'in_progress')`,
      [createdMatchId, row.team1_id, row.team1_id, row.team2_id]
    );

    res.json({ message: "Match started, live scoring enabled", match_id: createdMatchId });
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
    // check ownership or team owner
    const [match] = await db.query(
      `SELECT m.*, t.created_by,
      t1.owner_id as team1_owner, t2.owner_id as team2_owner
       FROM tournament_matches m 
       JOIN tournaments t ON m.tournament_id = t.id
       LEFT JOIN teams t1 ON m.team1_id = t1.id
       LEFT JOIN teams t2 ON m.team2_id = t2.id
       WHERE m.id = ? AND(
        t.created_by = ? OR 
         t1.owner_id = ? OR 
         t2.owner_id = ?
       )`,
      [id, req.user.id, req.user.id, req.user.id]
    );

    if (match.length === 0) {
      return res.status(403).json({ error: "Not allowed to end this match" });
    }

    if (match[0].status !== "live") {
      return res.status(400).json({ error: "Match must be live to end" });
    }

    await db.query(
      `UPDATE tournament_matches 
       SET status = 'finished', winner_id = ?
      WHERE id = ? `,
      [winner_id, id]
    );

    // If linked to an actual match, mark it completed as well
    if (match[0].match_id) {
      await db.query(
        `UPDATE matches SET status = 'completed', winner_team_id = ? WHERE id = ? `,
        [winner_id, match[0].match_id]
      );
    }

    // ✅ Knockout progression
    const round = match[0].round;
    const nextRound = getNextRoundName(round);

    if (nextRound) {
      // find if next round already exists with empty slot
      const [nextMatch] = await db.query(
        `SELECT * FROM tournament_matches 
         WHERE tournament_id = ? AND round = ? AND(team1_id IS NULL OR team2_id IS NULL)
         LIMIT 1`,
        [match[0].tournament_id, nextRound]
      );

      if (nextMatch.length > 0) {
        // fill empty slot
        // Determine if winner is from team1 or team2 and get corresponding tt_id
        // This logic assumes the winner was one of the participating teams in the current match
        const winner_tt_id = match[0].winner_id == match[0].team1_id ? match[0].team1_tt_id : match[0].team2_tt_id;

        if (!nextMatch[0].team1_id) {
          await db.query(`UPDATE tournament_matches SET team1_id = ?, team1_tt_id = ? WHERE id = ? `, [
            winner_id,
            winner_tt_id,
            nextMatch[0].id,
          ]);
        } else {
          await db.query(`UPDATE tournament_matches SET team2_id = ?, team2_tt_id = ? WHERE id = ? `, [
            winner_id,
            winner_tt_id,
            nextMatch[0].id,
          ]);
        }
      } else {
        // create new match
        // Determine if winner is from team1 or team2 and get corresponding tt_id
        const winner_tt_id = match[0].winner_id == match[0].team1_id ? match[0].team1_tt_id : match[0].team2_tt_id;

        // Note: New rounds created automatically default to 'Unknown' location here as well
        await db.query(
          `INSERT INTO tournament_matches(tournament_id, team1_id, team1_tt_id, round, location, status) 
           VALUES(?, ?, ?, ?, 'Unknown', 'upcoming')`,
          [match[0].tournament_id, winner_id, winner_tt_id, nextRound]
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
    const [match] = await db.query(
      `SELECT m.*, t.created_by FROM tournament_matches m 
       JOIN tournaments t ON m.tournament_id = t.id
       WHERE m.id = ? AND t.created_by = ? `,
      [id, req.user.id]
    );

    if (match.length === 0) {
      return res.status(403).json({ error: "Not allowed to delete this match" });
    }

    if (match[0].status !== "upcoming") {
      return res.status(400).json({ error: "Cannot delete after match started" });
    }

    await db.query("DELETE FROM tournament_matches WHERE id = ?", [id]);

    res.json({ message: "Match deleted successfully" });
  } catch (err) {
    console.error("❌ Error in deleteTournamentMatch:", err);
    res.status(500).json({ error: "Server error" });
  }
};

/**
 * 📌 Create Friendly Match (Standalone)
 */
const createFriendlyMatch = async (req, res) => {
  const { team1_id, team2_id, team1_name, team2_name, overs, match_date, venue } = req.body;

  // Basic validation
  if ((!team1_id && !team1_name) || (!team2_id && !team2_name)) {
    return res.status(400).json({ error: "Teams are required" });
  }

  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();

    let t1Id = team1_id;
    let t2Id = team2_id;

    // If IDs not provided, create temporary teams

    if (!t1Id && team1_name) {
      const [r1] = await conn.query("INSERT INTO teams (team_name, owner_id) VALUES (?, ?)", [team1_name, req.user.id]);
      t1Id = r1.insertId;
    }
    if (!t2Id && team2_name) {
      const [r2] = await conn.query("INSERT INTO teams (team_name, owner_id) VALUES (?, ?)", [team2_name, req.user.id]);
      t2Id = r2.insertId;
    }

    // Create Match in `matches` table directly (skipping tournament_matches)
    const [result] = await conn.query(
      `INSERT INTO matches(team1_id, team2_id, overs, status, match_datetime, venue, tournament_id) 
       VALUES(?, ?, ?, 'not_started', ?, ?, NULL)`,
      [
        t1Id,
        t2Id,
        overs || 10,
        match_date ? new Date(match_date) : new Date(),
        venue || 'Unknown' // ✅ Defaults to 'Unknown' location for temporary/friendly matches
      ]
    );

    await conn.commit();

    // Return formatted match object
    res.status(201).json({
      id: result.insertId,
      team1_id: t1Id,
      team2_id: t2Id,
      team1_name: team1_name || 'Team A',
      team2_name: team2_name || 'Team B',
      status: 'not_started',
      overs: overs || 10,
      venue: venue || 'Unknown'
    });

  } catch (err) {
    await conn.rollback();
    console.error("createFriendlyMatch error:", err);
    res.status(500).json({ error: "Server error creating match", details: err.message, stack: err.stack });
  } finally {
    conn.release();
  }
};

/**
 * 📌 Create Manual Match (from Frontend "Schedule Match" dialog)
 * Resolves team names to IDs automatically
 */
const createManualMatch = async (req, res) => {
  const { tournament_id, team1_name, team2_name, match_date, round } = req.body;

  if (!tournament_id || !team1_name || !team2_name) {
    return res.status(400).json({ error: "Tournament ID and Team Names are required" });
  }

  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();

    // 1. Verify Tournament Access
    const [tournament] = await conn.query(
      "SELECT * FROM tournaments WHERE id = ? AND created_by = ?",
      [tournament_id, req.user.id]
    );
    if (tournament.length === 0) {
      await conn.rollback();
      return res.status(403).json({ error: "Not allowed to modify this tournament" });
    }

    // 2. Resolve Team Names to Tournament Team IDs
    const getTeamDetails = async (name) => {
      const [rows] = await conn.query(
        `SELECT tt.id as tt_id, tt.team_id 
         FROM tournament_teams tt
         LEFT JOIN teams t ON tt.team_id = t.id
         WHERE tt.tournament_id = ?
      AND(t.team_name = ? OR tt.temp_team_name = ?)`,
        [tournament_id, name, name]
      );
      return rows.length > 0 ? rows[0] : null;
    };

    const t1 = await getTeamDetails(team1_name);
    const t2 = await getTeamDetails(team2_name);

    if (!t1 || !t2) {
      await conn.rollback();
      return res.status(400).json({ error: "One or both teams not found in the tournament" });
    }

    // 2.5 Check for existing matches in this round for these teams
    const [existingMatches] = await conn.query(
      `SELECT * FROM tournament_matches 
       WHERE tournament_id = ? AND round = ?
      AND(team1_id IN(?, ?) OR team2_id IN(?, ?))
       AND status != 'cancelled'`,
      [tournament_id, round || 'Group Stage', t1.team_id, t2.team_id, t1.team_id, t2.team_id]
    );

    if (existingMatches.length > 0) {
      await conn.rollback();
      return res.status(400).json({ error: "One or both teams already have a match scheduled in this round" });
    }

    // 3. Insert into tournament_matches
    const [result] = await conn.query(
      `INSERT INTO tournament_matches(tournament_id, team1_id, team1_tt_id, team2_id, team2_tt_id, round, match_date, location, status) 
       VALUES(?, ?, ?, ?, ?, ?, ?, 'Unknown', 'upcoming')`,
      [
        tournament_id,
        t1.team_id,
        t1.tt_id,
        t2.team_id,
        t2.tt_id,
        round || 'Group Stage', // Default round if not provided
        match_date || new Date(),
      ]
    );

    await conn.commit();

    // Return the created match object
    res.status(201).json({
      message: "Match scheduled successfully",
      match: {
        id: result.insertId,
        tournament_id,
        team1_id: t1.team_id,
        team2_id: t2.team_id,
        team1_name,
        team2_name,
        round: round || 'Group Stage',
        match_date: match_date || new Date(),
        location: 'Unknown',
        status: 'upcoming'
      }
    });

  } catch (err) {
    await conn.rollback();
    console.error("❌ Error in createManualMatch:", err);
    res.status(500).json({ error: "Server error" });
  } finally {
    conn.release();
  }
};

module.exports = {
  getAllTournamentMatches,
  createTournamentMatches,
  getTournamentMatches,
  getTournamentMatchById,
  updateTournamentMatch,
  startTournamentMatch,
  endTournamentMatch,
  deleteTournamentMatch,
  createFriendlyMatch,
  createManualMatch
};