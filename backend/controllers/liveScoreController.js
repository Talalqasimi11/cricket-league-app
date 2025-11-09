const { db } = require("../config/db");
const { withTransaction } = require("../utils/transactionWrapper");

// Lazy import io instance to avoid circular dependency
let io = null;
const getIo = () => {
  if (!io) {
    // Only import when needed (after index.js has been fully loaded)
    try {
      const indexModule = require("../index");
      io = indexModule.io;
    } catch (err) {
      console.warn("Socket.IO not available:", err.message);
    }
  }
  return io;
};

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

    // Check if user is owner of either team
    const [teams] = await db.query(
      `SELECT t.id, t.owner_id
       FROM teams t
       WHERE t.id IN (?, ?) AND t.owner_id = ?`,
      [matchData.team1_id, matchData.team2_id, userId]
    );

    return teams.length > 0;
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
 * 
 * API Contract (Scoring Data Model):
 * Single 'runs' field represents TOTAL runs for the delivery:
 *   - Legal balls (extras=null): runs off bat, 0-6
 *   - Wides/No-balls (extras='wide'|'no-ball'): penalty runs, 0+
 *   - Byes/Leg-byes (extras='bye'|'leg-bye'): unearned runs, 1+
 * 
 * Over/Ball Numbering:
 *   - over_number: 0-based (0 = first over, 1 = second over, etc.)
 *   - ball_number: 1-based (1-6 balls per over)
 *   - First ball in innings: over=0, ball=1
 *   - Ball sequences must be contiguous; gaps and out-of-order submissions are rejected
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

  // Normalize extras: ensure it's either a valid string or null (never undefined)
  const normalizedExtras = extras ?? null;

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

    // ✅ Strict ball number validation (cricket rules: 1-6)
    // This is 1-based: 1 = first ball of over, 6 = last ball of over
    if (!Number.isInteger(ball_number) || ball_number < 1 || ball_number > 6) {
      return res.status(400).json({ error: "Ball number must be an integer between 1 and 6" });
    }

    // ✅ Strict over number validation (0-based)
    // over_number=0: first over; over_number=1: second over, etc.
    // Contract requirement: API enforces 0-based overs; frontend must send 0 for first over
    if (!Number.isInteger(over_number) || over_number < 0) {
      return res.status(400).json({ error: "Over number must be a non-negative integer (0-based: 0 for first over)" });
    }

    // ✅ Strict runs validation
    // The 'runs' field represents TOTAL runs for this delivery, including:
    //   - Legal balls: runs off bat (0-6)
    //   - Wides/No-balls: penalty/extra runs (0+, e.g., wide with 2 runs = 2)
    //   - Byes/Leg-byes: unearned runs (1+)
    if (!Number.isInteger(runs) || runs < 0) {
      return res.status(400).json({ error: "Runs must be a non-negative integer" });
    }

    // ✅ Validate extras if provided
    // Each extra type has specific run constraints:
    // - Legal balls (no extras): 0-6 runs
    // - Wides/No-balls: 0+ runs (typically 1+, but 0 is technically valid)
    // - Byes/Leg-byes: 1+ runs (at least 1 run must accompany these)
    if (normalizedExtras) {
      const validExtras = ['wide', 'no-ball', 'bye', 'leg-bye'];
      if (!validExtras.includes(normalizedExtras)) {
        return res.status(400).json({ 
          error: `Invalid extras type. Allowed: ${validExtras.join(', ')}` 
        });
      }
      
      // Validate runs constraints for each extra type
      if (normalizedExtras === 'wide' || normalizedExtras === 'no-ball') {
        // Wides/no-balls: 0+ runs (no strict upper limit)
        // These are typically 1+ (wide 1 run, no-ball 1 run), but allow 0 for edge cases
        if (runs < 0) {
          return res.status(400).json({ 
            error: `${normalizedExtras} must have non-negative runs` 
          });
        }
      } else if (normalizedExtras === 'bye' || normalizedExtras === 'leg-bye') {
        // Byes/leg-byes: 1+ runs required (these deliveries MUST have runs)
        if (runs < 1) {
          return res.status(400).json({ 
            error: `${normalizedExtras} must have at least 1 run` 
          });
        }
      }
    } else {
      // Legal ball (no extras): 0-6 runs off bat
      if (runs > 6) {
        return res.status(400).json({ 
          error: "Legal deliveries (no extras) can have maximum 6 runs" 
        });
      }
    }

    // ✅ Validate wicket type if provided
    if (wicket_type !== undefined && wicket_type !== null) {
      const validWicketTypes = ['bowled', 'caught', 'lbw', 'run-out', 'stumped', 'hit-wicket'];
      if (!validWicketTypes.includes(wicket_type)) {
        return res.status(400).json({ 
          error: `Invalid wicket type. Allowed: ${validWicketTypes.join(', ')}` 
        });
      }
      
      // If wicket, out_player_id is required
      if (!out_player_id) {
        return res.status(400).json({ error: "out_player_id is required when wicket_type is specified" });
      }
    }

    // Execute all database operations within a transaction
    const result = await withTransaction(async (conn) => {
      // Check innings status
      const [[inningStatus]] = await conn.query(
        `SELECT status, batting_team_id, bowling_team_id FROM match_innings WHERE id = ?`,
        [inning_id]
      );
      
      if (!inningStatus) {
        throw { statusCode: 404, message: "Innings not found" };
      }

      if (inningStatus.status !== 'in_progress') {
        throw { statusCode: 400, message: "Innings is not in progress" };
      }

      // Verify batsman is in batting team
      const [batsmanTeam] = await conn.query(
        `SELECT team_id FROM players WHERE id = ?`,
        [batsman_id]
      );
      
      if (batsmanTeam.length === 0 || batsmanTeam[0].team_id !== inningStatus.batting_team_id) {
        throw { statusCode: 400, message: "Batsman must be from the batting team" };
      }

      // Verify bowler is in bowling team
      const [bowlerTeam] = await conn.query(
        `SELECT team_id FROM players WHERE id = ?`,
        [bowler_id]
      );
      
      if (bowlerTeam.length === 0 || bowlerTeam[0].team_id !== inningStatus.bowling_team_id) {
        throw { statusCode: 400, message: "Bowler must be from the bowling team" };
      }

      // ✅ Verify out_player_id is from batting team if wicket is recorded
      if (out_player_id) {
        const [outPlayerTeam] = await conn.query(
          `SELECT team_id FROM players WHERE id = ?`,
          [out_player_id]
        );
        
        if (outPlayerTeam.length === 0 || outPlayerTeam[0].team_id !== inningStatus.batting_team_id) {
          throw { statusCode: 400, message: "Out player must be from the batting team" };
        }
      }

      // --- New Ball Sequencing Logic ---

      // 1. Calculate sequence for the ball entry with row-level locking
      // Use FOR UPDATE to serialize concurrent scoring for the same innings
      const [[{ next_seq }]] = await conn.query(
        `SELECT COALESCE(MAX(sequence), -1) + 1 AS next_seq
         FROM ball_by_ball
         WHERE inning_id = ? AND over_number = ? AND ball_number = ?
         FOR UPDATE`,
        [inning_id, over_number, ball_number]
      );
      const sequence = next_seq;

      const isLegalBall = normalizedExtras !== 'wide' && normalizedExtras !== 'no-ball';

      // 2. Validate ball sequencing for legal balls
      if (isLegalBall) {
        const [lastLegalBall] = await conn.query(
          `SELECT over_number, ball_number FROM ball_by_ball 
           WHERE inning_id = ? AND (extras IS NULL OR extras NOT IN ('wide', 'no-ball'))
           ORDER BY over_number DESC, ball_number DESC, sequence DESC
           LIMIT 1`,
          [inning_id]
        );

        if (lastLegalBall.length > 0) {
          const lastOver = lastLegalBall[0].over_number;
          const lastBallNum = lastLegalBall[0].ball_number;
          
          const expectedOver = lastBallNum === 6 ? lastOver + 1 : lastOver;
          const expectedBall = lastBallNum === 6 ? 1 : lastBallNum + 1;
          
          if (over_number !== expectedOver || ball_number !== expectedBall) {
            throw { statusCode: 400, message: `Invalid legal ball sequence. Expected over ${expectedOver}, ball ${expectedBall}` };
          }
        } else if (over_number !== 0 || ball_number !== 1) {
          throw { statusCode: 400, message: "First legal ball must be over 0, ball 1" };
        }
      }
      
      // 3. Insert ball record with sequence and handle duplicate conflicts
      try {
        await conn.query(
          `INSERT INTO ball_by_ball 
          (match_id, inning_id, over_number, ball_number, sequence, batsman_id, bowler_id, runs, extras, wicket_type, out_player_id) 
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [
            match_id,
            inning_id,
            over_number,
            ball_number,
            sequence,
            batsman_id,
            bowler_id,
            runs,
            normalizedExtras,
            wicket_type || null,
            out_player_id || null,
          ]
        );
      } catch (err) {
        // Handle duplicate entry errors
        if (err.code === 'ER_DUP_ENTRY') {
          throw { 
            statusCode: 409, 
            message: `Duplicate ball event at over ${over_number}, ball ${ball_number}, sequence ${sequence}` 
          };
        }
        // Re-throw other errors
        throw err;
      }

      // Update innings table
      // 'runs' field is the TOTAL runs for this delivery (includes all types of runs)
      // Wickets are counted separately and are independent of run count
      await conn.query(
        `UPDATE match_innings 
         SET runs = runs + ?, 
             wickets = wickets + IF(?, 1, 0) 
         WHERE id = ?`,
        [runs, wicket_type ? 1 : 0, inning_id]
      );

      // Update overs - only count legal balls (exclude wides/no-balls)
      // Reuse the isLegalBall variable defined earlier
      if (isLegalBall) {
        // Increment legal_balls first for safety and clarity
        await conn.query(
          `UPDATE match_innings SET legal_balls = legal_balls + 1 WHERE id = ?`,
          [inning_id]
        );
        
        // Then, update overs based on the new legal_balls value
        await conn.query(
          `UPDATE match_innings 
           SET overs_decimal = FLOOR(legal_balls/6) + (legal_balls % 6)/10,
               overs = FLOOR(legal_balls / 6)
           WHERE id = ?`,
          [inning_id]
        );
      }

      // ✅ Update batsman stats for every delivery
      // Only count legal balls and no-balls for balls_faced (not wides)
      // Only credit runs off the bat (exclude wides, byes, leg-byes)
      
      // Determine balls faced increment: 1 for legal balls and no-balls, 0 for wides
      const ballsFacedIncrement = (normalizedExtras !== 'wide') ? 1 : 0;
      
      // Determine batsman runs credit:
      // - No extras: full runs
      // - Wide/bye/leg-bye: 0 runs (not credited to batsman)
      // - No-ball: runs - 1 (exclude the penalty run)
      let batsmanRuns = 0;
      if (!normalizedExtras) {
        batsmanRuns = runs;
      } else if (normalizedExtras === 'no-ball') {
        batsmanRuns = Math.max(0, runs - 1);
      } else if (normalizedExtras === 'wide' || normalizedExtras === 'bye' || normalizedExtras === 'leg-bye') {
        batsmanRuns = 0;
      }
      
      await conn.query(
        `INSERT INTO player_match_stats (match_id, player_id, runs, balls_faced) 
         VALUES (?, ?, ?, ?) 
         ON DUPLICATE KEY UPDATE runs = runs + VALUES(runs), balls_faced = balls_faced + VALUES(balls_faced)`,
        [match_id, batsman_id, batsmanRuns, ballsFacedIncrement]
      );

      // ✅ Update bowler stats for every delivery
      // Only count legal balls for balls_bowled (exclude wides and no-balls)
      // Note: runs_conceded includes both runs off bat and extra runs (wides/no-balls)
      
      // Determine balls bowled increment: 1 for legal balls only, 0 for wides/no-balls
      const ballsBowledIncrement = isLegalBall ? 1 : 0;
      
      await conn.query(
        `INSERT INTO player_match_stats (match_id, player_id, balls_bowled, runs_conceded, wickets) 
         VALUES (?, ?, ?, ?, ?) 
         ON DUPLICATE KEY UPDATE 
           balls_bowled = balls_bowled + VALUES(balls_bowled), 
           runs_conceded = runs_conceded + VALUES(runs_conceded), 
           wickets = wickets + VALUES(wickets)`,
        [match_id, bowler_id, ballsBowledIncrement, runs, wicket_type ? 1 : 0]
      );

      // 🔄 Auto-end innings if all out or overs finished
      const [[matchCheck]] = await conn.query(`SELECT overs FROM matches WHERE id = ?`, [match_id]);
      const maxLegalBalls = matchCheck.overs * 6;

      // Get updated innings data for Socket.IO emission and to check for auto-end
      let [[updatedInning]] = await conn.query(
        `SELECT * FROM match_innings WHERE id = ?`,
        [inning_id]
      );

      // Determine if innings should be auto-ended using the latest, post-update data
      const shouldAutoEnd = updatedInning.wickets >= 10 || updatedInning.legal_balls >= maxLegalBalls;
      if (shouldAutoEnd) {
        await conn.query(`UPDATE match_innings SET status = 'completed' WHERE id = ?`, [inning_id]);
        // Re-fetch to get the final 'completed' status for the socket emission
        [[updatedInning]] = await conn.query(`SELECT * FROM match_innings WHERE id = ?`, [inning_id]);
      }

      // Return data for Socket.IO emission (after commit)
      return { 
        updatedInning, 
        shouldAutoEnd,
        match_id,
        inning_id,
        over_number,
        ball_number,
        sequence,
        batsman_id,
        bowler_id,
        runs,
        extras: normalizedExtras,
        wicket_type,
        out_player_id
      };
    });

    // After successful transaction commit, emit Socket.IO events
    const socketIo = getIo();
    if (socketIo) {
      const [balls] = await db.query(
        `SELECT b.*, 
                bats.player_name AS batsman_name,
                bowl.player_name AS bowler_name,
                outp.player_name AS out_player_name
         FROM ball_by_ball b
         LEFT JOIN players bats ON b.batsman_id = bats.id
         LEFT JOIN players bowl ON b.bowler_id = bowl.id
         LEFT JOIN players outp ON b.out_player_id = outp.id
         WHERE b.match_id = ? 
         ORDER BY b.over_number ASC, b.ball_number ASC, b.sequence ASC`,
        [match_id]
      );

      socketIo.of('/live-score').to(`match:${match_id}`).emit('scoreUpdate', {
        matchId: match_id,
        inningId: inning_id,
        inning: result.updatedInning,
        ballAdded: {
          over_number,
          ball_number,
          sequence: result.sequence,
          batsman_id,
          bowler_id,
          runs,
          extras: normalizedExtras,
          wicket_type,
          out_player_id,
        },
        allBalls: balls,
        autoEnded: result.shouldAutoEnd,
      });

      if (result.shouldAutoEnd) {
        const [[finalInning]] = await db.query(
          `SELECT * FROM match_innings WHERE id = ?`,
          [inning_id]
        );
        socketIo.of('/live-score').to(`match:${match_id}`).emit('inningsEnded', {
          matchId: match_id,
          inningId: inning_id,
          inning: finalInning,
        });
      }
    }

    if (result.shouldAutoEnd) {
      return res.json({ message: "Ball recorded. Innings ended automatically", autoEnded: true });
    }

    res.json({ message: "Ball recorded successfully" });
  } catch (err) {
    // Handle custom error objects from transaction
    if (err.statusCode && err.message) {
      return res.status(err.statusCode).json({ error: err.message });
    }
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

    // Emit innings end event via WebSocket
    const socketIo = getIo();
    if (socketIo) {
      const matchId = inning.match_id;
      const [[updatedInning]] = await db.query(
        `SELECT * FROM match_innings WHERE id = ?`,
        [inning_id]
      );
      
      socketIo.of('/live-score').to(`match:${matchId}`).emit('inningsEnded', {
        matchId,
        inningId: inning_id,
        inning: updatedInning,
      });
    }

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
      `SELECT * FROM ball_by_ball WHERE match_id = ? ORDER BY over_number ASC, ball_number ASC, sequence ASC`,
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
