const { db } = require("../config/db");
const { withTransaction } = require("../utils/transactionWrapper");
const { finalizeMatchInternal } = require("./matchFinalizationController");
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
    const [matches] = await db.query(
      `SELECT m.team1_id, m.team2_id, m.tournament_id, m.creator_id, tr.created_by as tournament_creator 
       FROM matches m 
       LEFT JOIN tournaments tr ON m.tournament_id = tr.id 
       WHERE m.id = ?`,
      [matchId]
    );

    if (matches.length === 0) return false;
    const match = matches[0];

    // Check if user is the match creator or tournament creator
    if (match.creator_id === userId || match.tournament_creator === userId) {
      return true;
    }

    // Check if user owns either of the teams
    const [teams] = await db.query(
      `SELECT id FROM teams WHERE id IN (?, ?) AND owner_id = ?`,
      [match.team1_id, match.team2_id, userId]
    );

    return teams.length > 0;
  } catch (err) {
    console.error("Error checking match auth:", err);
    return false;
  }
};

const canScoreForInnings = async (userId, inningId) => {
  try {
    const [innings] = await db.query(
      `SELECT mi.batting_team_id, mi.bowling_team_id, mi.match_id 
       FROM match_innings mi 
       WHERE mi.id = ?`,
      [inningId]
    );

    if (innings.length === 0) return false;
    const inningData = innings[0];

    // Check match authorization (includes creator_id check)
    return await canScoreForMatch(userId, inningData.match_id);
  } catch (err) {
    console.error("Error checking innings auth:", err);
    return false;
  }
};

// ==========================================
// CONTROLLER METHODS
// ==========================================

