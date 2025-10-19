const db = require("../config/db");

/**
 * Helper function to check if user can score for a match
 */
const canScoreForMatch = async (userId, matchId) => {
  try {
    // Get match details
    const [match] = await db.query(
      `SELECT m.id, m.team1_id, m.team2_id, m.tournament_id, t.created_by as tournament_creator
       FROM matches m
       LEFT JOIN tournaments t ON m.tournament_id = t.id
       WHERE m.id = ?`,
      [matchId]
    );

    if (match.length === 0) return false;
    const matchData = match[0];

    // Check if user is tournament creator
    if (matchData.tournament_creator === userId) return true;

    // Check if user is owner of either team (registered user)
    const [teams] = await db.query(
      `SELECT t.id, t.owner_id
       FROM teams t
       WHERE t.id IN (?, ?)`,
      [matchData.team1_id, matchData.team2_id]
    );

    return teams.some(team => team.owner_id === userId);
  } catch (err) {
    // Note: No req.log available in helper function
    console.error("Error checking scoring authorization:", err);
    return false;
  }
};

/**
 * Helper function to check if user can score for an innings
 */
const canScoreForInnings = async (userId, inningId) => {
  try {
    const [innings] = await db.query(
      `SELECT mi.batting_team_id, mi.bowling_team_id
       FROM match_innings mi
       WHERE mi.id = ?`,
      [inningId]
    );

    if (innings.length === 0) return false;
    const inningData = innings[0];

    // Check if user is owner of batting or bowling team (registered user)
    const [teams] = await db.query(
      `SELECT t.id, t.owner_id
       FROM teams t
       WHERE t.id IN (?, ?)`,
      [inningData.batting_team_id, inningData.bowling_team_id]
    );

    return teams.some(team => team.owner_id === userId);
  } catch (err) {
    // Note: No req.log available in helper function
    console.error("Error checking innings scoring authorization:", err);
    return false;
  }
};

/**
 * 📌 Start Innings
 */
