
const http = require('http');

const LOGIN_DATA = JSON.stringify({
    phone_number: '923123456789',
    password: 'password123'
});

function request(path, method, data, token) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'localhost',
            port: 5003,
            path: path,
            method: method,
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': data ? Buffer.byteLength(data) : 0
            }
        };

        if (token) {
            options.headers['Authorization'] = 'Bearer ' + token;
        }

        const req = http.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                try {
                    const json = body ? JSON.parse(body) : {};
                    resolve({ status: res.statusCode, data: json });
                } catch (e) {
                    resolve({ status: res.statusCode, data: body });
                }
            });
        });

        req.on('error', (e) => reject(e));
        if (data) req.write(data);
        req.end();
    });
}

async function run() {
    try {
        // 1. Login
        console.log('Logging in...');
        const loginRes = await request('/api/auth/login', 'POST', LOGIN_DATA);
        if (loginRes.status !== 200) {
            console.error('Login failed:', loginRes.status, loginRes.data);
            return;
        }
        const token = loginRes.data.token;
        const myUserId = loginRes.data.user.id;
        console.log('Logged in. ID:', myUserId);

        // 2. Get Teams
        console.log('Fetching teams...');
        const teamsRes = await request('/api/teams', 'GET', null, token);
        let teams = teamsRes.data.teams || teamsRes.data || [];

        const otherTeam = teams.find(t => t.owner_id !== myUserId);
        if (!otherTeam) {
            console.error('No other team found.');
            return;
        }
        console.log('Target Team:', otherTeam.team_name, otherTeam.id);

        // 3. Test Permanent (Fail)
        console.log('Test 1: Permanent (Expect 403)');
        const permData = JSON.stringify({
            player_name: 'Illegal Perm',
            player_role: 'Batsman',
            team_id: otherTeam.id,
            is_temporary: false
        });
        const permRes = await request('/api/players', 'POST', permData, token);
        if (permRes.status === 403) {
            console.log('PASS: 403 Received');
        } else {
            console.log('FAIL: Status', permRes.status);
        }

        // 4. Test Temporary (Success)
        console.log('Test 2: Temporary (Expect 201)');
        const tempData = JSON.stringify({
            player_name: 'Valid Temp',
            player_role: 'Batsman',
            team_id: otherTeam.id,
            is_temporary: true
        });
        const tempRes = await request('/api/players', 'POST', tempData, token);
        if (tempRes.status === 201) {
            console.log('PASS: 201 Received', tempRes.data);
        } else {
            console.log('FAIL: Status', permRes.status, permRes.data);
        }

    } catch (e) {
        console.error('Error:', e);
    }
}

run();
