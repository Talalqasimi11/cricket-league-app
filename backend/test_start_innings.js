const { db } = require("./config/db");
const { startInnings } = require("./controllers/liveScoreController");

// Mock Request and Response
const mockReq = (body, userId) => ({
    body,
    user: { id: userId },
    log: console
});

const mockRes = () => {
    const res = {};
    res.status = (code) => {
        res.statusCode = code;
        return res;
    };
    res.json = (data) => {
        console.log(`Response [${res.statusCode || 200}]:`, data);
        return res;
    };
    return res;
};

async function runTest() {
    try {
        const userId = 4;

        // 1. Find or Create Tournament
        let [tournaments] = await db.query("SELECT id FROM tournaments WHERE created_by = ? LIMIT 1", [userId]);
        let tournamentId;
        if (tournaments.length > 0) {
            tournamentId = tournaments[0].id;
        } else {
            const [res] = await db.query("INSERT INTO tournaments (tournament_name, created_by, start_date, end_date) VALUES (?, ?, NOW(), NOW())", ["Test Tourney", userId]);
            tournamentId = res.insertId;
        }

        // 2. Create Teams
        const [t1] = await db.query("INSERT INTO teams (team_name, owner_id) VALUES (?, ?)", ["Test Team A", userId]);
        const [t2] = await db.query("INSERT INTO teams (team_name, owner_id) VALUES (?, ?)", ["Test Team B", userId]);
        const t1Id = t1.insertId;
        const t2Id = t2.insertId;

        // 3. Create Match (Status: LIVE)
        const [m] = await db.query(
            "INSERT INTO matches (tournament_id, team1_id, team2_id, overs, status, match_datetime) VALUES (?, ?, ?, ?, 'live', NOW())",
            [tournamentId, t1Id, t2Id, 10]
        );
        const matchId = m.insertId;

        // 4. Call startInnings
        await startInnings(
            mockReq({
                match_id: matchId,
                batting_team_id: t1Id,
                bowling_team_id: t2Id,
                inning_number: 1
            }, userId),
            mockRes()
        );

        // 5. Create Match (Status: UPCOMING) - Should fail
        const [m2] = await db.query(
            "INSERT INTO matches (tournament_id, team1_id, team2_id, overs, status, match_datetime) VALUES (?, ?, ?, ?, 'upcoming', NOW())",
            [tournamentId, t1Id, t2Id, 10]
        );
        const matchId2 = m2.insertId;

        await startInnings(
            mockReq({
                match_id: matchId2,
                batting_team_id: t1Id,
                bowling_team_id: t2Id,
                inning_number: 1
            }, userId),
            mockRes()
        );

    } catch (err) {
        const fs = require('fs');
        if (err.sqlMessage) {
            fs.writeFileSync('error.txt', "SQL_ERR: " + err.sqlMessage);
        } else {
            fs.writeFileSync('error.txt', "ERR: " + err.message);
        }
        process.exit(1);
    } finally {
        process.exit(0);
    }
}

runTest();
