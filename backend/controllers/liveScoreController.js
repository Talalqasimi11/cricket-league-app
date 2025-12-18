const { db } = require("../config/db");
const { withTransaction } = require("../utils/transactionWrapper");

// Lazy import io instance to avoid circular dependency
let io = null;
const setIo = (ioInstance) => {
  io = ioInstance;
};

const getIo = () => {
  if (!io) {
    console.warn("Socket.IO not initialized in liveScoreController");
  }
  return io;
};

// ==========================================
// HELPER FUNCTIONS (Authorization)
// ==========================================

const canScoreForMatch = async (userId, matchId) => {
  try {
    const [match] = await db.query(
      `SELECT m.id, m.team1_id, m.team2_id, m.tournament_id, t.created_by as tournament_creator
       FROM matches m
       LEFT JOIN tournaments t ON m.tournament_id = t.id
       WHERE m.id = ?`,
      [matchId]
    );

    if (match.length === 0) return false;
    const matchData = match[0];

    if (matchData.tournament_creator === userId) return true;

    const [teams] = await db.query(
      `SELECT id FROM teams WHERE id IN (?, ?) AND owner_id = ?`,
      [matchData.team1_id, matchData.team2_id, userId]
    );

    return teams.length > 0;
  } catch (err) {
    console.error("Error checking scoring auth:", err);
    return false;
  }
};

const canScoreForInnings = async (userId, inningId) => {
  try {
    const [innings] = await db.query(
      `SELECT mi.batting_team_id, mi.bowling_team_id FROM match_innings mi WHERE mi.id = ?`,
      [inningId]
    );

    if (innings.length === 0) return false;
    const inningData = innings[0];

    const [teams] = await db.query(
      `SELECT id FROM teams WHERE id IN (?, ?) AND owner_id = ?`,
      [inningData.batting_team_id, inningData.bowling_team_id, userId]
    );

    return teams.length > 0;
  } catch (err) {
    console.error("Error checking innings auth:", err);
    return false;
  }
};

// ==========================================
// CONTROLLER METHODS
// ==========================================

