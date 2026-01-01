const { db } = require("../config/db");
const { logDatabaseError } = require("../utils/safeLogger"); // Assuming this exists

/**
 * 📌 Get live score of a match (Optimized for Viewers)
 */
const getLiveScoreViewer = async (req, res) => {
  const { match_id } = req.params;

  if (!match_id) return res.status(400).json({ error: "Match ID is required" });
  const matchIdNum = parseInt(match_id, 10);
  if (isNaN(matchIdNum) || matchIdNum <= 0) return res.status(400).json({ error: "Invalid match ID" });

  try {
    // 1. Fetch Match Details
    const [matchDetails] = await db.query(
      "SELECT id, team1_id, team2_id, overs, status, target_score FROM matches WHERE id = ?",
      [matchIdNum]
    );
    if (!matchDetails.length) return res.status(404).json({ error: "Match not found" });

    // 2. Fetch Innings & Ball-by-Ball Data (Concurrent)
    const [inningsResult, ballsResult, playersResult] = await Promise.all([
      db.query(
        `SELECT mi.id, mi.inning_number, mi.batting_team_id, mi.bowling_team_id, 
                mi.runs, mi.wickets, mi.overs, mi.overs_decimal, mi.legal_balls, mi.status,
                bt.team_name AS batting_team_name,
                blt.team_name AS bowling_team_name
         FROM match_innings mi
         LEFT JOIN teams bt ON mi.batting_team_id = bt.id
         LEFT JOIN teams blt ON mi.bowling_team_id = blt.id
         WHERE mi.match_id = ?
         ORDER BY mi.inning_number ASC`,
        [matchIdNum]
      ),
      db.query(
        `SELECT b.id, b.inning_id, b.over_number, b.ball_number, b.runs, b.extras, b.wicket_type,
                b.batsman_id, b.bowler_id, b.out_player_id,
                bats.player_name AS batsman_name,
                bowl.player_name AS bowler_name,
                outp.player_name AS out_player_name
         FROM ball_by_ball b
         LEFT JOIN players bats ON b.batsman_id = bats.id
         LEFT JOIN players bowl ON b.bowler_id = bowl.id
         LEFT JOIN players outp ON b.out_player_id = outp.id
         WHERE b.match_id = ?
         ORDER BY b.sequence ASC`,
        [matchIdNum]
      ),
      db.query(
        `SELECT pms.player_id, p.player_name, p.player_role,
                pms.runs, pms.balls_faced, pms.wickets, pms.balls_bowled, pms.runs_conceded
         FROM player_match_stats pms
         JOIN players p ON pms.player_id = p.id
         WHERE pms.match_id = ?`,
        [matchIdNum]
      )
    ]);

    const innings = inningsResult[0];
    const balls = ballsResult[0];
    const players = playersResult[0];

    // 3. Derived Summary Stats (CRR, RRR, Partnership)
    let crr = "0.00";
    let rrr = "0.00";
    let partnership = { runs: 0, balls: 0 };
    let currentBatsmen = [];
    let currentBowler = null;
    let recentBalls = [];

    const activeInning = innings.find(i => i.status === 'in_progress') || innings[innings.length - 1];

    if (activeInning) {
      // Calculate CRR
      if (activeInning.legal_balls > 0) {
        crr = ((activeInning.runs / activeInning.legal_balls) * 6).toFixed(2);
      }

      // Calculate RRR (if 2nd innings and target exists)
      if (activeInning.inning_number === 2 && matchDetails[0].target_score) {
        const target = matchDetails[0].target_score;
        const runsToWin = target - activeInning.runs;
        const totalOvers = matchDetails[0].overs * 6;
        const remainingBalls = Math.max(0, totalOvers - activeInning.legal_balls);
        if (remainingBalls > 0 && runsToWin > 0) { // Only calculate if runs are needed and balls remain
          rrr = ((runsToWin / remainingBalls) * 6).toFixed(2);
        } else if (runsToWin <= 0) { // Target achieved
          rrr = "0.00";
        }
      }

      // Calculate Recent Balls (Last 12)
      recentBalls = balls
        .filter(b => b.inning_id === activeInning.id)
        .slice(-12);

      // Current Batsmen & Bowler
      // Logic: From last few balls or match_innings active player IDs
      // For Viewer, we can fetch active pair from match_innings if we have columns
      const [[inningState]] = await db.query(
        "SELECT current_striker_id, current_non_striker_id, current_bowler_id FROM match_innings WHERE id = ?",
        [activeInning.id]
      );

      if (inningState) {
        const { current_striker_id, current_non_striker_id, current_bowler_id } = inningState;

        // Map to full objects from players matched result
        if (current_striker_id) {
          const striker = players.find(p => p.player_id === current_striker_id);
          if (striker) currentBatsmen.push(striker);
        }
        if (current_non_striker_id) {
          const nonStriker = players.find(p => p.player_id === current_non_striker_id);
          if (nonStriker) currentBatsmen.push(nonStriker);
        }
        if (current_bowler_id) {
          currentBowler = players.find(p => p.player_id === current_bowler_id);
        }

        // Calculate current partnership
        // Iterate backwards through balls of the active inning
        let tempPartnershipRuns = 0;
        let tempPartnershipBalls = 0;
        let lastWicketBallIndex = -1;

        for (let i = balls.length - 1; i >= 0; i--) {
          const ball = balls[i];
          if (ball.inning_id !== activeInning.id) continue; // Only consider balls from the active inning

          if (ball.wicket_type && ball.out_player_id !== null) {
            lastWicketBallIndex = i;
            break; // Found the last wicket, partnership started after this
          }
        }

        // Now iterate from the ball after the last wicket (or start of inning)
        for (let i = balls.length - 1; i > lastWicketBallIndex; i--) {
          const ball = balls[i];
          if (ball.inning_id !== activeInning.id) continue;

          // Only count runs and balls if the current batsmen were involved
          const isCurrentBatsman = (currentBatsmen.some(b => b.player_id === ball.batsman_id) || currentBatsmen.some(b => b.player_id === ball.out_player_id));

          if (isCurrentBatsman) {
            tempPartnershipRuns += ball.runs;
            if (!['wide', 'no-ball'].includes(ball.extras)) {
              tempPartnershipBalls += 1;
            }
          }
        }
        partnership = { runs: tempPartnershipRuns, balls: tempPartnershipBalls };
      }
    }

    // 4. Response
    res.json({
      ...matchDetails[0],
      innings,
      balls,
      players,
      stats: {
        crr,
        rrr,
        partnership
      },
      currentContext: {
        batsmen: currentBatsmen,
        bowler: currentBowler,
        recentBalls
      }
    });

  } catch (err) {
    if (typeof logDatabaseError === 'function') {
      logDatabaseError(req.log, "getLiveScoreViewer", err, { matchId: matchIdNum });
    } else {
      console.error("❌ Error in getLiveScoreViewer:", err);
    }
    res.status(500).json({ error: "Server error retrieving live score" });
  }
};

module.exports = { getLiveScoreViewer };