const getMatchLiveContext = async (matchIdInput) => {
  const matchId = parseInt(matchIdInput);
  console.log(`[MatchContext] Fetching for matchId: ${matchId} (original: ${matchIdInput})`);
  const [matchDetails] = await db.query(
    "SELECT id, team1_id, team2_id, overs, status, target_score, team1_lineup, team2_lineup, winner_team_id FROM matches WHERE id = ?",
    [matchId]
  );
  if (!matchDetails.length) return null;

  const [innings] = await db.query(
    "SELECT * FROM match_innings WHERE match_id = ? ORDER BY inning_number ASC",
    [matchId]
  );

  const [balls] = await db.query(
    `SELECT b.*, bat.player_name as batsman_name, bowl.player_name as bowler_name 
     FROM ball_by_ball b
     LEFT JOIN players bat ON b.batsman_id = bat.id
     LEFT JOIN players bowl ON b.bowler_id = bowl.id
     WHERE b.match_id = ? ORDER BY b.sequence ASC`,
    [matchId]
  );

  const [match_stats] = await db.query(
    `SELECT ps.*, p.player_name 
     FROM player_match_stats ps 
     LEFT JOIN players p ON ps.player_id = p.id 
     WHERE ps.match_id = ?`,
    [matchId]
  );

  console.log(`[Stats Debug] getMatchLiveContext(${matchId}): Found ${match_stats.length} stats rows.`);
  if (match_stats.length > 0) {
    console.log(`[Stats Debug] Sample stat: `, JSON.stringify(match_stats[0]));
  } else {
    console.log(`[Stats Debug] WARNING: No stats found for match ${matchId}`);
  }

  const getTeamPlayers = async (teamId, lineupStr) => {
    if (lineupStr) {
      try {
        const ids = JSON.parse(lineupStr);
        if (Array.isArray(ids) && ids.length > 0) {
          const [rows] = await db.query(
            "SELECT * FROM players WHERE id IN (?) ORDER BY player_name ASC",
            [ids]
          );
          return rows;
        }
      } catch (e) {
        console.error("Lineup parse error:", e);
      }
    }
    return (await db.query("SELECT * FROM players WHERE team_id = ? ORDER BY player_name ASC", [teamId]))[0];
  };

  const team1_players = await getTeamPlayers(matchDetails[0].team1_id, matchDetails[0].team1_lineup);
  const team2_players = await getTeamPlayers(matchDetails[0].team2_id, matchDetails[0].team2_id !== null ? matchDetails[0].team2_lineup : null);

  const activeInning = innings.find(i => i.status === 'in_progress') || innings[innings.length - 1];

  let crr = 0;
  let rrr = 0;
  let partnership = { runs: 0, balls: 0 };
  let currentBatsmen = [];
  let currentBowler = null;
  let recentBalls = [];

  if (activeInning) {
    if (activeInning.legal_balls > 0) {
      crr = (activeInning.runs / activeInning.legal_balls) * 6;
    }

    if (activeInning.inning_number === 2 && matchDetails[0].target_score) {
      const target = matchDetails[0].target_score;
      const runsToWin = target - activeInning.runs;
      const totalBalls = matchDetails[0].overs * 6;
      const remainingBalls = Math.max(0, totalBalls - activeInning.legal_balls);
      if (remainingBalls > 0) {
        rrr = (runsToWin / remainingBalls) * 6;
      }
    }

    recentBalls = balls
      .filter(b => b.inning_id === activeInning.id)
      .slice(-12);

    const getPlayerStat = (playerId) => {
      const stat = match_stats.find(p => p.player_id === playerId);

      // [Debug Log]
      if (playerId && !stat) {
        console.log(`[Stats Debug]Missing stat for player ${playerId} in match ${matchId}. Available stats for: ${match_stats.map(s => s.player_id).join(',')} `);
      }
      if (stat && stat.runs === 0 && stat.balls_faced > 0) {
        console.log(`[Stats Debug] Suspicious 0 runs for player ${playerId} in match ${matchId}.Stat: `, stat);
      }

      return stat || {
        player_id: playerId, runs: 0, balls_faced: 0, fours: 0, sixes: 0,
        balls_bowled: 0, runs_conceded: 0, wickets: 0, is_out: 0
      };
    };

    if (activeInning.current_striker_id) {
      const striker = getPlayerStat(activeInning.current_striker_id);
      const name = balls.find(b => b.batsman_id === activeInning.current_striker_id)?.batsman_name ||
        team1_players?.find(p => p.id === activeInning.current_striker_id)?.player_name ||
        team2_players?.find(p => p.id === activeInning.current_striker_id)?.player_name;
      currentBatsmen.push({ ...striker, player_name: name });
    }
    if (activeInning.current_non_striker_id) {
      const nonStriker = getPlayerStat(activeInning.current_non_striker_id);
      const name = balls.find(b => b.batsman_id === activeInning.current_non_striker_id)?.batsman_name ||
        team1_players?.find(p => p.id === activeInning.current_non_striker_id)?.player_name ||
        team2_players?.find(p => p.id === activeInning.current_non_striker_id)?.player_name;
      currentBatsmen.push({ ...nonStriker, player_name: name });
    }
    if (activeInning.current_bowler_id) {
      const bowler = getPlayerStat(activeInning.current_bowler_id);
      const name = balls.find(b => b.bowler_id === activeInning.current_bowler_id)?.bowler_name ||
        team1_players?.find(p => p.id === activeInning.current_bowler_id)?.player_name ||
        team2_players?.find(p => p.id === activeInning.current_bowler_id)?.player_name;
      currentBowler = { ...bowler, player_name: name };
    }

    for (let i = balls.length - 1; i >= 0; i--) {
      const b = balls[i];
      if (b.inning_id !== activeInning.id) break;
      if (b.wicket_type && b.out_player_id) break;
      partnership.runs += b.runs;
      if (!['wide', 'no-ball'].includes(b.extras)) partnership.balls += 1;
    }
  }

  const winnerId = matchDetails[0].winner_team_id;
  let winnerName = null;
  let resultMsg = null;

  if (winnerId) {
    const [[team]] = await db.query("SELECT team_name FROM teams WHERE id = ?", [winnerId]);
    winnerName = team?.team_name;
  }

  if (matchDetails[0].status === 'completed' && activeInning) {
    if (winnerId) {
      if (winnerId === activeInning.batting_team_id) {
        const wkts = 10 - activeInning.wickets;
        resultMsg = `${winnerName} won by ${wkts} wicket${wkts > 1 ? 's' : ''} `;
      } else {
        const target = matchDetails[0].target_score || (innings[0].runs + 1);
        const margin = target - 1 - activeInning.runs;
        resultMsg = `${winnerName} won by ${margin} run${margin > 1 ? 's' : ''} `;
      }
    } else {
      resultMsg = "Match tied";
    }
  }

  return {
    ...matchDetails[0],
    innings,
    allBalls: balls,
    player_stats: match_stats,
    team1_players,
    team2_players,
    winner_name: winnerName,
    result_message: resultMsg,
    stats: {
      crr: crr.toFixed(2),
      rrr: rrr.toFixed(2),
      partnership
    },
    currentContext: {
      batsmen: currentBatsmen,
      bowler: currentBowler,
      recentBalls
    },
    _debug: {
      match_stats_count: match_stats.length,
      balls_count: balls.length,
      active_inning_id: activeInning?.id
    }
  };

  console.log(`[MatchContext] Returning context for ${matchId}. Keys: ${Object.keys(result).join(',')}`);
  return result;
};