const startInnings = async (req, res) => {
  const { match_id, batting_team_id, bowling_team_id, inning_number } = req.body;

  try {
    // Authorization check
    const canScore = await canScoreForMatch(req.user.id, match_id);
    if (!canScore) {
      return res.status(403).json({ error: "Unauthorized: You cannot score for this match" });
    }

    const [match] = await db.query("SELECT * FROM matches WHERE id = ?", [match_id]);

    if (match.length === 0) return res.status(404).json({ error: "Match not found" });
    if (match[0].status !== "live")
      return res.status(400).json({ error: "Match must be live to start innings" });

    await db.query(
      `INSERT INTO match_innings 
       (match_id, team_id, batting_team_id, bowling_team_id, inning_number, runs, wickets, overs, status) 
       VALUES (?, ?, ?, ?, ?, 0, 0, 0, 'in_progress')`,
      [match_id, batting_team_id, batting_team_id, bowling_team_id, inning_number]
    );

    res.json({ message: `Innings ${inning_number} started successfully` });
  } catch (err) {
    req.log?.error("startInnings: Database error", { error: err.message, code: err.code, matchId: match_id });
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
    // Authorization check
    const canScore = await canScoreForInnings(req.user.id, inning_id);
    if (!canScore) {
      return res.status(403).json({ error: "Unauthorized: You cannot score for this innings" });
    }

    // Input validation
    if (!match_id || !inning_id || over_number === undefined || ball_number === undefined || 
        !batsman_id || !bowler_id || runs === undefined) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    if (ball_number < 1 || ball_number > 6) {
      return res.status(400).json({ error: "Ball number must be between 1 and 6" });
    }

    if (over_number < 0) {
      return res.status(400).json({ error: "Over number must be non-negative" });
    }

    if (runs < 0 || runs > 6) {
      return res.status(400).json({ error: "Runs must be between 0 and 6" });
    }

    // Check innings status
    const [[inningStatus]] = await db.query(
      `SELECT status FROM match_innings WHERE id = ?`,
      [inning_id]
    );
    
    if (!inningStatus) {
      return res.status(404).json({ error: "Innings not found" });
    }

    if (inningStatus.status !== 'in_progress') {
      return res.status(400).json({ error: "Innings is not in progress" });
    }

    // Check for duplicate delivery
    const [existingBall] = await db.query(
      `SELECT id FROM ball_by_ball 
       WHERE inning_id = ? AND over_number = ? AND ball_number = ?`,
      [inning_id, over_number, ball_number]
    );

    if (existingBall.length > 0) {
      return res.status(409).json({ error: "Ball already exists for this position" });
    }

    // Validate ball sequencing
    const [lastBall] = await db.query(
      `SELECT over_number, ball_number FROM ball_by_ball 
       WHERE inning_id = ? 
       ORDER BY over_number DESC, ball_number DESC 
       LIMIT 1`,
      [inning_id]
    );

    if (lastBall.length > 0) {
      const lastOver = lastBall[0].over_number;
      const lastBallNum = lastBall[0].ball_number;
      
      // Check if this ball is the next logical ball
      const expectedOver = lastBallNum === 6 ? lastOver + 1 : lastOver;
      const expectedBall = lastBallNum === 6 ? 1 : lastBallNum + 1;
      
      if (over_number !== expectedOver || ball_number !== expectedBall) {
        return res.status(400).json({ 
          error: `Invalid ball sequence. Expected over ${expectedOver}, ball ${expectedBall}` 
        });
      }
    } else if (over_number !== 0 || ball_number !== 1) {
      // First ball must be 0.1
      return res.status(400).json({ 
        error: "First ball must be over 0, ball 1" 
      });
    }

    // Insert ball record
    await db.query(
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
    await db.query(
      `UPDATE match_innings 
       SET runs = runs + ?, 
           wickets = wickets + IF(?, 1, 0) 
       WHERE id = ?`,
      [runs, wicket_type ? 1 : 0, inning_id]
    );

    // Update overs - only count legal balls (exclude wides/no-balls)
    const isLegalBall = !extras || (extras !== 'wide' && extras !== 'no-ball');
    if (isLegalBall) {
      // Calculate total legal balls for this innings
      const [legalBallsResult] = await db.query(
        `SELECT COUNT(*) as total_legal_balls 
         FROM ball_by_ball 
         WHERE inning_id = ? AND (extras IS NULL OR extras NOT IN ('wide', 'no-ball'))`,
        [inning_id]
      );
      
      const totalLegalBalls = legalBallsResult[0].total_legal_balls;
      const oversDecimal = totalLegalBalls / 6;
      const oversInteger = Math.floor(oversDecimal);
      
      // Update both overs_decimal and overs
      await db.query(
        `UPDATE match_innings SET overs_decimal = ?, overs = ? WHERE id = ?`, 
        [oversDecimal, oversInteger, inning_id]
      );
    }

    // ✅ Captain check - use owner_id for authorization
    const [[inningTeams]] = await db.query(
      `SELECT batting_team_id, bowling_team_id FROM match_innings WHERE id = ?`,
      [inning_id]
    );

    const [[battingTeam]] = await db.query(
      "SELECT owner_id FROM teams WHERE id = ?",
      [inningTeams.batting_team_id]
    );

    const [[bowlingTeam]] = await db.query(
      "SELECT owner_id FROM teams WHERE id = ?",
      [inningTeams.bowling_team_id]
    );

    // ✅ If scorer is batting team owner → update batsman stats
    if (battingTeam && battingTeam.owner_id === req.user.id) {
      await db.query(
        `INSERT INTO player_match_stats (match_id, player_id, runs, balls_faced) 
         VALUES (?, ?, ?, 1) 
         ON DUPLICATE KEY UPDATE runs = runs + VALUES(runs), balls_faced = balls_faced + 1`,
        [match_id, batsman_id, runs]
      );
    }

    // ✅ If scorer is bowling team owner → update bowler stats
    if (bowlingTeam && bowlingTeam.owner_id === req.user.id) {
      await db.query(
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
    const [[inningCheck]] = await db.query(`SELECT * FROM match_innings WHERE id = ?`, [inning_id]);
    const [[matchCheck]] = await db.query(`SELECT overs FROM matches WHERE id = ?`, [match_id]);

    // Convert overs to legal balls for comparison (overs * 6)
    const legalBallsBowled = Math.floor(inningCheck.overs) * 6 + (ball_number % 6);
    const maxLegalBalls = matchCheck.overs * 6;

    if (inningCheck.wickets >= 10 || legalBallsBowled >= maxLegalBalls) {
      await db.query(`UPDATE match_innings SET status = 'completed' WHERE id = ?`, [inning_id]);
      return res.json({ message: "Ball recorded. Innings ended automatically", autoEnded: true });
    }

    res.json({ message: "Ball recorded successfully" });
  } catch (err) {
    req.log?.error("addBall: Database error", { error: err.message, code: err.code, matchId: match_id, inningId: inning_id });
    res.status(500).json({ error: "Server error" });
  }
};

/**
 * 📌 Manual End Innings
 */
const endInnings = async (req, res) => {
  const { inning_id } = req.body;

  try {
    // Authorization check
    const canScore = await canScoreForInnings(req.user.id, inning_id);
    if (!canScore) {
      return res.status(403).json({ error: "Unauthorized: You cannot score for this innings" });
    }

    const [[inning]] = await db.query(`SELECT * FROM match_innings WHERE id = ?`, [inning_id]);
    if (!inning) return res.status(404).json({ error: "Innings not found" });

    if (inning.status === "completed")
      return res.status(400).json({ error: "Innings already ended" });

    await db.query(`UPDATE match_innings SET status = 'completed' WHERE id = ?`, [inning_id]);

    res.json({ message: `Innings ${inning.inning_number} ended manually` });
  } catch (err) {
    req.log?.error("endInnings: Database error", { error: err.message, code: err.code, inningId: inning_id });
    res.status(500).json({ error: "Server error" });
  }
};

/**
 * 📌 Get Live Score
 */
const getLiveScore = async (req, res) => {
  const { match_id } = req.params;

  try {
    const [innings] = await db.query(
      `SELECT * FROM match_innings WHERE match_id = ? ORDER BY inning_number ASC`,
      [match_id]
    );

    const [balls] = await db.query(
      `SELECT * FROM ball_by_ball WHERE match_id = ? ORDER BY id ASC`,
      [match_id]
    );

    const [players] = await db.query(
      `SELECT * FROM player_match_stats WHERE match_id = ?`,
      [match_id]
    );

    res.json({ innings, balls, players });
  } catch (err) {
    req.log?.error("getLiveScore: Database error", { error: err.message, code: err.code, matchId: match_id });
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = { startInnings, addBall, endInnings, getLiveScore };
