const { db } = require("../config/db");
const { logDatabaseError } = require("../utils/safeLogger"); // Assuming this exists

/**
 * 📌 Get live score of a match (Optimized for Viewers)
 */
const getLiveScoreViewer = async (req, res) => {
  const { match_id } = req.params;

  // 1. Validation
  if (!match_id) return res.status(400).json({ error: "Match ID is required" });
  const matchIdNum = parseInt(match_id, 10);
  if (isNaN(matchIdNum) || matchIdNum <= 0) return res.status(400).json({ error: "Invalid match ID" });

  try {
    // 2. Fetch Innings & Ball-by-Ball Data (Concurrent)
    const [inningsResult, ballsResult, playersResult] = await Promise.all([
      db.query(
        `SELECT mi.id, mi.inning_number, mi.batting_team_id, mi.bowling_team_id, 
                mi.runs, mi.wickets, mi.overs, mi.overs_decimal, mi.status,
                bt.team_name AS batting_team_name,
                blt.team_name AS bowling_team_name,
                CASE WHEN mi.overs_decimal > 0 THEN ROUND(mi.runs / mi.overs_decimal, 2) ELSE 0 END AS current_run_rate
         FROM match_innings mi
         LEFT JOIN teams bt ON mi.batting_team_id = bt.id
         LEFT JOIN teams blt ON mi.bowling_team_id = blt.id
         WHERE mi.match_id = ?
         ORDER BY mi.inning_number ASC`,
        [matchIdNum]
      ),
      db.query(
        `SELECT b.id, b.over_number, b.ball_number, b.runs, b.extras, b.wicket_type,
                bats.player_name AS batsman_name,
                bowl.player_name AS bowler_name,
                outp.player_name AS out_player_name
         FROM ball_by_ball b
         LEFT JOIN players bats ON b.batsman_id = bats.id
         LEFT JOIN players bowl ON b.bowler_id = bowl.id
         LEFT JOIN players outp ON b.out_player_id = outp.id
         WHERE b.match_id = ?
         ORDER BY b.id ASC`,
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

    // 3. Calculate Contextual Data (Current State)
    const currentInning = innings.find(inn => inn.status === 'in_progress');
    let currentBatsmen = [];
    let currentBowler = null;
    let last12Balls = [];
    let partnership = { runs: 0, balls: 0 };

    if (currentInning) {
      // Fetch Current Context concurrently
      const [batsmenRes, bowlerRes, recentBallsRes] = await Promise.all([
        db.query(
          `SELECT DISTINCT b.batsman_id, p.player_name, pms.runs, pms.balls_faced
           FROM ball_by_ball b
           JOIN players p ON b.batsman_id = p.id
           LEFT JOIN player_match_stats pms ON b.batsman_id = pms.player_id AND pms.match_id = ?
           WHERE b.inning_id = ? AND b.batsman_id IS NOT NULL
           ORDER BY b.id DESC LIMIT 2`,
          [matchIdNum, currentInning.id]
        ),
        db.query(
          `SELECT b.bowler_id, p.player_name, pms.balls_bowled, pms.runs_conceded, pms.wickets
           FROM ball_by_ball b
           JOIN players p ON b.bowler_id = p.id
           LEFT JOIN player_match_stats pms ON b.bowler_id = pms.player_id AND pms.match_id = ?
           WHERE b.inning_id = ? AND b.bowler_id IS NOT NULL
           ORDER BY b.id DESC LIMIT 1`,
          [matchIdNum, currentInning.id]
        ),
        db.query(
          `SELECT b.runs, b.extras, b.wicket_type
           FROM ball_by_ball b
           WHERE b.inning_id = ?
           ORDER BY b.id DESC LIMIT 12`,
          [currentInning.id]
        )
      ]);

      currentBatsmen = batsmenRes[0] || [];
      currentBowler = bowlerRes[0].length > 0 ? bowlerRes[0][0] : null;
      last12Balls = (recentBallsRes[0] || []).reverse();

      // Calculate Partnership (Run accumulation for current pair)
      if (currentBatsmen.length >= 2) {
        const [partnershipRes] = await db.query(
          `SELECT COUNT(*) as balls, SUM(runs) as runs
           FROM ball_by_ball 
           WHERE inning_id = ? AND batsman_id IN (?, ?)
           -- Note: Basic partnership logic; ideally track partnerships table for accuracy
           ORDER BY id DESC LIMIT 50`, 
          [currentInning.id, currentBatsmen[0].batsman_id, currentBatsmen[1].batsman_id]
        );
        partnership = {
          runs: partnershipRes[0]?.runs || 0,
          balls: partnershipRes[0]?.balls || 0
        };
      }
    }

    // 4. Calculate Required Run Rate (if applicable)
    if (innings.length > 1) {
      const firstInning = innings.find(i => i.inning_number === 1);
      const chasingInning = innings.find(i => i.inning_number === 2);
      
      if (firstInning && chasingInning) {
        const target = firstInning.runs + 1;
        const runsNeeded = Math.max(0, target - chasingInning.runs);
        
        // Assuming T20 (20 overs) or ODI (50 overs) - defaulting to T20 logic if not specified
        // You might want to fetch max_overs from matches table if variable
        const totalOvers = 20; 
        const ballsRem = (totalOvers * 6) - (chasingInning.overs * 6 + Math.round((chasingInning.overs_decimal % 1) * 10));
        
        // Attach derived RRR to the chasing inning object
        chasingInning.required_run_rate = ballsRem > 0 
          ? ((runsNeeded / ballsRem) * 6).toFixed(2) 
          : 0;
        chasingInning.target = target;
        chasingInning.runs_needed = runsNeeded;
        chasingInning.balls_remaining = ballsRem;
      }
    }

    // 5. Response
    res.json({ 
      innings, 
      balls, 
      players,
      currentContext: {
        batsmen: currentBatsmen,
        bowler: currentBowler,
        recentBalls: last12Balls,
        partnership
      }
    });

  } catch (err) {
    // Use safe logger if available, else console
    if (typeof logDatabaseError === 'function') {
      logDatabaseError(req.log, "getLiveScoreViewer", err, { matchId: matchIdNum });
    } else {
      console.error("❌ Error in getLiveScoreViewer:", err);
    }
    res.status(500).json({ error: "Server error retrieving live score" });
  }
};

module.exports = { getLiveScoreViewer };