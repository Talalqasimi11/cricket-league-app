const { db } = require("./config/db");

async function reproduceController(match_id) {
    console.log(`Reproducing controller logic for match_id: ${match_id}`);
    const matchIdNum = parseInt(match_id, 10);

    try {
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

        let currentBatsmen = [];
        let currentBowler = null;
        let last12Balls = [];
        let partnership = { runs: 0, balls: 0 };

        const currentInning = innings.find(inn => inn.status === 'in_progress');

        if (currentInning) {
            console.log("Inning in progress found:", currentInning.id);
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

            if (currentBatsmen.length >= 2) {
                console.log("Calculating partnership...");
                const [partnershipRes] = await db.query(
                    `SELECT COUNT(*) as balls, SUM(runs) as runs
           FROM ball_by_ball 
           WHERE inning_id = ? AND batsman_id IN (?, ?)
           ORDER BY id DESC LIMIT 50`,
                    [currentInning.id, currentBatsmen[0].batsman_id, currentBatsmen[1].batsman_id]
                );
                partnership = {
                    runs: partnershipRes[0]?.runs || 0,
                    balls: partnershipRes[0]?.balls || 0
                };
            }
        }

        if (innings.length > 1) {
            console.log("Found > 1 innings, checking RRR...");
            const firstInning = innings.find(i => i.inning_number === 1);
            const chasingInning = innings.find(i => i.inning_number === 2);

            if (firstInning && chasingInning) {
                const target = firstInning.runs + 1;
                const runsNeeded = Math.max(0, target - chasingInning.runs);
                const totalOvers = 20;
                const ballsRem = (totalOvers * 6) - (chasingInning.overs * 6 + Math.round((chasingInning.overs_decimal % 1) * 10));

                chasingInning.required_run_rate = ballsRem > 0
                    ? ((runsNeeded / ballsRem) * 6).toFixed(2)
                    : 0;
                chasingInning.target = target;
                chasingInning.runs_needed = runsNeeded;
                chasingInning.balls_remaining = ballsRem;
            }
        }

        console.log("SUCCESS: Response object constructed.");
        console.log("Partnership:", partnership);
        console.log("Current Bowler:", currentBowler);
        console.log("Current Batsmen Count:", currentBatsmen.length);

    } catch (err) {
        console.error("FAILURE: Error in reproduction script.");
        console.error(err);
    } finally {
        process.exit();
    }
}

reproduceController(9);
reproduceController(1); // Test with another id if 9 is empty
