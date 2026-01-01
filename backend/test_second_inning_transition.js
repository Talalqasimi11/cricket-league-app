
const { db } = require("./config/db");
const { startInnings, addBall, endInnings, getLiveScore } = require("./controllers/liveScoreController");

// Mock user for auth
const mockReq = (body, params) => ({
    body,
    params,
    user: { id: 1 }, // Assuming admin or creator
    log: { error: console.error }
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

async function runHelper(name, fn, req) {
    const res = mockRes();
    console.log(`--- Running ${name} ---`);
    await fn(req, res);
    if (res.statusCode && res.statusCode >= 400) {
        console.error(`Error in ${name}:`, res.data);
        throw new Error(`Failed ${name}`);
    }
    return res.data;
}

async function runTest() {
    try {
        console.log("Starting Test...");

        // 1. Create Tournament
        console.log("Creating Tournament...");
        const [tourn] = await db.query("INSERT INTO tournaments (tournament_name, created_by, start_date, end_date, location) VALUES (?, ?, NOW(), NOW(), ?)", [`TestTourn_${Date.now()}`, 1, 'Test Location']);
        const tournamentId = tourn.insertId;

        // 2. Create Teams
        console.log("Creating Teams...");
        const [team1] = await db.query("INSERT INTO teams (team_name, owner_id) VALUES (?, ?)", [`TestTeamA_${Date.now()}`, 1]);
        const team1Id = team1.insertId;
        const [team2] = await db.query("INSERT INTO teams (team_name, owner_id) VALUES (?, ?)", [`TestTeamB_${Date.now()}`, 1]);
        const team2Id = team2.insertId;

        // Add Players
        const [p1] = await db.query("INSERT INTO players (player_name, team_id, player_role) VALUES (?, ?, ?)", [`P1_T1`, team1Id, 'Batsman']);
        const [p2] = await db.query("INSERT INTO players (player_name, team_id, player_role) VALUES (?, ?, ?)", [`P1_T2`, team2Id, 'Bowler']);

        // 3. Create Match
        console.log("Creating Match...");
        const [match] = await db.query(
            "INSERT INTO matches (team1_id, team2_id, creator_id, overs, status, tournament_id, match_datetime, venue) VALUES (?, ?, ?, ?, ?, ?, NOW(), ?)",
            [team1Id, team2Id, 1, 5, 'scheduled', tournamentId, 'Test Venue']
        );
        const matchId = match.insertId;

        // 4. Start Inning 1
        console.log("Starting Inning 1...");
        const start1Vis = await runHelper("startInnings", startInnings, mockReq({
            match_id: matchId,
            batting_team_id: team1Id,
            bowling_team_id: team2Id,
            inning_number: 1
        }));
        const inning1Id = start1Vis.inning_id;

        // 5. Add Ball (Score runs)
        console.log("Adding runs...");
        await runHelper("addBall", addBall, mockReq({
            match_id: matchId,
            inning_id: inning1Id,
            over_number: 0,
            ball_number: 1,
            runs: 6,
            batsman_id: p1.insertId,
            bowler_id: p2.insertId
        }));
        await runHelper("addBall", addBall, mockReq({
            match_id: matchId,
            inning_id: inning1Id,
            over_number: 0,
            ball_number: 2,
            runs: 4,
            batsman_id: p1.insertId,
            bowler_id: p2.insertId
        }));

        // 6. End Inning 1
        console.log("Ending Inning 1...");
        await runHelper("endInnings", endInnings, mockReq({ inning_id: inning1Id }));

        // Check Target Score
        const [[matchData]] = await db.query("SELECT target_score FROM matches WHERE id = ?", [matchId]);
        console.log("Target Score in DB:", matchData.target_score);
        if (matchData.target_score !== 11) throw new Error("Target score incorrect expected 11");

        // 7. Start Inning 2
        console.log("Starting Inning 2...");
        const start2Vis = await runHelper("startInnings", startInnings, mockReq({
            match_id: matchId,
            batting_team_id: team2Id,
            bowling_team_id: team1Id,
            inning_number: 2
        }));
        const inning2Id = start2Vis.inning_id;

        // 8. Get Live Score
        console.log("Getting Live Score Context...");
        const liveScore = await runHelper("getLiveScore", getLiveScore, mockReq({}, { match_id: matchId }));

        console.log("Live Score Stats:", liveScore.stats);
        if (liveScore.target_score !== 11) throw new Error("LiveScore target incorrect");

        // RRR check
        if (liveScore.stats.rrr == "0.00") throw new Error("RRR is 0.00 but expected value");

        console.log("TEST PASSED");
        process.exit(0);

    } catch (err) {
        console.error("TEST FAILED:", err);
        process.exit(1);
    }
}

runTest();
