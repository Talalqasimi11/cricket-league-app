const http = require('http');

const post = (path, data, token) => {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: '127.0.0.1',
            port: 5003,
            path: '/api' + path,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(JSON.stringify(data))
            }
        };
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
        req.write(JSON.stringify(data));
        req.end();
    });
};

const get = (path, token) => {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: '127.0.0.1',
            port: 5003,
            path: '/api' + path,
            method: 'GET',
            headers: {}
        };
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
        req.end();
    });
};

async function testFix() {
    try {
        const user = {
            username: 'test_scorer_' + Date.now(),
            phone_number: '+' + Math.floor(10000000000 + Math.random() * 90000000000), // Random 11 digit
            password: 'password123'
        };

        console.log('1. Registering user...');
        let res;
        try {
            res = await post('/auth/register', user);
        } catch (e) {
            console.error('Register request failed:', e);
            return;
        }

        console.log('Register status:', res.status);
        let token = res.data.token;

        if (!token) {
            console.log('Registration failed (maybe user exists), trying login...');
            console.log('Register response:', res.data);
            res = await post('/auth/login', { phone_number: user.phone_number, password: user.password });
            token = res.data.token;
        }

        if (!token) {
            console.error('Login response:', res.data);
            throw new Error('Failed to get token');
        }

        console.log('2. Creating friendly match...');
        res = await post('/tournament-matches/friendly', {
            team1_name: 'Team A',
            team2_name: 'Team B',
            overs: 5,
            match_date: new Date().toISOString()
        }, token);

        console.log('Create Match Status:', res.status);
        if (res.status !== 201) {
            require('fs').writeFileSync('error.json', JSON.stringify(res.data, null, 2));
            console.error('Create match failed. Check error.json');
            return;
        }

        const matchId = res.data.id;
        console.log(`   Match created with ID: ${matchId}, Status: ${res.data.status}`);

        if (res.data.status !== 'not_started') {
            console.error('❌ Expected match status to be not_started');
            return;
        }

        console.log('3. Starting innings (should auto-start match)...');
        res = await post('/live/start-innings', {
            match_id: matchId,
            batting_team_id: res.data.team1_id,
            bowling_team_id: res.data.team2_id,
            inning_number: 1
        }, token);

        console.log('   Start Innings Response:', res.data);

        if (res.status !== 200) {
            console.error('❌ Start Innings Failed');
            return;
        }

        console.log('4. Verifying match status...');
        res = await get(`/matches/${matchId}`, token);
        const currentStatus = res.data.match.status;
        console.log(`   Current Match Status: ${currentStatus}`);

        if (currentStatus === 'live') {
            console.log('🎉 SUCCESS: Match was auto-started and innings began!');
        } else {
            console.error('❌ FAILURE: Match status is not live');
        }

    } catch (err) {
        console.error('❌ Test Failed:', err);
    }
}

testFix();
