const db = require("../config/db");

/**
 * 📌 Finalize Match
 * Decides winner & updates stats
 */
const finalizeMatch = async (req, res) => {
  const { match_id } = req.body;

  let conn;
  try {
    // Start transaction
    conn = await db.getConnection();
    await conn.beginTransaction();

    // 1️⃣ Fetch match with defensive status check
    const [[match]] = await conn.query("SELECT * FROM matches WHERE id = ? FOR UPDATE", [match_id]);
    if (!match) {
      await conn.rollback();
      return res.status(404).json({ error: "Match not found" });
    }

    if (match.status === "completed") {
      await conn.rollback();
      return res.status(400).json({ error: "Match already finalized" });
    }

    if (match.status !== "live") {
      await conn.rollback();
      return res.status(400).json({ error: "Match must be live to finalize" });
    }

    // 2️⃣ Get innings scores grouped by inning_number
    const [innings] = await conn.query(
      "SELECT * FROM match_innings WHERE match_id = ? ORDER BY inning_number ASC",
      [match_id]
    );

    // Validate there are at least first innings for both teams
    if (innings.length < 2) {
      await conn.rollback();
      return res.status(400).json({ error: "Match must have at least 2 innings to finalize" });
    }

    // Map innings to match teams deterministically
    const team1Innings = innings.filter(inning => inning.batting_team_id === match.team1_id);
    const team2Innings = innings.filter(inning => inning.batting_team_id === match.team2_id);

    if (team1Innings.length === 0 || team2Innings.length === 0) {
      await conn.rollback();
      return res.status(400).json({ error: "Both teams must have at least one innings" });
    }

    // Calculate total runs for each team
    const team1TotalRuns = team1Innings.reduce((sum, inning) => sum + inning.runs, 0);
    const team2TotalRuns = team2Innings.reduce((sum, inning) => sum + inning.runs, 0);

    let winnerTeamId = null;

    // Handle ties explicitly - set winner_team_id to null for ties
    if (team1TotalRuns > team2TotalRuns) {
      winnerTeamId = match.team1_id;
    } else if (team2TotalRuns > team1TotalRuns) {
      winnerTeamId = match.team2_id;
    }
    // If scores are equal, winnerTeamId remains null (tie)

    // 3️⃣ Update match record with transaction
    await conn.query(
      "UPDATE matches SET status = 'completed', winner_team_id = ? WHERE id = ?",
      [winnerTeamId, match_id]
    );

    // 4️⃣ Update team tournament summary
    if (match.tournament_id) {
      const teams = [match.team1_id, match.team2_id];

      for (const teamId of teams) {
        // Matches played +1
        await conn.query(
          `INSERT INTO team_tournament_summary (tournament_id, team_id, matches_played, matches_won) 
           VALUES (?, ?, 1, ?) 
           ON DUPLICATE KEY UPDATE 
             matches_played = matches_played + 1, 
             matches_won = matches_won + VALUES(matches_won)`,
          [match.tournament_id, teamId, teamId === winnerTeamId ? 1 : 0]
        );
      }
    }

    // 5️⃣ Update players permanent stats (from player_match_stats)
    const [playerStats] = await conn.query(
      "SELECT * FROM player_match_stats WHERE match_id = ?",
      [match_id]
    );

    for (const stat of playerStats) {
      await conn.query(
        `UPDATE players 
         SET 
           runs = runs + ?, 
           matches_played = matches_played + 1, 
           wickets = wickets + ?,
           batting_average = IF(matches_played + 1 > 0, (runs + ?) / (matches_played + 1), batting_average),
           strike_rate = IF(balls_faced > 0, ((runs + ?) / (balls_faced)) * 100, strike_rate)
         WHERE id = ?`,
        [stat.runs || 0, stat.wickets || 0, stat.runs || 0, stat.runs || 0, stat.player_id]
      );
    }

    // Commit transaction
    await conn.commit();

    res.json({
      message: "✅ Match finalized successfully",
      winner: winnerTeamId || "Match tied",
      team1Runs: team1TotalRuns,
      team2Runs: team2TotalRuns
    });
  } catch (err) {
    if (conn) {
      await conn.rollback();
    }
    console.error("❌ Error in finalizeMatch:", err);
    res.status(500).json({ error: "Server error" });
  } finally {
    if (conn) {
      conn.release();
    }
  }
};

module.exports = { finalizeMatch };
