const db = require("../config/db");

/**
 * 📌 Finalize Match
 * Decides winner & updates stats
 */
const finalizeMatch = async (req, res) => {
  const { match_id } = req.body;

  try {
    // 1️⃣ Fetch match
    const [[match]] = await db.query("SELECT * FROM matches WHERE id = ?", [match_id]);
    if (!match) return res.status(404).json({ error: "Match not found" });

    if (match.status === "completed") {
      return res.status(400).json({ error: "Match already finalized" });
    }

    // 2️⃣ Get innings scores
    const [innings] = await db.query(
      "SELECT * FROM match_innings WHERE match_id = ? ORDER BY inning_number ASC",
      [match_id]
    );

    if (innings.length < 2) {
      return res.status(400).json({ error: "Match must have at least 2 innings to finalize" });
    }

    const team1Score = innings[0].runs;
    const team2Score = innings[1].runs;

    let winnerTeamId = null;

    if (team1Score > team2Score) {
      winnerTeamId = innings[0].batting_team_id;
    } else if (team2Score > team1Score) {
      winnerTeamId = innings[1].batting_team_id;
    }

    // 3️⃣ Update match record
    await db.query(
      "UPDATE matches SET status = 'completed', winner_team_id = ? WHERE id = ?",
      [winnerTeamId, match_id]
    );

    // 4️⃣ Update team tournament summary
    if (match.tournament_id) {
      const teams = [match.team1_id, match.team2_id];

      for (const teamId of teams) {
        // Matches played +1
        await db.query(
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
    const [playerStats] = await db.query(
      "SELECT * FROM player_match_stats WHERE match_id = ?",
      [match_id]
    );

    for (const stat of playerStats) {
      await db.query(
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

    res.json({
      message: "✅ Match finalized successfully",
      winner: winnerTeamId || "Match tied",
    });
  } catch (err) {
    console.error("❌ Error in finalizeMatch:", err);
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = { finalizeMatch };
