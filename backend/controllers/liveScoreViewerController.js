const { db } = require("../config/db");

/**
 * 📌 Get live score of a match (for viewers)
 */
const getLiveScoreViewer = async (req, res) => {
  const { match_id } = req.params;

  try {
    // Innings info with enhanced data
    const [innings] = await db.query(
      `SELECT mi.id, mi.inning_number, mi.batting_team_id, mi.bowling_team_id, 
              mi.runs, mi.wickets, mi.overs, mi.overs_decimal, mi.status,
              bt.team_name AS batting_team_name,
              blt.team_name AS bowling_team_name,
              -- Calculate current run rate using overs_decimal for accuracy
              CASE 
                WHEN mi.overs_decimal > 0 THEN ROUND(mi.runs / mi.overs_decimal, 2)
                ELSE 0 
              END AS current_run_rate,
              -- Calculate required run rate (if second innings) using overs_decimal
              CASE 
                WHEN mi.inning_number = 2 THEN 
                  ROUND((SELECT mi2.runs FROM match_innings mi2 
                         WHERE mi2.match_id = ? AND mi2.inning_number = 1) / mi.overs_decimal, 2)
                ELSE NULL 
              END AS required_run_rate
       FROM match_innings mi
       LEFT JOIN teams bt ON mi.batting_team_id = bt.id
       LEFT JOIN teams blt ON mi.bowling_team_id = blt.id
       WHERE mi.match_id = ?
       ORDER BY mi.inning_number ASC`,
      [match_id, match_id]
    );

    // Get current innings data for additional aggregates
    const currentInning = innings.find(inn => inn.status === 'in_progress');
    let currentBatsmen = [];
    let currentBowler = null;
    let last12Balls = [];

    if (currentInning) {
      // Get current batsmen (last 2 batsmen who faced balls)
      const [batsmen] = await db.query(
        `SELECT DISTINCT b.batsman_id, p.player_name, pms.runs, pms.balls_faced
         FROM ball_by_ball b
         JOIN players p ON b.batsman_id = p.id
         LEFT JOIN player_match_stats pms ON b.batsman_id = pms.player_id AND pms.match_id = ?
         WHERE b.inning_id = ? AND b.batsman_id IS NOT NULL
         ORDER BY b.id DESC
         LIMIT 2`,
        [match_id, currentInning.id]
      );
      currentBatsmen = batsmen;

      // Get current bowler (last bowler who bowled)
      const [bowler] = await db.query(
        `SELECT b.bowler_id, p.player_name, pms.balls_bowled, pms.runs_conceded, pms.wickets
         FROM ball_by_ball b
         JOIN players p ON b.bowler_id = p.id
         LEFT JOIN player_match_stats pms ON b.bowler_id = pms.player_id AND pms.match_id = ?
         WHERE b.inning_id = ? AND b.bowler_id IS NOT NULL
         ORDER BY b.id DESC
         LIMIT 1`,
        [match_id, currentInning.id]
      );
      currentBowler = bowler[0] || null;

      // Get last 12 balls
      const [lastBalls] = await db.query(
        `SELECT b.over_number, b.ball_number, b.runs, b.extras, b.wicket_type,
                bats.player_name AS batsman_name,
                bowl.player_name AS bowler_name
         FROM ball_by_ball b
         LEFT JOIN players bats ON b.batsman_id = bats.id
         LEFT JOIN players bowl ON b.bowler_id = bowl.id
         WHERE b.inning_id = ?
         ORDER BY b.id DESC
         LIMIT 12`,
        [currentInning.id]
      );
      last12Balls = lastBalls.reverse(); // Show in chronological order
    }

    // Ball-by-ball info
    const [balls] = await db.query(
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
      [match_id]
    );

    // Player stats
    const [players] = await db.query(
      `SELECT pms.player_id, p.player_name, p.player_role,
              pms.runs, pms.balls_faced, pms.wickets, pms.balls_bowled, pms.runs_conceded
       FROM player_match_stats pms
       JOIN players p ON pms.player_id = p.id
       WHERE pms.match_id = ?`,
      [match_id]
    );

    // Calculate partnership runs and balls for current batsmen
    let partnershipRuns = 0;
    let partnershipBalls = 0;
    if (currentBatsmen.length >= 2) {
      const [partnership] = await db.query(
        `SELECT COUNT(*) as balls, SUM(runs) as runs
         FROM ball_by_ball 
         WHERE inning_id = ? AND batsman_id IN (?, ?)
         ORDER BY id DESC
         LIMIT 50`, // Last 50 balls for partnership calculation
        [currentInning.id, currentBatsmen[0].batsman_id, currentBatsmen[1].batsman_id]
      );
      partnershipRuns = partnership[0]?.runs || 0;
      partnershipBalls = partnership[0]?.balls || 0;
    }

    res.json({ 
      innings, 
      balls, 
      players,
      currentBatsmen,
      currentBowler,
      last12Balls,
      partnership: {
        runs: partnershipRuns,
        balls: partnershipBalls
      }
    });
  } catch (err) {
    console.error("❌ Error in getLiveScoreViewer:", err);
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = { getLiveScoreViewer };
