const mysql = require("mysql2/promise");
const path = require("path");
require("dotenv").config({ path: path.join(__dirname, "../.env") });

// Use native fetch
const API_URL = 'http://localhost:5000/api';

async function runTest() {
    const conn = await mysql.createConnection({
        host: process.env.DB_HOST,
        user: process.env.DB_USER,
        password: process.env.DB_PASS,
        database: process.env.DB_NAME
    });

    try {
        // 1. Login
        console.log('1. Login...');
        const loginRes = await fetch(`${API_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ phone_number: '+91234567890', password: 'admin' })
        });
        const loginData = await loginRes.json();
        const token = loginData.token;
        const headers = { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' };

        // 2. Create Tournament
        console.log('2. Create Tournament...');
        const uniqueName = `Test Tourney ${Date.now()}`;
        const tRes = await fetch(`${API_URL}/tournaments/create`, {
            method: 'POST',
            headers,
            body: JSON.stringify({
                tournament_name: uniqueName,
                start_date: new Date().toISOString().split('T')[0],
                end_date: new Date(Date.now() + 86400000).toISOString().split('T')[0],
                location: 'Test Ground',
                overs: 10
            })
        });
        const tData = await tRes.json();
        const tourneyId = tData.tournamentId;
        console.log('   Tournament ID:', tourneyId);

        // 3. Register Teams manually
        const t1Name = `Team A ${Date.now()}`;
        const t2Name = `Team B ${Date.now()}`;

        await conn.query("DELETE FROM tournament_teams WHERE tournament_id = ?", [tourneyId]);

        // Create Team A
        const [r1] = await conn.query("INSERT INTO teams (team_name, owner_id) VALUES (?, ?)", [t1Name, loginData.user.id]);
        const teamAId = r1.insertId;
        // NO STATUS COLUMN
        const [tt1] = await conn.query("INSERT INTO tournament_teams (tournament_id, team_id, temp_team_name) VALUES (?, ?, ?)", [tourneyId, teamAId, t1Name]);
        const ttAId = tt1.insertId;

        // Create Team B
        const [r2] = await conn.query("INSERT INTO teams (team_name, owner_id) VALUES (?, ?)", [t2Name, loginData.user.id]);
        const teamBId = r2.insertId;
        // NO STATUS COLUMN
        const [tt2] = await conn.query("INSERT INTO tournament_teams (tournament_id, team_id, temp_team_name) VALUES (?, ?, ?)", [tourneyId, teamBId, t2Name]);
        const ttBId = tt2.insertId;

        // 4. Create Match (Manual API)
        console.log('4. Schedule Match (API)...');
        const mRes = await fetch(`${API_URL}/tournament-matches/manual`, {
            method: 'POST',
            headers,
            body: JSON.stringify({
                tournament_id: tourneyId,
                team1_name: t1Name,
                team2_name: t2Name,
                match_date: new Date().toISOString(),
                round: 'round_1'
            })
        });
        const mData = await mRes.json();
        if (!mRes.ok) {
            console.error('Failed to create match:', mData);
            return;
        }
        const matchId = mData.match.id;
        console.log('   Match ID:', matchId);


        // 5. START MATCH via API
        console.log('5. Calling Start Match API...');
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
            console.log('   DB Status:', rows[0].status);
            console.log('   Parent Match ID:', rows[0].parent_match_id);

            if (rows[0].parent_match_id) {
                const [m2] = await conn.query("SELECT * FROM matches WHERE id = ?", [rows[0].parent_match_id]);
                console.log('   Matches Table Status:', m2[0].status);

                // CHECK FOR INNINGS
                const [inns] = await conn.query("SELECT * FROM match_innings WHERE match_id = ?", [rows[0].parent_match_id]);
                console.log('   Innings Count:', inns.length);
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
