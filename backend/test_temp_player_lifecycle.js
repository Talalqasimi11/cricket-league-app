const BASE_URL = 'http://127.0.0.1:5000/api';
const fs = require('fs');
const path = require('path');

const LOG_FILE = path.join(__dirname, 'test_lifecycle_log.txt');

function log(message) {
    console.log(message);
    fs.appendFileSync(LOG_FILE, message + '\n');
}

async function runTest() {
    try {
        fs.writeFileSync(LOG_FILE, '');
        log('--- Starting Test: Temporary Player Lifecycle ---');

        // Helper for JSON requests
        const post = async (url, data, token) => {
            const headers = { 'Content-Type': 'application/json' };
            if (token) headers['Authorization'] = `Bearer ${token}`;
            try {
                const res = await fetch(url, { method: 'POST', headers, body: JSON.stringify(data) });
                const text = await res.text();
                let json; try { json = JSON.parse(text); } catch (e) { json = null; }
                return { status: res.status, data: json, text };
            } catch (err) { return { status: 0, text: err.message }; }
        };

        const get = async (url, token) => {
            const headers = { 'Content-Type': 'application/json' };
            if (token) headers['Authorization'] = `Bearer ${token}`;
            try {
                const res = await fetch(url, { method: 'GET', headers });
                const text = await res.text();
                let json; try { json = JSON.parse(text); } catch (e) { json = null; }
                return { status: res.status, data: json, text };
            } catch (err) { return { status: 0, text: err.message }; }
        };

        // 1. Register User
        const user = { username: `user_lifecycle_${Date.now()}`, password: 'password123', phone_number: `333${Date.now().toString().slice(-7)}` };
        const reg = await post(`${BASE_URL}/auth/register`, user);
        const token = reg.data.token;
        log('User Registered.');

        // 2. Create Team
        const teamRes = await post(`${BASE_URL}/teams/my-team`, { team_name: `Lifecycle Team ${Date.now()}`, team_location: 'Loc' }, token);
        if (!teamRes.data || !teamRes.data.team) {
            throw new Error(`Team creation failed: ${teamRes.status} ${teamRes.text}`);
        }
        const teamId = teamRes.data.team.id;
        log(`Team Created (ID: ${teamId}).`);

        // 3. Add Temporary Player
        const tempPlayerRes = await post(`${BASE_URL}/players`, {
            player_name: 'Temp Player', player_role: 'Batsman', team_id: teamId, is_temporary: true
        }, token);
        const tempPlayerId = tempPlayerRes.data.id;
        log(`Temp Player Added (ID: ${tempPlayerId}).`);

        // 4. Verify Player is Visible
        const playersRes1 = await get(`${BASE_URL}/players/my-players`, token);
        log('Players Response: ' + JSON.stringify(playersRes1.data));
        if (!Array.isArray(playersRes1.data)) throw new Error('Expected array of players');
        const found1 = playersRes1.data.find(p => p.id === tempPlayerId);
        if (found1) log('✅ Temp player visible before match.');
        else log('❌ Temp player NOT visible before match!');

        // 5. Create Match
        const user2 = { username: `user_opp_${Date.now()}`, password: 'password123', phone_number: `444${Date.now().toString().slice(-7)}` };
        const reg2 = await post(`${BASE_URL}/auth/register`, user2);
        const token2 = reg2.data.token;
        const team2ResReal = await post(`${BASE_URL}/teams/my-team`, { team_name: `Opponent Team ${Date.now()}`, team_location: 'Loc' }, token2);
        const team2Id = team2ResReal.data.team.id;

        const matchRes = await post(`${BASE_URL}/matches`, {
            team1_id: teamId, team2_id: team2Id, match_datetime: new Date().toISOString(), venue: 'Test Venue', overs: 5
        }, token);
        log('Match Response: ' + JSON.stringify(matchRes.data));
        const matchId = matchRes.data.matchId || matchRes.data.id;
        log(`Match Created (ID: ${matchId}).`);

        // 6. Finalize Match
        const finalizeRes = await post(`${BASE_URL}/matches/finalize`, { match_id: matchId }, token);
        if (finalizeRes.status === 200) log('✅ Match Finalized.');
        else log(`❌ Match Finalization Failed: ${finalizeRes.text}`);

        // 7. Verify Player is Archived (Not Visible)
        const playersRes2 = await get(`${BASE_URL}/players/my-players`, token);
        const found2 = playersRes2.data.find(p => p.id === tempPlayerId);
        if (!found2) log('✅ Temp player GONE after match (Archived).');
        else log('❌ Temp player STILL VISIBLE after match!');

        log('--- Test Completed ---');

    } catch (error) {
        log('Test Script Error: ' + error.message);
    }
}

runTest();