// 📌 Start Innings
const startInnings = async (req, res) => {
  const { match_id, batting_team_id, bowling_team_id, inning_number } = req.body;
  console.log("🚀 startInnings called with:", req.body);

  try {
    const canScore = await canScoreForMatch(req.user.id, match_id);
    if (!canScore) {
      console.log("❌ Unauthorized access for match:", match_id);
      return res.status(403).json({ error: "Unauthorized" });
    }

    const [match] = await db.query("SELECT status FROM matches WHERE id = ?", [match_id]);
    console.log("🔍 Match found:", match);

    if (match.length === 0) return res.status(404).json({ error: "Match not found" });

    // ✅ Auto-start match if not already live
    if (match[0].status !== "live") {
      if (match[0].status === "completed" || match[0].status === "cancelled") {
        return res.status(400).json({ error: "Match is already completed or cancelled" });
      }

      console.log("⚠️ Match not live. Auto-starting match:", match_id);
      await db.query("UPDATE matches SET status = 'live' WHERE id = ?", [match_id]);
    }

    const [result] = await db.query(
      `INSERT INTO match_innings 
       (match_id, team_id, batting_team_id, bowling_team_id, inning_number, runs, wickets, overs, status) 
       VALUES (?, ?, ?, ?, ?, 0, 0, 0, 'in_progress')`,
      [match_id, batting_team_id, batting_team_id, bowling_team_id, inning_number]
    );

    res.json({ message: `Innings ${inning_number} started`, inning_id: result.insertId });
  } catch (err) {
    console.error("❌ Error in startInnings:", err);
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Add Ball (Core Scoring Logic)
const addBall = async (req, res) => {
  const {
    match_id, inning_id, over_number, ball_number, batsman_id, bowler_id,
    runs, extras, wicket_type, out_player_id,
  } = req.body;

  const normalizedExtras = extras ?? null;

  try {
    if (!await canScoreForInnings(req.user.id, inning_id)) {
      return res.status(403).json({ error: "Unauthorized" });
    }

    // Basic Validation
    if (!match_id || !inning_id || over_number === undefined || ball_number === undefined || !batsman_id || !bowler_id || runs === undefined) {
      return res.status(400).json({ error: "Missing fields" });
    }
    if (runs < 0) return res.status(400).json({ error: "Runs must be positive" });

    // Execute Transaction
    const result = await withTransaction(async (conn) => {
      // 1. Innings State Check
      const [[inningStatus]] = await conn.query(`SELECT status FROM match_innings WHERE id = ?`, [inning_id]);
      if (!inningStatus || inningStatus.status !== 'in_progress') {
        throw { statusCode: 400, message: "Innings not in progress" };
      }

      // 2. Calculate Sequence and Ball Number
      const [[lastSeq]] = await conn.query(
        `SELECT COALESCE(MAX(sequence), -1) + 1 AS next_seq FROM ball_by_ball WHERE inning_id = ? FOR UPDATE`,
        [inning_id]
      );
      const sequence = lastSeq.next_seq;

      // ✅ Auto-calculate ball_number to prevent duplicates
      const [[lastBall]] = await conn.query(
        `SELECT COALESCE(MAX(ball_number), 0) + 1 AS next_ball FROM ball_by_ball WHERE inning_id = ? AND over_number = ?`,
        [inning_id, over_number]
      );
      const calculatedBallNumber = lastBall.next_ball;

      // 3. Insert Ball
      await conn.query(
        `INSERT INTO ball_by_ball 
         (match_id, inning_id, over_number, ball_number, sequence, batsman_id, bowler_id, runs, extras, wicket_type, out_player_id) 
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [match_id, inning_id, over_number, calculatedBallNumber, sequence, batsman_id, bowler_id, runs, normalizedExtras, wicket_type || null, out_player_id || null]
      );

      // 4. Update Innings Totals
      const isWicket = wicket_type ? 1 : 0;
      await conn.query(
        `UPDATE match_innings SET runs = runs + ?, wickets = wickets + ? WHERE id = ?`,
        [runs, isWicket, inning_id]
      );

      // 5. Update Overs (Legal balls only)
      const isLegalBall = !['wide', 'no-ball'].includes(normalizedExtras);
      if (isLegalBall) {
        await conn.query(`UPDATE match_innings SET legal_balls = legal_balls + 1 WHERE id = ?`, [inning_id]);
        await conn.query(
          `UPDATE match_innings 
           SET overs_decimal = FLOOR(legal_balls/6) + (legal_balls % 6)/10, 
           overs = FLOOR(legal_balls / 6) 
           WHERE id = ?`,
          [inning_id]
        );
      }

      // 6. Update Player Stats
      // Batsman Logic
      let batsmanRuns = 0;
      let ballsFaced = (normalizedExtras !== 'wide') ? 1 : 0;

      if (!normalizedExtras) batsmanRuns = runs;
      else if (normalizedExtras === 'no-ball') batsmanRuns = Math.max(0, runs - 1);
      // Wides/Byes = 0 runs to batsman

      const isFour = batsmanRuns === 4 ? 1 : 0;
      const isSix = batsmanRuns === 6 ? 1 : 0;

      await conn.query(
        `INSERT INTO player_match_stats (match_id, player_id, runs, balls_faced, fours, sixes) 
         VALUES (?, ?, ?, ?, ?, ?) 
         ON DUPLICATE KEY UPDATE 
         runs = runs + VALUES(runs), balls_faced = balls_faced + VALUES(balls_faced),
         fours = fours + VALUES(fours), sixes = sixes + VALUES(sixes)`,
        [match_id, batsman_id, batsmanRuns, ballsFaced, isFour, isSix]
      );

      // Bowler Logic
      const ballsBowled = isLegalBall ? 1 : 0;
      // Byes/Leg-byes are NOT charged to bowler runs, Wides/No-balls ARE
      let bowlerRuns = runs;
      if (normalizedExtras === 'bye' || normalizedExtras === 'leg-bye') bowlerRuns = 0;

      await conn.query(
        `INSERT INTO player_match_stats (match_id, player_id, balls_bowled, runs_conceded, wickets) 
         VALUES (?, ?, ?, ?, ?) 
         ON DUPLICATE KEY UPDATE 
         balls_bowled = balls_bowled + VALUES(balls_bowled), 
         runs_conceded = runs_conceded + VALUES(runs_conceded), 
         wickets = wickets + VALUES(wickets)`,
        [match_id, bowler_id, ballsBowled, bowlerRuns, isWicket]
      );

      // 7. Auto-End Logic
      const [[matchData]] = await conn.query("SELECT overs FROM matches WHERE id = ?", [match_id]);
      const [[updatedInning]] = await conn.query("SELECT * FROM match_innings WHERE id = ?", [inning_id]);

      const maxBalls = matchData.overs * 6;
      const shouldEnd = updatedInning.wickets >= 10 || updatedInning.legal_balls >= maxBalls;

      if (shouldEnd) {
        await conn.query("UPDATE match_innings SET status = 'completed' WHERE id = ?", [inning_id]);
      }

      return { updatedInning, shouldEnd, sequence };
    });

    // Socket Emit
    const socketIo = getIo();
    if (socketIo) {
      const [balls] = await db.query(
        `SELECT b.*, bat.player_name as batsman_name, bowl.player_name as bowler_name 
         FROM ball_by_ball b
         LEFT JOIN players bat ON b.batsman_id = bat.id
         LEFT JOIN players bowl ON b.bowler_id = bowl.id
         WHERE b.match_id = ? ORDER BY b.sequence ASC`,
        [match_id]
      );

      socketIo.of('/live-score').to(`match:${match_id}`).emit('scoreUpdate', {
        matchId: match_id,
        inning: result.updatedInning,
        allBalls: balls,
        autoEnded: result.shouldEnd
      });
    }

    res.json({ message: "Ball recorded", autoEnded: result.shouldEnd });

  } catch (err) {
    req.log?.error(err);
    const status = err.statusCode || 500;
    res.status(status).json({ error: err.message || "Server error" });
  }
};

// 📌 Undo Last Ball
const undoLastBall = async (req, res) => {
  const { match_id, inning_id } = req.body;

  try {
    if (!await canScoreForInnings(req.user.id, inning_id)) return res.status(403).json({ error: "Unauthorized" });

    await withTransaction(async (conn) => {
      const [balls] = await conn.query(
        `SELECT * FROM ball_by_ball WHERE match_id = ? AND inning_id = ? ORDER BY id DESC LIMIT 1 FOR UPDATE`,
        [match_id, inning_id]
      );

      if (balls.length === 0) throw { statusCode: 400, message: "No balls to undo" };
      const ball = balls[0];

      // Delete
      await conn.query(`DELETE FROM ball_by_ball WHERE id = ? `, [ball.id]);

      // Reverse Innings
      const isWicket = ball.wicket_type ? 1 : 0;
      const isLegal = !['wide', 'no-ball'].includes(ball.extras);

      await conn.query(
        `UPDATE match_innings 
         SET runs = runs - ?, wickets = wickets - ?, legal_balls = legal_balls - ?
      WHERE id = ? `,
        [ball.runs, isWicket, isLegal ? 1 : 0, inning_id]
      );

      await conn.query(
        `UPDATE match_innings 
         SET overs = FLOOR(legal_balls / 6),
      overs_decimal = FLOOR(legal_balls / 6) + (legal_balls % 6) / 10 
         WHERE id = ? `,
        [inning_id]
      );

      // Reverse Player Stats (Simplified: Subtract what was added)
      let batsmanRuns = 0;
      if (!ball.extras) batsmanRuns = ball.runs;
      else if (ball.extras === 'no-ball') batsmanRuns = Math.max(0, ball.runs - 1);

      let bowlerRuns = ball.runs;
      if (ball.extras === 'bye' || ball.extras === 'leg-bye') bowlerRuns = 0;

      await conn.query(
        `UPDATE player_match_stats 
         SET runs = runs - ?, balls_faced = balls_faced - ?
      WHERE match_id = ? AND player_id = ? `,
        [batsmanRuns, (ball.extras !== 'wide' ? 1 : 0), match_id, ball.batsman_id]
      );

      await conn.query(
        `UPDATE player_match_stats 
         SET runs_conceded = runs_conceded - ?, balls_bowled = balls_bowled - ?, wickets = wickets - ?
      WHERE match_id = ? AND player_id = ? `,
        [bowlerRuns, (isLegal ? 1 : 0), isWicket, match_id, ball.bowler_id]
      );
    });

    // Socket Update (Fetch fresh state)
    const socketIo = getIo();
    if (socketIo) {
      const [[updatedInning]] = await db.query("SELECT * FROM match_innings WHERE id = ?", [inning_id]);
      const [balls] = await db.query(
        `SELECT b.*, bat.player_name as batsman_name, bowl.player_name as bowler_name 
         FROM ball_by_ball b
         LEFT JOIN players bat ON b.batsman_id = bat.id
         LEFT JOIN players bowl ON b.bowler_id = bowl.id
         WHERE b.match_id = ? ORDER BY b.sequence ASC`,
        [match_id]
      );

      socketIo.of('/live-score').to(`match:${match_id} `).emit('scoreUpdate', {
        matchId: match_id,
        inning: updatedInning,
        allBalls: balls,
        autoEnded: false // Undo implies resumption
      });
    }

    res.json({ message: "Undo successful" });

  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    res.status(status).json({ error: err.message || "Server error" });
  }
};

// 📌 End Innings
const endInnings = async (req, res) => {
  const { inning_id } = req.body;
  try {
    if (!await canScoreForInnings(req.user.id, inning_id)) return res.status(403).json({ error: "Unauthorized" });

    await db.query("UPDATE match_innings SET status = 'completed' WHERE id = ?", [inning_id]);

    const socketIo = getIo();
    if (socketIo) {
      const [[inning]] = await db.query("SELECT * FROM match_innings WHERE id = ?", [inning_id]);
      socketIo.of('/live-score').to(`match:${inning.match_id} `).emit('inningsEnded', {
        matchId: inning.match_id,
        inningId: inning_id,
        inning
      });
    }
    res.json({ message: "Innings ended" });
  } catch (err) {
    req.log?.error(err);
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Get Live Score Data
const getLiveScore = async (req, res) => {
  const { match_id } = req.params;
  try {
    const [matchDetails] = await db.query("SELECT id, team1_id, team2_id, overs, status FROM matches WHERE id = ?", [match_id]);
    const [innings] = await db.query("SELECT * FROM match_innings WHERE match_id = ? ORDER BY inning_number ASC", [match_id]);
    const [balls] = await db.query(
      `SELECT b.*, bat.player_name as batsman_name, bowl.player_name as bowler_name 
       FROM ball_by_ball b
       LEFT JOIN players bat ON b.batsman_id = bat.id
       LEFT JOIN players bowl ON b.bowler_id = bowl.id
       WHERE b.match_id = ? ORDER BY b.sequence ASC`,
      [match_id]
    );
    const [players] = await db.query("SELECT * FROM player_match_stats WHERE match_id = ?", [match_id]);

    res.json({
      ...matchDetails[0], // Spread match details (team1_id, team2_id, etc.)
      innings,
      balls,
      players
    });
  } catch (err) {
    req.log?.error(err);
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = { startInnings, addBall, endInnings, getLiveScore, undoLastBall, setIo };