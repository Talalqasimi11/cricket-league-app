const { db } = require("../config/db");
const { logDatabaseError } = require("../utils/safeLogger");

const { canScoreForMatch } = require("./liveScoreController");

/**
 * 📌 Finalize Match
 * Decides winner, updates tournament standings, and persists cumulative player stats.
 */
// Internal function for reuse
const finalizeMatchInternal = async (match_id) => {
  let conn;
  try {
    // Start transaction
    conn = await db.getConnection();
    await conn.beginTransaction();

    // 1️⃣ Fetch match & Lock Row
    const [[match]] = await conn.query("SELECT * FROM matches WHERE id = ? FOR UPDATE", [match_id]);

    if (!match) {
      await conn.rollback();
      throw { status: 404, message: "Match not found" };
    }

    console.log("[Finalize Debug] Match found:", match); // DEBUG LOG


    if (match.status === "completed") {
      await conn.rollback();
      throw { status: 400, message: "Match already finalized" };
    }

    // 2️⃣ Calculate Scores
    const [innings] = await conn.query(
      "SELECT batting_team_id, runs FROM match_innings WHERE match_id = ?",
      [match_id]
    );

    const scores = {};
    scores[match.team1_id] = 0;
    scores[match.team2_id] = 0;

    innings.forEach(inn => {
      if (scores[inn.batting_team_id] !== undefined) {
        scores[inn.batting_team_id] += inn.runs;
      }
    });

    const team1Runs = scores[match.team1_id];
    const team2Runs = scores[match.team2_id];
    let winnerTeamId = null;

    if (team1Runs > team2Runs) winnerTeamId = match.team1_id;
    else if (team2Runs > team1Runs) winnerTeamId = match.team2_id;
    // Else it's a tie (winnerTeamId remains null)

    // 3️⃣ Update Match Status
    await conn.query(
      "UPDATE matches SET status = 'completed', winner_team_id = ? WHERE id = ?",
      [winnerTeamId, match_id]
    );

    // 4️⃣ Update Global Team Stats (Main `teams` table)
    // Only if it's a tournament match
    if (match.tournament_id) {
      // Increment matches_played for both
      await conn.query(
        "UPDATE teams SET matches_played = matches_played + 1 WHERE id IN (?, ?)",
        [match.team1_id, match.team2_id]
      );

      // Increment matches_won for winner
      if (winnerTeamId) {
        await conn.query(
          "UPDATE teams SET matches_won = matches_won + 1 WHERE id = ?",
          [winnerTeamId]
        );
      }

      // 5️⃣ Update Tournament Standings (if part of tournament)
      const teams = [match.team1_id, match.team2_id];
      for (const teamId of teams) {
        await conn.query(
          `INSERT INTO team_tournament_summary 
           (tournament_id, team_id, matches_played, matches_won, points) 
           VALUES (?, ?, 1, ?, ?) 
           ON DUPLICATE KEY UPDATE 
             matches_played = matches_played + 1, 
             matches_won = matches_won + VALUES(matches_won),
             points = points + VALUES(points)`,
          [
            match.tournament_id,
            teamId,
            teamId === winnerTeamId ? 1 : 0,
            teamId === winnerTeamId ? 2 : 1 // 2 pts for win, 1 for tie/loss (adjust logic as needed)
          ]
        );
      }

      // 6️⃣ Update Cumulative Player Stats
      // We fetch current match stats and merge them into the players' lifetime stats
      const [matchStats] = await conn.query(
        "SELECT * FROM player_match_stats WHERE match_id = ?",
        [match_id]
      );

      for (const stat of matchStats) {
        const runs = stat.runs || 0;
        const wickets = stat.wickets || 0;
        const hundreds = runs >= 100 ? 1 : 0;
        const fifties = (runs >= 50 && runs < 100) ? 1 : 0;

        await conn.query(
          `UPDATE players 
           SET 
             matches_played = matches_played + 1,
             runs = runs + ?,
             wickets = wickets + ?,
             hundreds = hundreds + ?,
             fifties = fifties + ?,
             
             -- Recalculate Batting Average
             batting_average = CASE 
               WHEN (matches_played + 1) > 0 
               THEN (runs + ?) / (matches_played + 1)
               ELSE 0 
             END
           WHERE id = ?`,
          [runs, wickets, hundreds, fifties, runs, stat.player_id]
        );
      }
    }

    // 7️⃣ Archive Temporary Players
    // Find players in this match who are marked as temporary and archive them
    await conn.query(
      `UPDATE players 
       SET is_archived = 1 
       WHERE is_temporary = 1 
       AND team_id IN (?, ?)`,
      [match.team1_id, match.team2_id]
    );

    // 8️⃣ Sync Tournament Match Status & Promote Winner
    // If this was a tournament match, ensure the bracket reflects it is finished.
    // 8️⃣ Sync Tournament Match Status & Promote Winner
    // If this was a tournament match, ensure the bracket reflects it is finished.

    if (match.tournament_id) {

      const [updateRes] = await conn.query(
        "UPDATE tournament_matches SET status = 'finished', winner_id = ? WHERE match_id = ?",
        [winnerTeamId, match_id]
      );


      if (updateRes.affectedRows === 0) {
        // Fallback: Find by tournament and teams, ensure we link match_id
        await conn.query(
          `UPDATE tournament_matches 
             SET status = 'finished', winner_id = ?, match_id = ? 
             WHERE tournament_id = ? 
             AND (team1_id IN (?, ?) AND team2_id IN (?, ?))
             AND status != 'finished'`,
          [winnerTeamId, match_id, match.tournament_id, match.team1_id, match.team2_id, match.team1_id, match.team2_id]
        );
      }


      // --- Promotion Logic ---
      const [[currentMatch]] = await conn.query(
        "SELECT id, parent_match_id FROM tournament_matches WHERE match_id = ?",
        [match_id]
      );

      if (currentMatch && currentMatch.parent_match_id) {
        // Determine which slot in the parent match to fill (Team 1 or Team 2)
        // Based on ID order of siblings
        const [siblings] = await conn.query(
          "SELECT id FROM tournament_matches WHERE parent_match_id = ? ORDER BY id ASC",
          [currentMatch.parent_match_id]
        );

        const isFirstChild = (siblings.length > 0 && siblings[0].id === currentMatch.id);
        const targetPrefix = isFirstChild ? 'team1' : 'team2';

        // Find Team TT ID to ensure consistency
        const [[wonTeamTT]] = await conn.query(
          "SELECT id FROM tournament_teams WHERE tournament_id = ? AND team_id = ?",
          [match.tournament_id, winnerTeamId]
        );
        const winnerTTId = wonTeamTT ? wonTeamTT.id : null;

        await conn.query(
          `UPDATE tournament_matches 
             SET ${targetPrefix}_id = ?, ${targetPrefix}_tt_id = ? 
             WHERE id = ?`,
          [winnerTeamId, winnerTTId, currentMatch.parent_match_id]
        );

        console.log(`[Tournament] Promoted Team ${winnerTeamId} to Match ${currentMatch.parent_match_id} (${targetPrefix})`);
      } else if (currentMatch && !currentMatch.parent_match_id) {
        // ✅ NO PARENT MATCH -> THIS IS THE FINAL!
        // Update Tournament Winner and Status
        await conn.query(
          "UPDATE tournaments SET status = 'completed', winner_team_id = ? WHERE id = ?",
          [winnerTeamId, match.tournament_id]
        );
        console.log(`[Tournament] Tournament ${match.tournament_id} COMPLETED. Winner: Team ${winnerTeamId}`);
      }
    }

    await conn.commit();

    return {
      success: true,
      message: "✅ Match finalized successfully",
      winner_id: winnerTeamId,
      score_summary: {
        [match.team1_id]: team1Runs,
        [match.team2_id]: team2Runs
      }
    };

  } catch (err) {
    if (conn) await conn.rollback();
    console.error("Error in finalizeMatchInternal:", err);
    throw err;
  } finally {
    if (conn) conn.release();
  }
};

const finalizeMatch = async (req, res) => {
  const { match_id } = req.body;
  const userId = req.user.id;

  if (!match_id) return res.status(400).json({ error: "Match ID is required" });

  // 0️⃣ Authorization Check
  const authorized = await canScoreForMatch(userId, match_id);
  if (!authorized) {
    return res.status(403).json({ error: "Unauthorized: You don't have permission to finalize this match" });
  }

  try {
    const result = await finalizeMatchInternal(match_id);
    res.json(result);
  } catch (err) {
    const status = err.status || 500;
    logDatabaseError(req.log, "finalizeMatch", err, { match_id });
    res.status(status).json({ error: err.message || "Server error finalizing match" });
  }
};

module.exports = { finalizeMatch, finalizeMatchInternal };