// 📌 Start Innings
// 📌 Start Innings
const startInnings = async (req, res) => {
  const { match_id, batting_team_id, bowling_team_id, inning_number, striker_id, non_striker_id, bowler_id } = req.body;
  console.log(`[LiveScore Debug] startInnings called: `, { match_id, inning_number, batting_team_id });

  try {
    const canScore = await canScoreForMatch(req.user.id, match_id);
    if (!canScore) {
      console.log("❌ Unauthorized access for match:", match_id);
      return res.status(403).json({ error: "Unauthorized" });
    }

    const result = await withTransaction(async (conn) => {
      const [match] = await conn.query("SELECT status FROM matches WHERE id = ?", [match_id]);
      console.log("🔍 Match found:", match);

      if (match.length === 0) throw { statusCode: 404, message: "Match not found" };

      // ✅ Auto-start match if not already live
      if (match[0].status !== "live") {
        if (match[0].status === "completed" || match[0].status === "cancelled") {
          throw { statusCode: 400, message: "Match is already completed or cancelled" };
        }

        console.log("⚠️ Match not live. Auto-starting match:", match_id);
        await conn.query("UPDATE matches SET status = 'live' WHERE id = ?", [match_id]);
      }

      // ✅ Set any existing innings for this match to 'completed' before starting a new one
      await conn.query("UPDATE match_innings SET status = 'completed' WHERE match_id = ? AND status = 'in_progress'", [match_id]);

      const [insertResult] = await conn.query(
        `INSERT INTO match_innings
    (match_id, team_id, batting_team_id, bowling_team_id, inning_number, runs, wickets, overs, legal_balls, overs_decimal, status, current_striker_id, current_non_striker_id, current_bowler_id)
  VALUES(?, ?, ?, ?, ?, 0, 0, 0, 0, 0, 'in_progress', ?, ?, ?)`,
        [match_id, batting_team_id, batting_team_id, bowling_team_id, inning_number, striker_id || null, non_striker_id || null, bowler_id || null]
      );
      return insertResult;
    });

    res.json({ message: `Innings ${inning_number} started`, inning_id: result.insertId });
  } catch (err) {
    console.error("❌ Error in startInnings:", err);
    const status = err.statusCode || 500;
    res.status(status).json({ error: err.message || "Server error" });
  }
};

