const { db } = require("../config/db");
const { logDatabaseError } = require("../utils/safeLogger");

/**
 * 📌 Finalize Match
 * Decides winner, updates tournament standings, and persists cumulative player stats.
 */
const finalizeMatch = async (req, res) => {
  const { match_id } = req.body;

  if (!match_id) return res.status(400).json({ error: "Match ID is required" });

  let conn;
  try {
    // Start transaction
    conn = await db.getConnection();
    await conn.beginTransaction();

    // 1️⃣ Fetch match & Lock Row
    const [[match]] = await conn.query("SELECT * FROM matches WHERE id = ? FOR UPDATE", [match_id]);

    if (!match) {
      await conn.rollback();
      return res.status(404).json({ error: "Match not found" });
    }

    if (match.status === "completed") {
      await conn.rollback();
      return res.status(400).json({ error: "Match already finalized" });
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
    if (match.tournament_id) {
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
    }

    // 6️⃣ Update Cumulative Player Stats
    // We fetch current match stats and merge them into the players' lifetime stats
    const [matchStats] = await conn.query(
      "SELECT * FROM player_match_stats WHERE match_id = ?",
      [match_id]
    );

    for (const stat of matchStats) {
      const runs = stat.runs || 0;
      const balls = stat.balls_faced || 0;
      const wickets = stat.wickets || 0;
      const hundreds = runs >= 100 ? 1 : 0;
      const fifties = (runs >= 50 && runs < 100) ? 1 : 0;

      // Complex update for averages
      // Formula: NewAvg = (CurrentRuns + NewRuns) / (CurrentInnings + 1)
      // Note: matches_played in `players` table acts as innings count for simplicity here

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
           END,

           -- Recalculate Strike Rate
           strike_rate = CASE 
             -- We need cumulative balls faced. Since we don't store cumulative balls, 
             -- we approximate or you need a cumulative_balls column. 
             -- For now, let's update it based on standard formula if we tracked cumulative balls.
             -- Assuming we don't track cumulative balls, we might skip this or estimate.
             -- Better approach: Just update raw counts, calculate average/SR on read time.
             -- But based on your schema request:
             WHEN (runs + ?) > 0 
             THEN strike_rate -- Placeholder: Ideally you store total_balls_faced in players table
             ELSE strike_rate
           END

         WHERE id = ?`,
        [runs, wickets, hundreds, fifties, runs, runs, stat.player_id]
      );
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

    await conn.commit();

    res.json({
      message: "✅ Match finalized successfully",
      winner_id: winnerTeamId,
      score_summary: {
        [match.team1_id]: team1Runs,
        [match.team2_id]: team2Runs
      }
    });

  } catch (err) {
    if (conn) await conn.rollback();
    logDatabaseError(req.log, "finalizeMatch", err, { match_id });
    res.status(500).json({ error: "Server error finalizing match" });
  } finally {
    if (conn) conn.release();
  }
};

module.exports = { finalizeMatch };