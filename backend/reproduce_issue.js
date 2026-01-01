const { db } = require("./config/db");
const liveScoreController = require("./controllers/liveScoreController");

// Mock Express Objects
const mockRes = () => {
    const res = {};
    res.status = (code) => {
        res.statusCode = code;
        return res;
    };
    res.json = (data) => {
        res.body = data;
        return res;
    };
    return res;
};

const runReproduction = async () => {
    try {
        console.log("Running reproduction script...");

        // 1. Setup: Create a dummy match
        // 1. Setup: Create a dummy match
        const connection = await db.getConnection();

        // Get a valid user ID
        const [users] = await connection.query("SELECT id FROM users LIMIT 1");
        if (users.length === 0) throw new Error("No users found in database");
        const userId = users[0].id;
        console.log("Using User ID:", userId);

        // const userId = 999; // Mock user ID - REMOVED
        let matchId = null;
        let team1Id = null;
        let team2Id = null;

        try {
            // Create Teams
            const [t1] = await connection.query("INSERT INTO teams (team_name, owner_id) VALUES ('Test Team A', ?)", [userId]);
            const [t2] = await connection.query("INSERT INTO teams (team_name, owner_id) VALUES ('Test Team B', ?)", [userId]);
            team1Id = t1.insertId;
            team2Id = t2.insertId;

            // Create Match
            const [m] = await connection.query(
                "INSERT INTO matches (team1_id, team2_id, creator_id, overs, status, match_datetime, venue) VALUES (?, ?, ?, 10, 'live', NOW(), 'Test Venue')",
                [team1Id, team2Id, userId]
            );
            matchId = m.insertId;
            console.log(`Created match ${matchId} with teams ${team1Id} vs ${team2Id}`);

            // 2. Start Inning 1
            const req1 = {
                body: {
                    match_id: matchId,
                    batting_team_id: team1Id,
                    bowling_team_id: team2Id,
                    inning_number: 1
                },
                user: { id: userId }
            };
            const res1 = mockRes();
            await liveScoreController.startInnings(req1, res1);
            console.log("Start Inning 1 Response:", res1.statusCode, res1.body);

            if (res1.statusCode && res1.statusCode !== 200) throw new Error("Failed to start inning 1");
            const inning1Id = res1.body.inning_id;

            // 3. End Inning 1
            const reqEndDate = {
                body: { inning_id: inning1Id },
                user: { id: userId }
            };
            const resEnd = mockRes();
            await liveScoreController.endInnings(reqEndDate, resEnd);
            console.log("End Inning 1 Response:", resEnd.statusCode, resEnd.body);

            // 4. Start Inning 2
            const req2 = {
                body: {
                    match_id: matchId,
                    batting_team_id: team2Id,
                    bowling_team_id: team1Id,
                    inning_number: 2
                },
                user: { id: userId }
            };
            const res2 = mockRes();
            await liveScoreController.startInnings(req2, res2);
            console.log("Start Inning 2 Response:", res2.statusCode, res2.body);

            if (res2.statusCode && res2.statusCode !== 200) throw new Error("Failed to start inning 2");

            // 5. Get Live Score
            const reqGet = {
                params: { match_id: matchId }
            };
            const resGet = mockRes();
            await liveScoreController.getLiveScore(reqGet, resGet);

            console.log("Get Live Score Response Status:", resGet.statusCode);

            const data = resGet.body;
            const innings = data.innings;
            console.log("Innings returned:", JSON.stringify(innings, null, 2));

            const activeInning = innings.find(i => i.status === 'in_progress');
            console.log("Active Inning:", activeInning);

            if (activeInning && activeInning.inning_number === 2) {
                console.log("✅ SUCCESS: Inning 2 is active and in_progress.");
            } else {
                console.log("❌ FAILURE: Inning 2 is NOT active or NOT in_progress.");
            }

        } finally {
            // Cleanup
            if (matchId) await connection.query("DELETE FROM matches WHERE id = ?", [matchId]);
            if (team1Id) await connection.query("DELETE FROM teams WHERE id IN (?, ?)", [team1Id, team2Id]);
            await connection.query("DELETE FROM match_innings WHERE match_id = ?", [matchId]); // Just in case
            connection.release();
        }

    } catch (err) {
        console.error("Error running reproduction:", err);
    } finally {
        process.exit(0);
    }
};

runReproduction();
