const path = require('path');
require("dotenv").config({ path: path.resolve(__dirname, '../.env') });
const { createFriendlyMatch } = require("../controllers/tournamentMatchController");
const { startInnings, addBall, undoLastBall } = require("../controllers/liveScoreController");
const { getLiveScoreViewer } = require("../controllers/liveScoreViewerController");
const { db } = require("../config/db");

// Mock Request/Response
const mockReq = (body = {}, params = {}, user = { id: 1 }) => ({
    body,
    params,
    user,
    log: { error: (msg, meta) => console.error(`[LOG ERROR] ${msg}:`, JSON.stringify(meta, null, 2)) }
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

async function runVerification() {
    console.log("🚀 Starting Live Scoring Verification...");

    try {
        // 0. Ensure a valid user exists
        console.log("\n0️⃣ Ensuring valid user...");
        const [users] = await db.query("SELECT id FROM users LIMIT 1");
        let userId;
        if (users.length > 0) {
            userId = users[0].id;
        } else {
            const [newUser] = await db.query("INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)", ["verif_user", "verif@example.com", "hash"]);
            userId = newUser.insertId;
        }
        console.log(`   Using User ID: ${userId}`);

        // 1. Create a Friendly Match
        console.log("\n1️⃣ Creating Friendly Match...");
        const reqCreate = mockReq({
            team1_name: "Verif Team A",
            team2_name: "Verif Team B",
            overs: 5,
            match_date: new Date().toISOString().slice(0, 19).replace('T', ' '),
            venue: "Test"
        }, {}, { id: userId });
        const resCreate = mockRes();
        await createFriendlyMatch(reqCreate, resCreate);

        if (resCreate.statusCode && resCreate.statusCode !== 201) {
            throw new Error(`Failed to create match: ${JSON.stringify(resCreate.data)}`);
        }
        const matchId = resCreate.data.id;
        const team1Id = resCreate.data.team1_id;
        const team2Id = resCreate.data.team2_id;
        console.log(`✅ Match Created: ID ${matchId} (${resCreate.data.team1_name} vs ${resCreate.data.team2_name})`);

        // Get Players (assuming some players exist or we might need to insert them if teams are new)
        // For this test, we might need to insert dummy players if they don't exist for these new teams.
        // Since createFriendlyMatch creates new teams if names provided, they won't have players.
        // Let's insert 2 players for each team manually for testing.
        console.log("   Inserting dummy players...");
        const [p1] = await db.query("INSERT INTO players (team_id, player_name, player_role) VALUES (?, ?, ?)", [team1Id, "Batsman 1", "Batsman"]);
        const [p2] = await db.query("INSERT INTO players (team_id, player_name, player_role) VALUES (?, ?, ?)", [team1Id, "Batsman 2", "Batsman"]);
        const [p3] = await db.query("INSERT INTO players (team_id, player_name, player_role) VALUES (?, ?, ?)", [team2Id, "Bowler 1", "Bowler"]);

        const batsman1Id = p1.insertId;
        const batsman2Id = p2.insertId;
        const bowler1Id = p3.insertId;

        // 2. Start Innings
        console.log("\n2️⃣ Starting Innings...");
        // We need to update match status to 'live' manually because createFriendlyMatch sets it to 'scheduled'
        // and startTournamentMatch logic is complex. For verification, we just force it.
        await db.query("UPDATE matches SET status = 'live' WHERE id = ?", [matchId]);

        const reqStart = mockReq({
            match_id: matchId,
            batting_team_id: team1Id,
            bowling_team_id: team2Id,
            inning_number: 1
        }, {}, { id: userId });
        const resStart = mockRes();
        await startInnings(reqStart, resStart);

        if (resStart.data.error) throw new Error(`Failed to start innings: ${resStart.data.error}`);
        console.log("✅ Innings Started");

        // Get Innings ID
        const [innings] = await db.query("SELECT id FROM match_innings WHERE match_id = ?", [matchId]);
        const inningId = innings[0].id;

        // 3. Add Balls
        console.log("\n3️⃣ Adding Balls...");

        // Ball 1: 1 run
        const reqBall1 = mockReq({
            match_id: matchId,
            inning_id: inningId,
            over_number: 0,
            ball_number: 1,
            batsman_id: batsman1Id,
            bowler_id: bowler1Id,
            runs: 1
        }, {}, { id: userId });
        const resBall1 = mockRes();
        await addBall(reqBall1, resBall1);
        if (resBall1.data.error) throw new Error(`Ball 1 failed: ${resBall1.data.error}`);
        console.log("✅ Ball 1 (1 run) added");

        // Ball 2: 4 runs
        const reqBall2 = mockReq({
            match_id: matchId,
            inning_id: inningId,
            over_number: 0,
            ball_number: 2,
            batsman_id: batsman2Id, // Striker changed
            bowler_id: bowler1Id,
            runs: 4
        }, {}, { id: userId });
        const resBall2 = mockRes();
        await addBall(reqBall2, resBall2);
        if (resBall2.data.error) throw new Error(`Ball 2 failed: ${resBall2.data.error}`);
        console.log("✅ Ball 2 (4 runs) added");

        // 4. Verify Viewer Data
        console.log("\n4️⃣ Verifying Viewer Data...");
        const reqView = mockReq({}, { match_id: matchId.toString() });
        const resView = mockRes();
        await getLiveScoreViewer(reqView, resView);

        const viewData = resView.data;
        if (!viewData.innings || !viewData.balls) throw new Error("Invalid viewer data structure");

        const score = viewData.innings.find(i => i.id === inningId).runs;
        if (score !== 5) throw new Error(`Expected score 5, got ${score}`);
        console.log(`✅ Viewer Data Verified: Score ${score}/0`);

        // 5. Undo Last Ball
        console.log("\n5️⃣ Undoing Last Ball...");
        const reqUndo = mockReq({ match_id: matchId, inning_id: inningId }, {}, { id: userId });
        const resUndo = mockRes();
        await undoLastBall(reqUndo, resUndo);

        if (resUndo.data.error) throw new Error(`Undo failed: ${resUndo.data.error}`);
        console.log("✅ Undo Successful");

        // Verify Score after Undo
        await getLiveScoreViewer(reqView, resView);
        const scoreAfterUndo = resView.data.innings.find(i => i.id === inningId).runs;
        if (scoreAfterUndo !== 1) throw new Error(`Expected score 1 after undo, got ${scoreAfterUndo}`);
        console.log(`✅ Score Verified after Undo: ${scoreAfterUndo}/0`);

        console.log("\n🎉 Verification Completed Successfully!");

    } catch (err) {
        console.error("\n❌ FAILED:", err.message);
        if (err.response && err.response.data) {
            console.error("Response:", JSON.stringify(err.response.data));
        }
    } finally {
        await db.end();
        process.exit(0);
    }
}

runVerification();
