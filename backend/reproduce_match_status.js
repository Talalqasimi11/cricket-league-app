
const { db } = require('./config/db');
const { startInnings, addBall } = require('./controllers/liveScoreController');
const { createMatch } = require('./controllers/matchController');
const { finalizeMatchInternal } = require('./controllers/matchFinalizationController');

// Mock request/response objects
const mockReq = (body, user) => ({
    body,
    user: user || { id: 1 }, // Admin/Creator
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
        console.log("=== Starting Reproduction Test ===");

        // 1. Create a dummy match
        // We'll insert directly to avoid complex auth/setup for now or use a mock controller if possible.
        // Actually, let's insert into DB manually to be fast.
        const [team1] = await db.query("SELECT id FROM teams LIMIT 1");
        const [team2] = await db.query("SELECT id FROM teams LIMIT 1 OFFSET 1");

        if (!team1.length || !team2.length) {
            console.log("Not enough teams to run test");
            return;
        }
        const t1 = team1[0].id;
        const t2 = team2[0].id;

        // Create match
        const matchRes = await db.query(`
      INSERT INTO matches (team1_id, team2_id, tournament_id, status, overs, creator_id, match_datetime, venue)
      VALUES (?, ?, NULL, 'scheduled', 1, 1, NOW(), 'Test Venue')
    `, [t1, t2]);
        const matchId = matchRes[0].insertId;
        console.log(`Created Match ${matchId}`);

        // Update to live
        await db.query("UPDATE matches SET status = 'live' WHERE id = ?", [matchId]);

        // 2. Start Innings 1
        const reqStart = mockReq({
            match_id: matchId,
            batting_team_id: t1,
            bowling_team_id: t2,
            inning_number: 1
        });
        const resStart = mockRes();
        await startInnings(reqStart, resStart);
        const inn1Id = resStart.data.inning_id;
        console.log(`Started Inning 1: ${inn1Id}`);

        // 3. End Inning 1 (Auto-end logic or manual)
        // We'll simulate 1 over (6 balls) giving 10 runs
        for (let i = 1; i <= 6; i++) {
            const reqBall = mockReq({
                match_id: matchId,
                inning_id: inn1Id,
                over_number: 0,
                ball_number: i,
                runs: 1, // 6 runs total
                batsman_id: 1, // Mock
                bowler_id: 2
            });
            const resBall = mockRes();
            await addBall(reqBall, resBall);
            if (i === 6) console.log("Ball 6 added, inning should be complete logic trigger");
        }

        // Check status
        const [inn1] = await db.query("SELECT status, runs FROM match_innings WHERE id = ?", [inn1Id]);
        console.log(`Inning 1 Status: ${inn1[0].status}, Runs: ${inn1[0].runs}`);

        // Manually complete if not
        if (inn1[0].status !== 'completed') {
            await db.query("UPDATE match_innings SET status = 'completed' WHERE id = ?", [inn1Id]);
            await db.query("UPDATE matches SET target_score = ? WHERE id = ?", [inn1[0].runs + 1, matchId]);
        }

        // 4. Start Inning 2
        const reqStart2 = mockReq({
            match_id: matchId,
            batting_team_id: t2,
            bowling_team_id: t1,
            inning_number: 2
        });
        const resStart2 = mockRes();
        await startInnings(reqStart2, resStart2);
        const inn2Id = resStart2.data.inning_id;
        console.log(`Started Inning 2: ${inn2Id}`);

        // 5. Chase target (Need 7 runs)
        // Ball 1: 6 runs
        const reqBall2_1 = mockReq({
            match_id: matchId,
            inning_id: inn2Id,
            over_number: 0,
            ball_number: 1,
            runs: 6,
            batsman_id: 2,
            bowler_id: 1
        });
        const resBall2_1 = mockRes();
        await addBall(reqBall2_1, resBall2_1);

        // Ball 2: 4 runs (Win)
        const reqBall2_2 = mockReq({
            match_id: matchId,
            inning_id: inn2Id,
            over_number: 0,
            ball_number: 2,
            runs: 4,
            batsman_id: 2,
            bowler_id: 1
        });
        const resBall2_2 = mockRes();
        await addBall(reqBall2_2, resBall2_2);

        console.log("Winning ball added. Response:", JSON.stringify(resBall2_2.data));

        // 6. Verify Match Status
        const [finalMatch] = await db.query("SELECT status, winner_team_id FROM matches WHERE id = ?", [matchId]);
        console.log(`Final Match Status: ${finalMatch[0].status}`);
        console.log(`Winner ID: ${finalMatch[0].winner_team_id}`);

        if (finalMatch[0].status === 'completed' && finalMatch[0].winner_team_id === t2) {
            console.log("✅ SUCCESS: Match marked as completed with correct winner.");
        } else {
            console.log("❌ FAILURE: Match status/winner incorrect.");
        }

    } catch (e) {
        console.error("Test Error:", e);
    } finally {
        process.exit();
    }
}

runTest();
