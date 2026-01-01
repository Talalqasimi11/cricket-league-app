const { db } = require("./config/db");

async function debugQueries() {
    const matchIdNum = 9;
    console.log(`Debugging queries for match_id: ${matchIdNum}`);

    try {
        console.log("Running Query 1: match_innings...");
        const [inningsResult] = await db.query(
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
        );
        console.log("Query 1 success. Innings count:", inningsResult.length);

        console.log("Running Query 2: ball_by_ball...");
        const [ballsResult] = await db.query(
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
        );
        console.log("Query 2 success. Balls count:", ballsResult.length);

        console.log("Running Query 3: player_match_stats...");
        const [playersResult] = await db.query(
            `SELECT pms.player_id, p.player_name, p.player_role,
              pms.runs, pms.balls_faced, pms.wickets, pms.balls_bowled, pms.runs_conceded
       FROM player_match_stats pms
       JOIN players p ON pms.player_id = p.id
       WHERE pms.match_id = ?`,
            [matchIdNum]
        );
        console.log("Query 3 success. Players count:", playersResult.length);

        const innings = inningsResult;
        const currentInning = innings.find(inn => inn.status === 'in_progress');

        if (currentInning) {
            console.log("Running In-progress queries for Inning ID:", currentInning.id);
            console.log("Query 4: current batsmen...");
            const [batsmenRes] = await db.query(
                `SELECT DISTINCT b.batsman_id, p.player_name, pms.runs, pms.balls_faced
         FROM ball_by_ball b
         JOIN players p ON b.batsman_id = p.id
         LEFT JOIN player_match_stats pms ON b.batsman_id = pms.player_id AND pms.match_id = ?
         WHERE b.inning_id = ? AND b.batsman_id IS NOT NULL
         ORDER BY b.id DESC LIMIT 2`,
                [matchIdNum, currentInning.id]
            );
            console.log("Query 4 success. Batsmen count:", batsmenRes.length);

            console.log("Query 5: current bowler...");
            const [bowlerRes] = await db.query(
                `SELECT b.bowler_id, p.player_name, pms.balls_bowled, pms.runs_conceded, pms.wickets
         FROM ball_by_ball b
         JOIN players p ON b.bowler_id = p.id
         LEFT JOIN player_match_stats pms ON b.bowler_id = pms.player_id AND pms.match_id = ?
         WHERE b.inning_id = ? AND b.bowler_id IS NOT NULL
         ORDER BY b.id DESC LIMIT 1`,
                [matchIdNum, currentInning.id]
            );
            console.log("Query 5 success. Bowler found:", bowlerRes.length > 0);

            console.log("Query 6: recent balls...");
            const [recentBallsRes] = await db.query(
                `SELECT b.runs, b.extras, b.wicket_type
         FROM ball_by_ball b
         WHERE b.inning_id = ?
         ORDER BY b.id DESC LIMIT 12`,
                [currentInning.id]
            );
            console.log("Query 6 success. Recent balls:", recentBallsRes.length);
        } else {
            console.log("No in-progress inning found.");
        }

        console.log("Debug check: testing RRR logic...");
        if (innings.length > 1) {
            const firstInning = innings.find(i => i.inning_number === 1);
            const chasingInning = innings.find(i => i.inning_number === 2);
            if (firstInning && chasingInning) {
                console.log("First inning runs:", firstInning.runs);
                console.log("Chasing inning overs:", chasingInning.overs);
                console.log("Chasing inning overs_decimal:", chasingInning.overs_decimal);
                const totalOvers = 20;
                const ballsRem = (totalOvers * 6) - (chasingInning.overs * 6 + Math.round((chasingInning.overs_decimal % 1) * 10));
                console.log("Balls remaining:", ballsRem);
            }
        }

        console.log("ALL QUERIES PASSED!");
    } catch (err) {
        console.error("❌ QUERY FAILED!");
        console.error(err);
    } finally {
        process.exit();
    }
}

debugQueries();
