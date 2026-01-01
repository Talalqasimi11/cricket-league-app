const http = require('http');

const PORT = 5000;
const HOST = '127.0.0.1';

const request = (method, path, data, token) => {
    return new Promise((resolve, reject) => {
        const bodyContent = data ? JSON.stringify(data) : '';
        const options = {
            hostname: HOST,
            port: PORT,
            path: '/api' + path,
            method: method,
            headers: {
                'Content-Type': 'application/json',
                'x-client-type': 'mobile'
            }
        };
        if (bodyContent) options.headers['Content-Length'] = Buffer.byteLength(bodyContent);
        if (token) options.headers['Authorization'] = `Bearer ${token}`;

        const req = http.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                try {
                    resolve({ status: res.statusCode, data: JSON.parse(body) });
                } catch (e) {
                    resolve({ status: res.statusCode, data: body });
                }
            });
        });

        req.on('error', (e) => reject(e));
        if (bodyContent) req.write(bodyContent);
        req.end();
    });
};

const post = (path, data, token) => request('POST', path, data, token);
const get = (path, token) => request('GET', path, null, token);

async function testAuthFix() {
    console.log('🚀 Starting Auth Fix Verification Test...');

    try {
        // 1. Register User A (The Creator)
        const userA = {
            phone_number: '+1' + Math.floor(1000000000 + Math.random() * 9000000000),
            password: 'password123'
        };
        console.log(`\n1. Registering User A (${userA.phone_number})...`);
        const regA = await post('/auth/register', userA);
        const tokenA = regA.data.token;
        if (!tokenA) throw new Error('Failed to register User A');
        const userIdA = regA.data.user.id;
        console.log(`   User A registered (ID: ${userIdA})`);

        // 2. Register User B (The Team Owner)
        const userB = {
            phone_number: '+1' + Math.floor(1000000000 + Math.random() * 9000000000),
            password: 'password123'
        };
        console.log(`\n2. Registering User B (${userB.phone_number})...`);
        const regB = await post('/auth/register', userB);
        const tokenB = regB.data.token;
        if (!tokenB) throw new Error('Failed to register User B');
        const userIdB = regB.data.user.id;
        console.log(`   User B registered (ID: ${userIdB})`);

        // 3. User B creates two teams
        console.log('\n3. User B creating Team 1 and Team 2...');
        const team1Res = await post('/teams', { team_name: 'Team B1', team_location: 'Loc 1' }, tokenB);
        const team2Res = await post('/teams', { team_name: 'Team B2', team_location: 'Loc 2' }, tokenB);
        const team1Id = team1Res.data.id;
        const team2Id = team2Res.data.id;
        console.log(`   Teams created (ID1: ${team1Id}, ID2: ${team2Id})`);

        // 4. User A creates a friendly match between User B's teams
        console.log('\n4. User A creating a match between User B\'s teams...');
        const matchRes = await post('/tournament-matches/friendly', {
            team1_id: team1Id,
            team2_id: team2Id,
            overs: 20,
            match_date: new Date().toISOString(),
            venue: 'Test Venue'
        }, tokenA);

        if (matchRes.status !== 201) {
            console.error('   Create Match Failed:', matchRes.data);
            throw new Error('Failed to create match');
        }
        const matchId = matchRes.data.id;
        console.log(`   Match created (ID: ${matchId}). Creator is User A.`);

        // 5. User A tries to start innings (Should SUCCEED now)
        console.log('\n5. User A (Creator) starting innings...');
        const startInningsRes = await post('/live/start-innings', {
            match_id: matchId,
            batting_team_id: team1Id,
            bowling_team_id: team2Id,
            inning_number: 1
        }, tokenA);

        console.log(`   Response Status: ${startInningsRes.status}`);
        if (startInningsRes.status === 200) {
            console.log('   ✅ SUCCESS: Match Creator can start innings!');
        } else {
            console.error('   ❌ FAILURE: Match Creator denied access:', startInningsRes.data);
        }

        // 6. User B (Team Owner but not creator) try to add a ball (Should SUCCEED because they own teams)
        console.log('\n6. User B (Team Owner) adding a ball...');
        const addBallResB = await post('/live/ball', {
            match_id: matchId,
            inning_id: startInningsRes.data.inning_id,
            runs: 1,
            batsman_id: 1, // Dummy IDs, controller should check auth before IDs
            bowler_id: 2,
            over_number: 0,
            ball_number: 1
        }, tokenB);

        console.log(`   Response Status: ${addBallResB.status}`);
        if (addBallResB.status === 400 || addBallResB.status === 200) {
            // 400 is fine here as it means auth passed but dummy IDs failed
            console.log('   ✅ SUCCESS: Team Owner has access.');
        } else if (addBallResB.status === 403) {
            console.error('   ❌ FAILURE: Team Owner denied access.');
        }

        // 7. Verify guest access to WebSocket (Simulation via HTTP GET live score)
        console.log('\n7. Verifying public access to live score...');
        const publicRes = await get(`/live/${matchId}`);
        if (publicRes.status === 200) {
            console.log('   ✅ SUCCESS: Live score is public.');
        } else {
            console.error('   ❌ FAILURE: Live score is not public.');
        }

    } catch (err) {
        console.error('\n❌ Test Interrupted:', err.message);
    }
}

testAuthFix();
