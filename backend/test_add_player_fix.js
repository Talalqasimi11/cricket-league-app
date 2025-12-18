const fs = require('fs');
const path = require('path');

const BASE_URL = 'http://127.0.0.1:5000/api';
const LOG_FILE = path.join(__dirname, 'test_log.txt');

function log(message) {
    console.log(message);
    fs.appendFileSync(LOG_FILE, message + '\n');
}

async function runTest() {
    try {
        fs.writeFileSync(LOG_FILE, ''); // Clear log file
        log('--- Starting Test: Add Player Fix (using fetch) ---');

        // Helper for JSON requests
        const post = async (url, data, token) => {
            const headers = { 'Content-Type': 'application/json' };
            if (token) headers['Authorization'] = `Bearer ${token}`;

            try {
                const res = await fetch(url, {
                    method: 'POST',
                    headers,
                    body: JSON.stringify(data)
                });

                const text = await res.text();
                let json;
                try {
                    json = JSON.parse(text);
                } catch (e) {
                    json = null;
                }

                return { status: res.status, data: json, text };
            } catch (err) {
                return { status: 0, text: err.message };
            }
        };

        // 1. Register User 1
        const user1 = {
            username: `user1_${Date.now()}`,
            password: 'password123',
            phone_number: `111${Date.now().toString().slice(-7)}`
        };
        log('Registering User 1...');
        const reg1 = await post(`${BASE_URL}/auth/register`, user1);
        if (reg1.status !== 201 && reg1.status !== 200) throw new Error(`User 1 Reg Failed: ${reg1.text}`);
        const token1 = reg1.data.token;
        log('User 1 Registered.');

        // 2. Create Team 1 for User 1
        log('Creating Team 1...');
        const team1Data = {
            team_name: `Team 1 ${Date.now()}`,
            team_location: 'Location 1'
        };
        const team1Res = await post(`${BASE_URL}/teams/my-team`, team1Data, token1);
        if (team1Res.status !== 201 && team1Res.status !== 200) throw new Error(`Team 1 Create Failed: ${team1Res.text}`);
        const team1Id = team1Res.data.team.id;
        log(`Team 1 Created (ID: ${team1Id}).`);

        // 3. Register User 2
        const user2 = {
            username: `user2_${Date.now()}`,
            password: 'password123',
            phone_number: `222${Date.now().toString().slice(-7)}`
        };
        log('Registering User 2...');
        const reg2 = await post(`${BASE_URL}/auth/register`, user2);
        if (reg2.status !== 201 && reg2.status !== 200) throw new Error(`User 2 Reg Failed: ${reg2.text}`);
        const token2 = reg2.data.token;
        log('User 2 Registered.');

        // 4. Create Team 2 for User 2
        log('Creating Team 2...');
        const team2Data = {
            team_name: `Team 2 ${Date.now()}`,
            team_location: 'Location 2'
        };
        const team2Res = await post(`${BASE_URL}/teams/my-team`, team2Data, token2);
        if (team2Res.status !== 201 && team2Res.status !== 200) throw new Error(`Team 2 Create Failed: ${team2Res.text}`);
        const team2Id = team2Res.data.team.id;
        log(`Team 2 Created (ID: ${team2Id}).`);

        // 5. User 1 tries to add player to Team 2 (Should Fail)
        log('User 1 attempting to add player to Team 2 (Should Fail)...');
        const failRes = await post(`${BASE_URL}/players`, {
            player_name: 'Intruder',
            player_role: 'Batsman',
            team_id: team2Id
        }, token1);

        if (failRes.status === 403) {
            log('✅ SUCCESS: User 1 blocked from adding to Team 2 (403 Forbidden).');
        } else {
            log(`❌ FAILED: Unexpected status ${failRes.status}: ${failRes.text}`);
        }

        // 6. User 1 adds player to Team 1 explicitly (Should Success)
        log('User 1 adding player to Team 1 explicitly...');
        const player1Res = await post(`${BASE_URL}/players`, {
            player_name: 'Player One',
            player_role: 'Batsman',
            team_id: team1Id
        }, token1);

        if ((player1Res.status === 201 || player1Res.status === 200) && player1Res.data.team_id === team1Id) {
            log('✅ SUCCESS: Player added to Team 1 explicitly.');
        } else {
            log(`❌ FAILED: Status ${player1Res.status}, TeamID: ${player1Res.data?.team_id}`);
        }

        // 7. User 1 adds player without team_id (Should Success, Default to Team 1)
        log('User 1 adding player without team_id...');
        const player2Res = await post(`${BASE_URL}/players`, {
            player_name: 'Player Two',
            player_role: 'Bowler'
        }, token1);

        if ((player2Res.status === 201 || player2Res.status === 200) && player2Res.data.team_id === team1Id) {
            log('✅ SUCCESS: Player added to Team 1 by default.');
        } else {
            log(`❌ FAILED: Status ${player2Res.status}, TeamID: ${player2Res.data?.team_id}`);
        }

        log('--- Test Completed ---');

    } catch (error) {
        log('Test Script Error: ' + error.message);
    }
}

runTest();
