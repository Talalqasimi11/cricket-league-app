
const { db } = require('./config/db');
const { startInnings, addBall, getLiveScore } = require('./controllers/liveScoreController');

// Mock Request/Response
const mockReq = (body = {}, params = {}, user = { id: 1 }) => ({ body, params, user });
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

async function testPersistence() {
    try {
        console.log("1. Setup: Finding/Creating Match...");
        // Use an existing match or create one. For safety, let's use a hardcoded existing match if possible, or insert one.
        // Inserting a dummy match to be safe.
        const [res] = await db.query(`INSERT INTO matches (tournament_id, team1_id, team2_id, creator_id, status, overs, match_datetime, venue) VALUES (null, 1, 2, 1, 'live', 5, NOW(), 'Test Venue')`);
        const matchId = res.insertId;
        console.log(`   Created test match ID: ${matchId}`);

        // 2. Start Innings
        console.log("2. Starting Innings...");
        const reqStart = mockReq({
            match_id: matchId,
            batting_team_id: 1,
            bowling_team_id: 2,
            inning_number: 1
        });
        const resStart = mockRes();
        await startInnings(reqStart, resStart);

        if (resStart.statusCode && resStart.statusCode !== 200) {
            console.error("Failed to start innings:", resStart.data);
            process.exit(1);
        }
        const inningId = resStart.data.inning_id;
        console.log(`   Innings started. ID: ${inningId}`);

        // 3. Add Ball
        console.log("3. Adding Ball (Runs: 4)...");
        const reqBall = mockReq({
            match_id: matchId,
            inning_id: inningId,
            batsman_id: 1,
            bowler_id: 2,
            runs: 4,
            over_number: 0,
            ball_number: 1
        });
        const resBall = mockRes();
        await addBall(reqBall, resBall);

        console.log("   AddBall Response:", resBall.data ? "OK" : "Error");
        if (resBall.data && resBall.data.error) console.error(resBall.data.error);

        // 4. Verify Immediate Read (context inside addBall should have printed logs)

        // 5. Explicit Read via getLiveScore (Simulate GET request)
        console.log("5. Reading via getLiveScore (String ID)...");
        const reqGet = mockReq({}, { match_id: matchId.toString() });
        const resGet = mockRes();
        await getLiveScore(reqGet, resGet);

        const stats = resGet.data.player_stats;
        console.log(`   Retrieved Stats Count: ${stats ? stats.length : 0}`);

        if (stats && stats.length > 0) {
            console.log("   ✅ SUCCESS: Stats persisted and retrieved.");
            console.log("   Stats:", stats);
        } else {
            console.log("   ❌ FAILURE: Stats missing in GET response.");
        }

        // Cleanup
        // await db.query("DELETE FROM matches WHERE id = ?", [matchId]);

    } catch (e) {
        console.error("TEST FAILED:", e);
    } finally {
        process.exit(0);
    }
}

testPersistence();
