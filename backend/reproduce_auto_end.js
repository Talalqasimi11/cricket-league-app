
const { addBall, setIo, canScoreForMatch } = require('./controllers/liveScoreController');
const { db } = require('./config/db');

// Mock IO
const mockIo = {
    of: () => ({
        to: () => ({
            emit: (event, data) => {
                console.log(`[MockIO] Emitted ${event}: autoEnded=${data.autoEnded}, matchEnded=${data.matchEnded}`);
                if (data.inning && data.inning.status) {
                    console.log(`[MockIO] Inning Status in emission: ${data.inning.status}`);
                }
            }
        })
    })
};
setIo(mockIo);

// Mock Req/Res
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

async function createTestMatch() {
    // Create a minimal match, teams, innings
    console.log("Creating test match...");
    const [teamResult] = await db.query("INSERT INTO teams (team_name, owner_id) VALUES ('Test Team A', 1), ('Test Team B', 1)");

    // Debug Schema
    const [columns] = await db.query("SHOW COLUMNS FROM matches");
    console.log("Matches Columns:", columns.map(c => `${c.Field} (${c.Type}, Null:${c.Null}, Default:${c.Default})`).join('\n'));

    const team1Id = teamResult.insertId;
    const team2Id = teamResult.insertId + 1;
    const [playerResult] = await db.query(`INSERT INTO players (player_name, team_id, player_role) VALUES ('Player A1', ${team1Id}, 'batsman'), ('Player A2', ${team1Id}, 'batsman'), ('Bowler B1', ${team2Id}, 'bowler')`);
    const firstPlayerId = playerResult.insertId;
    const p1 = firstPlayerId;
    const p2 = firstPlayerId + 1;
    const p3 = firstPlayerId + 2;

    const [matchResult] = await db.query(`INSERT INTO matches (team1_id, team2_id, tournament_id, creator_id, status, overs, match_datetime, venue) VALUES (${team1Id}, ${team2Id}, NULL, 1, 'live', 1, NOW(), 'Test Venue')`);
    const matchId = matchResult.insertId;

    // Create Inning
    const [inningResult] = await db.query(`INSERT INTO match_innings (match_id, team_id, batting_team_id, bowling_team_id, inning_number, runs, wickets, overs, legal_balls, status, current_striker_id, current_non_striker_id, current_bowler_id) 
    VALUES (${matchId}, ${team1Id}, ${team1Id}, ${team2Id}, 1, 0, 0, 0, 0, 'in_progress', ${p1}, ${p2}, ${p3})`);

    return { matchId, inningId: inningResult.insertId, p1, p3 };
}

async function runTest() {
    try {
        const { matchId, inningId, p1, p3 } = await createTestMatch();
        console.log(`Test Match: ${matchId}, Inning: ${inningId}, Batsman: ${p1}, Bowler: ${p3}`);

        // Add 5 balls of 0 runs
        for (let i = 1; i <= 5; i++) {
            const req = {
                user: { id: 1 },
                body: {
                    match_id: matchId,
                    inning_id: inningId,
                    over_number: 0,
                    ball_number: i,
                    runs: 0,
                    batsman_id: p1,
                    bowler_id: p3
                }
            };
            const res = mockRes();
            await addBall(req, res);
            if (res.statusCode && res.statusCode !== 200) {
                console.error(`Ball ${i} failed:`, res.data);
                return;
            }
            console.log(`Ball ${i} added. AutoEnded: ${res.data.autoEnded}`);
        }

        // Add 6th ball (Should end over AND inning)
        console.log("Adding 6th ball (Final ball of match overs)...");
        const req = {
            user: { id: 1 },
            body: {
                match_id: matchId,
                inning_id: inningId,
                over_number: 0,
                ball_number: 6,
                runs: 4, // Hit a 4
                batsman_id: p1,
                bowler_id: p3
            }
        };
        const res = mockRes();
        await addBall(req, res);

        console.log(`6th Ball Result:`, res.data);

        if (res.data.autoEnded) {
            console.log("SUCCESS: autoEnded is true.");
        } else {
            console.error("FAILURE: autoEnded is false.");
        }

        // Check DB status
        const [[inning]] = await db.query("SELECT status FROM match_innings WHERE id = ?", [inningId]);
        console.log(`Inning Status in DB: ${inning.status}`);

    } catch (e) {
        console.error(e);
    } finally {
        process.exit();
    }
}

runTest();
