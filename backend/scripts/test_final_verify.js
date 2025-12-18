const mysql = require("mysql2/promise");
const path = require("path");
require("dotenv").config({ path: path.join(__dirname, "../.env") });

// Use native fetch
const API_URL = 'http://localhost:5000/api';

// Redirect checking
const fs = require('fs');
const util = require('util');
const logFile = fs.createWriteStream('verify_fix_log.txt', { flags: 'w' });
const logStdout = process.stdout;
const logStderr = process.stderr;

console.log = function (...args) {
    const msg = util.format(...args);
    logFile.write(msg + '\n');
    logStdout.write(msg + '\n');
};
console.error = function (...args) {
    const msg = util.format(...args);
    logFile.write(msg + '\n');
    logStderr.write(msg + '\n');
};

async function runTest() {
    const conn = await mysql.createConnection({
        host: process.env.DB_HOST,
        user: process.env.DB_USER,
        password: process.env.DB_PASS,
        database: process.env.DB_NAME
    });

    try {
        console.log('1. Login...');
        const loginRes = await fetch(`${API_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ phone_number: '+91234567890', password: 'admin' })
        });
        const loginData = await loginRes.json();
        const token = loginData.token;
        const headers = { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' };

        console.log('2. Create Tournament & Teams...');
        // We will manually insert everything to guarantee valid state and avoid API complexity for now
        // This isolates the "Start Match" logic test
        const tourneyRes = await conn.query(
            "INSERT INTO tournaments (tournament_name, start_date, end_date, created_by, status, location, overs) VALUES (?, NOW(), NOW(), ?, 'upcoming', 'Test Ground', 10)",
            [`Test T ${Date.now()}`, loginData.user.id]
        );
        const tourneyId = tourneyRes[0].insertId;
        console.log('   Tourney Created:', tourneyId);

        // Create Teams
        const [ta] = await conn.query("INSERT INTO teams (team_name, owner_id) VALUES (?, ?)", [`A ${Date.now()}`, loginData.user.id]);
        const teamAId = ta.insertId;
        const [tb] = await conn.query("INSERT INTO teams (team_name, owner_id) VALUES (?, ?)", [`B ${Date.now()}`, loginData.user.id]);
        const teamBId = tb.insertId;
        console.log('   Teams Created:', teamAId, teamBId);

        // Approve them IN TOURNAMENT
        await conn.query(
            "INSERT INTO tournament_teams (tournament_id, team_id, temp_team_name) VALUES (?, ?, ?)",
            [tourneyId, teamAId, 'A']
        );
        const [tt1] = await conn.query("SELECT id FROM tournament_teams WHERE tournament_id = ? AND team_id = ?", [tourneyId, teamAId]);

        await conn.query(
            "INSERT INTO tournament_teams (tournament_id, team_id, temp_team_name) VALUES (?, ?, ?)",
            [tourneyId, teamBId, 'B']
        );
        const [tt2] = await conn.query("SELECT id FROM tournament_teams WHERE tournament_id = ? AND team_id = ?", [tourneyId, teamBId]);
        console.log('   Tournament Teams Created:', tt1[0].id, tt2[0].id);

        // Create Match manually
        console.log('3. Schedule Match...');
        // tournament_id, team1_id, team2_id, team1_tt_id, team2_tt_id, round, match_date, status
        const [mRes] = await conn.query(
            `INSERT INTO tournament_matches (tournament_id, team1_id, team2_id, team1_tt_id, team2_tt_id, round, match_date, status) 
             VALUES (?, ?, ?, ?, ?, 'round_1', NOW(), 'upcoming')`,
            [tourneyId, teamAId, teamBId, tt1[0].id, tt2[0].id]
        );
        const matchId = mRes.insertId;
        console.log('   Match ID:', matchId);

        // 5. START MATCH via API
        console.log('4. Calling Start Match API...');
        const startRes = await fetch(`${API_URL}/tournament-matches/start/${matchId}`, {
            method: 'PUT',
            headers
        });

        console.log('   Status:', startRes.status);
        const startData = await startRes.json();
        console.log('   Response:', startData);

        if (startRes.status === 200) {
            // 6. Verify DB Status
            const [rows] = await conn.query("SELECT * FROM tournament_matches WHERE id = ?", [matchId]);
            console.log('   TM Status:', rows[0].status); // Should be live

            if (rows[0].parent_match_id) {
                const [m2] = await conn.query("SELECT * FROM matches WHERE id = ?", [rows[0].parent_match_id]);
                console.log('   Matches Table Status:', m2[0].status);

                // CHECK FOR INNINGS
                const [inns] = await conn.query("SELECT * FROM match_innings WHERE match_id = ?", [rows[0].parent_match_id]);
                console.log('   Innings Count:', inns.length); // Should be 1
                console.log('   Inning 1 Status:', inns[0]?.status);

                if (inns.length > 0) {
                    console.log('✅ PASS: Innings auto-started!');
                } else {
                    console.error('❌ FAIL: No innings created.');
                }
            } else {
                console.error('❌ FAIL: Parent match not created.');
            }
        } else {
            console.error('❌ FAIL: API returned error');
        }

    } catch (e) {
        console.error('TEST ERROR:', e);
    } finally {
        await conn.end();
    }
}

runTest();