// 📌 Set New Batter (After Wicket)
const setNewBatter = async (req, res) => {
  const { inning_id, new_batter_id, role } = req.body; // role = 'striker' or 'non_striker'
  console.log(`[LiveScore Debug] setNewBatter called: `, { inning_id, new_batter_id, role });

  try {
    if (!await canScoreForInnings(req.user.id, inning_id)) return res.status(403).json({ error: "Unauthorized" });

    let updateField = '';
    if (role === 'striker') updateField = 'current_striker_id';
    else if (role === 'non_striker') updateField = 'current_non_striker_id';
    else if (role === 'bowler') updateField = 'current_bowler_id';
    else return res.status(400).json({ error: "Invalid role" });

    const [[inning]] = await db.query("SELECT * FROM match_innings WHERE id = ?", [inning_id]);
    if (!inning) return res.status(404).json({ error: "Inning not found" });

    // Validation: prevent same player for both batter roles
    if (role === 'striker' && new_batter_id == inning.current_non_striker_id) {
      return res.status(400).json({ error: "Player is already non-striker" });
    }
    if (role === 'non_striker' && new_batter_id == inning.current_striker_id) {
      return res.status(400).json({ error: "Player is already striker" });
    }

    // Validation: prevent consecutive overs for same bowler
    if (role === 'bowler') {
      const [lastBalls] = await db.query(
        "SELECT bowler_id FROM ball_by_ball WHERE inning_id = ? ORDER BY sequence DESC LIMIT 1",
        [inning_id]
      );
      if (lastBalls.length > 0 && lastBalls[0].bowler_id == new_batter_id) {
        if (inning.legal_balls % 6 === 0 && inning.legal_balls > 0) {
          return res.status(400).json({ error: "Bowler cannot bowl consecutive overs" });
        }
      }
    }

    await db.query(`UPDATE match_innings SET ${updateField} = ? WHERE id = ? `, [new_batter_id, inning_id]);

    // Socket Emit
    const [[updatedInning]] = await db.query("SELECT * FROM match_innings WHERE id = ?", [inning_id]);
    const context = await getMatchLiveContext(updatedInning.match_id);
    const socketIo = getIo();
    if (socketIo && context) {
      socketIo.of('/live-score').to(`match:${updatedInning.match_id} `).emit('scoreUpdate', {
        ...context,
        autoEnded: false
      });
    }

    res.json({ message: "New batter set" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Server error" });
  }
};

// 📌 Add Ball (Core Scoring Logic - Enhanced)
const addBall = async (req, res) => {
  const {
    match_id, inning_id, over_number, ball_number,
    runs, extras, wicket_type, out_player_id,
  } = req.body;

  console.log(`[LiveScore Debug] addBall called: `, { match_id, inning_id, runs, extras, wicket_type });

  const normalizedExtras = extras ?? null;

  try {
    if (!await canScoreForInnings(req.user.id, inning_id)) {
      return res.status(403).json({ error: "Unauthorized" });
    }

    if (!match_id || !inning_id || over_number === undefined || runs === undefined) {
      return res.status(400).json({ error: "Missing fields" });
    }
    if (runs < 0) return res.status(400).json({ error: "Runs must be positive" });

    const result = await withTransaction(async (conn) => {
      const [[inningState]] = await conn.query(
        `SELECT status, current_striker_id, current_non_striker_id, current_bowler_id 
         FROM match_innings WHERE id = ? FOR UPDATE`,
        [inning_id]
      );

      if (!inningState || inningState.status !== 'in_progress') {
        throw { statusCode: 400, message: "Innings not in progress" };
      }

      const { current_striker_id, current_non_striker_id, current_bowler_id } = inningState;

      const actualBatsmanId = current_striker_id || req.body.batsman_id;
      const actualBowlerId = current_bowler_id || req.body.bowler_id;

      const [[lastSeq]] = await conn.query(
        `SELECT COALESCE(MAX(sequence), -1) + 1 AS next_seq FROM ball_by_ball WHERE inning_id = ? `,
        [inning_id]
      );
      const sequence = lastSeq.next_seq;

      const [[lastBall]] = await conn.query(
        `SELECT COALESCE(MAX(ball_number), 0) + 1 AS next_ball FROM ball_by_ball WHERE inning_id = ? AND over_number = ? `,
        [inning_id, over_number]
      );
      const calculatedBallNumber = lastBall.next_ball;

      await conn.query(
        `INSERT INTO ball_by_ball
    (match_id, inning_id, over_number, ball_number, sequence, batsman_id, bowler_id, runs, extras, wicket_type, out_player_id)
  VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [match_id, inning_id, over_number, calculatedBallNumber, sequence, actualBatsmanId, actualBowlerId, runs, normalizedExtras, wicket_type || null, out_player_id || null]
      );

      const isWicket = wicket_type ? 1 : 0;
      await conn.query(
        `UPDATE match_innings SET runs = runs + ?, wickets = wickets + ? WHERE id = ? `,
        [runs, isWicket, inning_id]
      );

      if (isWicket) {
        const actualOutPlayerId = out_player_id || actualBatsmanId;
        if (actualOutPlayerId) {
          await conn.query(
            `UPDATE player_match_stats SET is_out = 1 WHERE match_id = ? AND player_id = ? `,
            [match_id, actualOutPlayerId]
          );
        }
      }

      const isLegalBall = !['wide', 'no-ball'].includes(normalizedExtras);
      let isOverComplete = false;

      if (isLegalBall) {
        await conn.query(`UPDATE match_innings SET legal_balls = legal_balls + 1 WHERE id = ? `, [inning_id]);
        const [[newInningState]] = await conn.query(`SELECT legal_balls FROM match_innings WHERE id = ? `, [inning_id]);
        if (newInningState.legal_balls % 6 === 0) {
          isOverComplete = true;
        }

        await conn.query(
          `UPDATE match_innings 
           SET overs_decimal = FLOOR(legal_balls / 6) + (legal_balls % 6) / 10,
    overs = FLOOR(legal_balls / 6) 
           WHERE id = ? `,
          [inning_id]
        );
      }

      let batsmanRuns = 0;
      let ballsFaced = (normalizedExtras !== 'wide') ? 1 : 0;

      if (!normalizedExtras) batsmanRuns = runs;
      else if (normalizedExtras === 'no-ball') batsmanRuns = Math.max(0, runs - 1);

      const isFour = batsmanRuns === 4 ? 1 : 0;
      const isSix = batsmanRuns === 6 ? 1 : 0;

      await conn.query(
        `INSERT INTO player_match_stats(match_id, player_id, runs, balls_faced, fours, sixes)
  VALUES(?, ?, ?, ?, ?, ?) 
         ON DUPLICATE KEY UPDATE
  runs = runs + ?, balls_faced = balls_faced + ?,
    fours = fours + ?, sixes = sixes + ? `,
        [match_id, actualBatsmanId, batsmanRuns, ballsFaced, isFour, isSix,
          batsmanRuns, ballsFaced, isFour, isSix]
      );

      const ballsBowled = isLegalBall ? 1 : 0;
      let bowlerRuns = runs;
      if (normalizedExtras === 'bye' || normalizedExtras === 'leg-bye') bowlerRuns = 0;

      await conn.query(
        `INSERT INTO player_match_stats(match_id, player_id, balls_bowled, runs_conceded, wickets)
  VALUES(?, ?, ?, ?, ?) 
         ON DUPLICATE KEY UPDATE
  balls_bowled = balls_bowled + ?,
    runs_conceded = runs_conceded + ?,
    wickets = wickets + ? `,
        [match_id, actualBowlerId, ballsBowled, bowlerRuns, isWicket,
          ballsBowled, bowlerRuns, isWicket]
      );

      let nextStriker = current_striker_id;
      let nextNonStriker = current_non_striker_id;

      if (runs % 2 !== 0) {
        const temp = nextStriker;
        nextStriker = nextNonStriker;
        nextNonStriker = temp;
      }

      if (isOverComplete) {
        const temp = nextStriker;
        nextStriker = nextNonStriker;
        nextNonStriker = temp;
      }

      if (isWicket) {
        if (out_player_id == nextStriker) nextStriker = null;
        else if (out_player_id == nextNonStriker) nextNonStriker = null;
        else if (!out_player_id) nextStriker = null;
      }

      await conn.query(
        `UPDATE match_innings 
         SET current_striker_id = ?, current_non_striker_id = ?
    WHERE id = ? `,
        [nextStriker, nextNonStriker, inning_id]
      );

      const [[matchData]] = await conn.query("SELECT overs, target_score FROM matches WHERE id = ?", [match_id]);
      const [[updatedInning]] = await conn.query("SELECT * FROM match_innings WHERE id = ?", [inning_id]);

      const maxBalls = matchData.overs * 6;
      let shouldEndMatch = false;
      let shouldEndInning = updatedInning.wickets >= 10 || updatedInning.legal_balls >= maxBalls;

      // Check for target chased in 2nd inning
      if (updatedInning.inning_number === 2 && matchData.target_score) {
        if (updatedInning.runs >= matchData.target_score) {
          shouldEndInning = true;
          shouldEndMatch = true;
        }
      }

      // If inning ends naturally (all out or overs) in 2nd inning, match also ends
      if (shouldEndInning && updatedInning.inning_number === 2) {
        shouldEndMatch = true;
      }

      if (shouldEndInning) {
        await conn.query("UPDATE match_innings SET status = 'completed' WHERE id = ?", [inning_id]);

        // If 1st inning ends, calculate target and set it
        if (updatedInning.inning_number === 1) {
          const target = updatedInning.runs + 1;
          await conn.query("UPDATE matches SET target_score = ? WHERE id = ?", [target, match_id]);
        }
      }

      // [Modified] Do NOT set match status to 'completed' here manually.
      // We will delegate this to finalizeMatchInternal() outside the transaction.
      /*
      if (shouldEndMatch) {
         ... removed ...
         await conn.query("UPDATE matches SET status = 'completed', winner_team_id = ? WHERE id = ?", [winnerId, match_id]);
      }
      */

      return { updatedInning, shouldEnd: shouldEndInning, matchEnded: shouldEndMatch, sequence, matchData };
    });

    // [Added] Automatically finalize match (update stats) if match ended
    if (result.matchEnded) {
      console.log(`[LiveScore] Match ${match_id} ended. Triggering finalization...`);
      try {
        const finalizationResult = await finalizeMatchInternal(match_id);
        console.log(`[LiveScore] Match ${match_id} finalized:`, finalizationResult.message);

        // Optionally emit a 'MatchFinalized' event? 
        // For now, scoreUpdate below with matchEnded=true is enough for frontend to show "Game Over".
      } catch (finErr) {
        console.error(`[LiveScore] Detailed Error finalizing match ${match_id}:`, finErr);
      }
    }

    const context = await getMatchLiveContext(match_id);
    const socketIo = getIo();
    if (socketIo && context) {
      socketIo.of('/live-score').to(`match:${match_id}`).emit('scoreUpdate', {
        ...context,
        autoEnded: result.shouldEnd,
        matchEnded: result.matchEnded
      });
      console.log(`[LiveScore Debug] Emitted scoreUpdate(addBall) for match ${match_id}`);
    }

    res.json({ message: "Ball recorded", autoEnded: result.shouldEnd, matchEnded: result.matchEnded });

  } catch (err) {
    console.error(`[LiveScore Debug]Error in addBall: `, err);
    req.log?.error(err);
    const status = err.statusCode || 500;
    res.status(status).json({ error: err.message || "Server error" });
  }
};

// 📌 Undo Last Ball
const undoLastBall = async (req, res) => {
  const { match_id, inning_id } = req.body;
  console.log(`[LiveScore Debug] undoLastBall called: `, { match_id, inning_id });

  try {
    if (!await canScoreForInnings(req.user.id, inning_id)) return res.status(403).json({ error: "Unauthorized" });

    await withTransaction(async (conn) => {
      const [balls] = await conn.query(
        `SELECT * FROM ball_by_ball WHERE match_id = ? AND inning_id = ? ORDER BY id DESC LIMIT 1 FOR UPDATE`,
        [match_id, inning_id]
      );

      if (balls.length === 0) throw { statusCode: 400, message: "No balls to undo" };
      const ball = balls[0];

      const [[inningBefore]] = await conn.query(
        "SELECT current_striker_id, current_non_striker_id, current_bowler_id, legal_balls FROM match_innings WHERE id = ?",
        [inning_id]
      );

      await conn.query(`DELETE FROM ball_by_ball WHERE id = ? `, [ball.id]);

      const isWicket = ball.wicket_type ? 1 : 0;
      const isLegal = !['wide', 'no-ball'].includes(ball.extras);

      await conn.query(
        `UPDATE match_innings 
         SET runs = runs - ?, wickets = wickets - ?, legal_balls = legal_balls - ?
    WHERE id = ? `,
        [ball.runs, isWicket, isLegal ? 1 : 0, inning_id]
      );

      if (isWicket) {
        const actualOutPlayerId = ball.out_player_id || ball.batsman_id;
        if (actualOutPlayerId) {
          await conn.query(
            `UPDATE player_match_stats SET is_out = 0 WHERE match_id = ? AND player_id = ? `,
            [match_id, actualOutPlayerId]
          );
        }
      }

      let prevStriker = ball.batsman_id;
      let prevNonStriker = (ball.batsman_id === inningBefore.current_striker_id)
        ? inningBefore.current_non_striker_id
        : inningBefore.current_striker_id;

      if (ball.wicket_type) {
        if (ball.out_player_id) {
          if (ball.out_player_id !== ball.batsman_id) {
            prevNonStriker = ball.out_player_id;
          } else {
            prevStriker = ball.out_player_id;
          }
        }
      }

      await conn.query(
        `UPDATE match_innings 
         SET overs = FLOOR(legal_balls / 6),
    overs_decimal = FLOOR(legal_balls / 6) + (legal_balls % 6) / 10,
    current_striker_id = ?,
    current_non_striker_id = ?
      WHERE id = ? `,
        [prevStriker, prevNonStriker, inning_id]
      );

      let batsmanRuns = 0;
      if (!ball.extras) batsmanRuns = ball.runs;
      else if (ball.extras === 'no-ball') batsmanRuns = Math.max(0, ball.runs - 1);

      const isFour = batsmanRuns === 4 ? 1 : 0;
      const isSix = batsmanRuns === 6 ? 1 : 0;

      await conn.query(
        `UPDATE player_match_stats 
         SET runs = runs - ?, balls_faced = balls_faced - ?, fours = fours - ?, sixes = sixes - ?
    WHERE match_id = ? AND player_id = ? `,
        [batsmanRuns, (ball.extras !== 'wide' ? 1 : 0), isFour, isSix, match_id, ball.batsman_id]
      );

      let bowlerRuns = ball.runs;
      if (ball.extras === 'bye' || ball.extras === 'leg-bye') bowlerRuns = 0;

      await conn.query(
        `UPDATE player_match_stats 
         SET runs_conceded = runs_conceded - ?, balls_bowled = balls_bowled - ?, wickets = wickets - ?
    WHERE match_id = ? AND player_id = ? `,
        [bowlerRuns, (isLegal ? 1 : 0), isWicket, match_id, ball.bowler_id]
      );

      // Revert statuses if they were completed
      await conn.query("UPDATE match_innings SET status = 'in_progress' WHERE id = ?", [inning_id]);
      await conn.query("UPDATE matches SET status = 'live', winner_team_id = NULL WHERE id = ?", [match_id]);
    });

    const socketIo = getIo();
    const context = await getMatchLiveContext(match_id);
    if (socketIo && context) {
      socketIo.of('/live-score').to(`match:${match_id} `).emit('scoreUpdate', {
        ...context,
        autoEnded: false
      });
      console.log(`[LiveScore Debug] Emitted scoreUpdate(undo) for match ${match_id}`);
    }

    res.json({ message: "Undo successful" });

  } catch (err) {
    console.error(`[LiveScore Debug]Error in undoLastBall: `, err);
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

      // If 1st inning ended manually, set target_score
      if (inning.inning_number === 1) {
        const target = (inning.runs || 0) + 1;
        await db.query("UPDATE matches SET target_score = ? WHERE id = ?", [target, inning.match_id]);
      }

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

const getLiveScore = async (req, res) => {
  const { match_id } = req.params;
  console.log(`[LiveScore Debug] getLiveScore called for match_id: ${match_id} (Type: ${typeof match_id})`);
  try {
    const context = await getMatchLiveContext(match_id);
    if (!context) return res.status(404).json({ error: "Match not found" });

    console.log(`[LiveScore Debug] Sending response for ${match_id}. Stats count: ${context.player_stats?.length}, Balls count: ${context.allBalls?.length}`);
    res.json(context);
  } catch (err) {
    req.log?.error(err);
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = { startInnings, addBall, endInnings, getLiveScore, undoLastBall, setNewBatter, setIo, canScoreForMatch, canScoreForInnings };