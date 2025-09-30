const pool = require("../config/db");

/**
 * 📌 Start Innings
 */
const startInnings = async (req, res) => {
  const { match_id, batting_team_id, bowling_team_id, inning_number } = req.body;

  try {
    const [match] = await pool.query("SELECT * FROM matches WHERE id = ?", [match_id]);

    if (match.length === 0) return res.status(404).json({ error: "Match not found" });
    if (match[0].status !== "live")
      return res.status(400).json({ error: "Match must be live to start innings" });

    await pool.query(
      `INSERT INTO match_innings 
       (match_id, batting_team_id, bowling_team_id, inning_number, runs, wickets, overs, status) 
       VALUES (?, ?, ?, ?, 0, 0, 0, 'in_progress')`,
      [match_id, batting_team_id, bowling_team_id, inning_number]
    );

    res.json({ message: `Innings ${inning_number} started successfully` });
  } catch (err) {
    console.error("❌ Error in startInnings:", err);
    res.status(500).json({ error: "Server error" });
  }
};

/**
 * 📌 Add Ball Entry (auto checks for innings end)
 */
const addBall = async (req, res) => {
  const {
    match_id,
    inning_id,
    over_number,
    ball_number,
    batsman_id,
    bowler_id,
    runs,
    extras,
    wicket_type,
    out_player_id,
  } = req.body;

  try {
    // Insert ball record
    await pool.query(
      `INSERT INTO ball_by_ball 
      (match_id, inning_id, over_number, ball_number, batsman_id, bowler_id, runs, extras, wicket_type, out_player_id) 
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        match_id,
        inning_id,
        over_number,
        ball_number,
        batsman_id,
        bowler_id,
        runs,
        extras || null,
        wicket_type || null,
        out_player_id || null,
      ]
    );

    // Update innings table
    await pool.query(
      `UPDATE match_innings 
       SET runs = runs + ?, 
           wickets = wickets + IF(?, 1, 0) 
       WHERE id = ?`,
      [runs, wicket_type ? 1 : 0, inning_id]
    );

    // Update overs when 6th ball
    if (ball_number === 6) {
      await pool.query(`UPDATE match_innings SET overs = overs + 1 WHERE id = ?`, [inning_id]);
    }

    // ✅ Captain check
    const [[inning]] = await pool.query(
      `SELECT batting_team_id, bowling_team_id FROM match_innings WHERE id = ?`,
      [inning_id]
    );

    const [[battingTeam]] = await pool.query(
      "SELECT captain_id FROM teams WHERE id = ?",
      [inning.batting_team_id]
    );

    const [[bowlingTeam]] = await pool.query(
      "SELECT captain_id FROM teams WHERE id = ?",
      [inning.bowling_team_id]
    );

    // ✅ If scorer is batting team captain → update batsman stats
    if (battingTeam && battingTeam.captain_id === req.user.id) {
      await pool.query(
        `INSERT INTO player_match_stats (match_id, player_id, runs, balls_faced) 
         VALUES (?, ?, ?, 1) 
         ON DUPLICATE KEY UPDATE runs = runs + VALUES(runs), balls_faced = balls_faced + 1`,
        [match_id, batsman_id, runs]
      );
    }

    // ✅ If scorer is bowling team captain → update bowler stats
    if (bowlingTeam && bowlingTeam.captain_id === req.user.id) {
      await pool.query(
        `INSERT INTO player_match_stats (match_id, player_id, balls_bowled, runs_conceded, wickets) 
         VALUES (?, ?, 1, ?, ?) 
         ON DUPLICATE KEY UPDATE 
           balls_bowled = balls_bowled + 1, 
           runs_conceded = runs_conceded + VALUES(runs_conceded), 
           wickets = wickets + VALUES(wickets)`,
        [match_id, bowler_id, runs, wicket_type ? 1 : 0]
      );
    }

    // 🔄 Auto-end innings if all out or overs finished
    const [[inningCheck]] = await pool.query(`SELECT * FROM match_innings WHERE id = ?`, [inning_id]);
    const [[matchCheck]] = await pool.query(`SELECT overs FROM matches WHERE id = ?`, [match_id]);

    if (inningCheck.wickets >= 10 || inningCheck.overs >= matchCheck.overs) {
      await pool.query(`UPDATE match_innings SET status = 'completed' WHERE id = ?`, [inning_id]);
      return res.json({ message: "Ball recorded. Innings ended automatically", autoEnded: true });
    }

    res.json({ message: "Ball recorded successfully" });
  } catch (err) {
    console.error("❌ Error in addBall:", err);
    res.status(500).json({ error: "Server error" });
  }
};

/**
 * 📌 Manual End Innings
 */
const endInnings = async (req, res) => {
  const { inning_id } = req.body;

  try {
    const [[inning]] = await pool.query(`SELECT * FROM match_innings WHERE id = ?`, [inning_id]);
    if (!inning) return res.status(404).json({ error: "Innings not found" });

    if (inning.status === "completed")
      return res.status(400).json({ error: "Innings already ended" });

    await pool.query(`UPDATE match_innings SET status = 'completed' WHERE id = ?`, [inning_id]);

    res.json({ message: `Innings ${inning.inning_number} ended manually` });
  } catch (err) {
    console.error("❌ Error in endInnings:", err);
    res.status(500).json({ error: "Server error" });
  }
};

/**
 * 📌 Get Live Score
 */
const getLiveScore = async (req, res) => {
  const { match_id } = req.params;

  try {
    const [innings] = await pool.query(
      `SELECT * FROM match_innings WHERE match_id = ? ORDER BY inning_number ASC`,
      [match_id]
    );

    const [balls] = await pool.query(
      `SELECT * FROM ball_by_ball WHERE match_id = ? ORDER BY id ASC`,
      [match_id]
    );

    const [players] = await pool.query(
      `SELECT * FROM player_match_stats WHERE match_id = ?`,
      [match_id]
    );

    res.json({ innings, balls, players });
  } catch (err) {
    console.error("❌ Error in getLiveScore:", err);
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = { startInnings, addBall, endInnings, getLiveScore };
