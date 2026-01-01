const { db } = require('./config/db');
const { startInnings, addBall } = require('./controllers/liveScoreController');
const { createTournamentMatches, startTournamentMatch } = require('./controllers/tournamentMatchController');
const { finalizeMatchInternal } = require('./controllers/matchFinalizationController');

// Mock helpers
const mockReq = (body, user) => ({
    body,
    user: user || { id: 1 },
    log: console
});

const mockRes = () => {
    const res = {};
    res.status = (code) => {
        res.statusCode = code;
        return res;
    };
    res.json = (data) => {
        res.data = data;
        return res;
    };
    return res;
};

async function runTest() {
    try {
        console.log("=== Starting Tournament Match Status Test ===");

        // 1. Setup Data: Tournament & Teams
        // Assuming we have teams 1 and 2 and a user 1
        const userId = 1;

        // Create a dummy tournament
        const [tournRes] = await db.query(
            "INSERT INTO tournaments (tournament_name, status, api_token, created_by) VALUES ('Status Test Tourn', 'active', 'test', ?)",
            [userId]
        );
        const tournId = tournRes.insertId;
        console.log(`Created Tournament ${tournId}`);

        // Register dummy teams to tournament (needed for tournament_teams)
        const [t1] = await db.query("SELECT id FROM teams LIMIT 1");
        const [t2] = await db.query("SELECT id FROM teams LIMIT 1 OFFSET 1");

        await db.query("INSERT INTO tournament_teams (tournament_id, team_id) VALUES (?, ?)", [tournId, t1[0].id]);
        const tt1Res = await db.query("SELECT id FROM tournament_teams WHERE tournament_id = ? AND team_id = ?", [tournId, t1[0].id]);
        const tt1Id = tt1Res[0].id;

        await db.query("INSERT INTO tournament_teams (tournament_id, team_id) VALUES (?, ?)", [tournId, t2[0].id]);
        const tt2Res = await db.query("SELECT id FROM tournament_teams WHERE tournament_id = ? AND team_id = ?", [tournId, t2[0].id]);
        const tt2Id = tt2Res[0].id;

        // 2. Create Tournament Match
        // We can manually insert to control IDs or use controller
        const [tmRes] = await db.query(
            "INSERT INTO tournament_matches (tournament_id, team1_id, team1_tt_id, team2_id, team2_tt_id, round, status) VALUES (?, ?, ?, ?, ?, 'round_1', 'upcoming')",
            [tournId, t1[0].id, tt1Id, t2[0].id, tt2Id]
        );
        const tmId = tmRes.insertId;
        console.log(`Created Tournament Match ${tmId}`);

        // 3. Start Match (Converts to Live)
        const reqStart = mockReq({}, { id: userId });
        reqStart.params = { id: tmId };
        const resStart = mockRes();

        await startTournamentMatch(reqStart, resStart);

        if (resStart.statusCode && resStart.statusCode !== 200) {
            console.error("Failed to start match:", resStart.data);
            return;
        }

        const matchId = resStart.data.match_id;
        console.log(`Match Started. Real Match ID: ${matchId}`);

        // 4. Start Innings 1
        const reqInn1 = mockReq({
            match_id: matchId,
            batting_team_id: t1[0].id,
            bowling_team_id: t2[0].id,
            inning_number: 1
        });
        const resInn1 = mockRes();
        await startInnings(reqInn1, resInn1);
        const inn1Id = resInn1.data.inning_id;

        // Score 10 Runs (2 balls of 5 runs - not realistic but fast)
        await addBall(mockReq({ match_id: matchId, inning_id: inn1Id, over_number: 0, ball_number: 1, runs: 6, batsman_id: 1, bowler_id: 2 }), mockRes());
        await addBall(mockReq({ match_id: matchId, inning_id: inn1Id, over_number: 0, ball_number: 2, runs: 4, wicket_type: 'bowled', out_player_id: 1, batsman_id: 1, bowler_id: 2 }), mockRes()); // Wicket to end inning maybe? No, manual end.

        // Manually End Innings 1
        await db.query("UPDATE match_innings SET status = 'completed' WHERE id = ?", [inn1Id]);
        await db.query("UPDATE matches SET target_score = ? WHERE id = ?", [11, matchId]); // Target 11

        // 5. Start Innings 2
        const reqInn2 = mockReq({
            match_id: matchId, // Bug in copy-paste corrected
            batting_team_id: t2[0].id,
            bowling_team_id: t1[0].id,
            inning_number: 2
        });
        const resInn2 = mockRes();
        await startInnings(reqInn2, resInn2);
        const inn2Id = resInn2.data.inning_id;

        // Chase Target: Hit 2 Sixes
        await addBall(mockReq({ match_id: matchId, inning_id: inn2Id, over_number: 0, ball_number: 1, runs: 6, batsman_id: 2, bowler_id: 1 }), mockRes());
        const resWin = mockRes();
        await addBall(mockReq({ match_id: matchId, inning_id: inn2Id, over_number: 0, ball_number: 2, runs: 6, batsman_id: 2, bowler_id: 1 }), resWin);

        console.log("Win Ball Result:", resWin.data);

        // 6. Verify Status
        const [tmCheck] = await db.query("SELECT status, winner_id FROM tournament_matches WHERE id = ?", [tmId]);
        const [mCheck] = await db.query("SELECT status, winner_team_id FROM matches WHERE id = ?", [matchId]);

        console.log("\n--- Verification ---");
        console.log(`Tournament Match Status: ${tmCheck[0].status} (Expected: finished)`);
        console.log(`Real Match Status:       ${mCheck[0].status} (Expected: completed)`);

        if (tmCheck[0].status === 'finished' && mCheck[0].status === 'completed') {
            console.log("✅ TEST PASSED: DB status updated correctly.");
        } else {
            console.log("❌ TEST FAILED: DB status mismatch.");
        }

    } catch (e) {
        console.error("Test Error:", e);
    } finally {
        process.exit();
    }
}

runTest();
