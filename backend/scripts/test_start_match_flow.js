const mysql = require("mysql2/promise");
const path = require("path");
require("dotenv").config({ path: path.join(__dirname, "../.env") });

// Use native fetch
// process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
const API_URL = 'http://localhost:5000/api';

async function runTest() {
    const conn = await mysql.createConnection({
        host: process.env.DB_HOST,
        user: process.env.DB_USER,
        password: process.env.DB_PASS,
        database: process.env.DB_NAME
    });

    try {
        // 1. Create User & Login
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
        // Ensure unique name
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

        // 3. Register Teams
        console.log('3. Register Teams...');
        // We'll just create dummy teams via tournament team registration helper if available, 
        // OR manually insert into teams and tournament_teams if the API is complex.
        // Let's use the DB directly for setup speed and reliability of environment

        // Create Team A
        const [r1] = await conn.query("INSERT INTO teams (team_name, owner_id) VALUES (?, ?)", [`Team A ${Date.now()}`, loginData.user.id]);
        const teamAId = r1.insertId;
        const [tt1] = await conn.query("INSERT INTO tournament_teams (tournament_id, team_id, status) VALUES (?, ?, 'approved')", [tourneyId, teamAId]);
        const ttAId = tt1.insertId;

        // Create Team B
        const [r2] = await conn.query("INSERT INTO teams (team_name, owner_id) VALUES (?, ?)", [`Team B ${Date.now()}`, loginData.user.id]);
        const teamBId = r2.insertId;
        const [tt2] = await conn.query("INSERT INTO tournament_teams (tournament_id, team_id, status) VALUES (?, ?, 'approved')", [tourneyId, teamBId]);
        const ttBId = tt2.insertId;

        console.log(`   Teams created: ${teamAId}, ${teamBId}`);

        // 4. Create Match (Manual)
        console.log('4. Schedule Match...');
        // We'll use DB insert for speed/precision to ensure 'upcoming'
        const [mRes] = await conn.query(
            `INSERT INTO tournament_matches (tournament_id, team1_id, team1_tt_id, team2_id, team2_tt_id, round, match_date, status) 
             VALUES (?, ?, ?, ?, ?, 'round_1', NOW(), 'upcoming')`,
            [tourneyId, teamAId, ttAId, teamBId, ttBId]
        );
        const matchId = mRes.insertId;
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

            if (rows[0].status !== 'live') {
                console.error('❌ FAIL: Match status is NOT live in DB!');
            } else {
                console.log('✅ SUCCESS: Match status is live.');
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
