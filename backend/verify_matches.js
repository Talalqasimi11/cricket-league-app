const BASE_URL = 'http://localhost:3000/api';
let token = '';
let matchId = '';

// Helper for fetch wrapper
const request = async (url, options = {}) => {
    const headers = {
        'Content-Type': 'application/json',
        ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
        ...options.headers
    };

    try {
        const res = await fetch(url, { ...options, headers });
        const contentType = res.headers.get("content-type");

        let data;
        if (contentType && contentType.indexOf("application/json") !== -1) {
            data = await res.json();
        } else {
            data = await res.text();
        }

        if (!res.ok) {
            throw { status: res.status, data };
        }
        return { status: res.status, data };
    } catch (err) {
        throw err;
    }
};

const login = async () => {
    try {
        console.log('Attempting login...');
        let res;
        try {
            res = await request(`${BASE_URL}/auth/login`, {
                method: 'POST',
                body: JSON.stringify({ email: 'admin@example.com', password: 'password123' })
            });
        } catch (e) {
            console.log('Login failed, trying registration...');
            res = await request(`${BASE_URL}/auth/register`, {
                method: 'POST',
                body: JSON.stringify({
                    username: 'testu_' + Date.now(),
                    email: 'test_' + Date.now() + '@example.com',
                    password: 'password123'
                })
            });
        }
        token = res.data.token;
        console.log('✅ Auth successful');
    } catch (err) {
        console.error('Auth failed:', err.data || err);
        process.exit(1);
    }
};

const createFriendlyMatch = async () => {
    try {
        console.log('Creating friendly match...');
        const res = await request(`${BASE_URL}/tournament-matches/friendly`, {
            method: 'POST',
            body: JSON.stringify({
                team1_name: 'Team A',
                team2_name: 'Team B',
                overs: 5,
                match_date: new Date().toISOString(),
                venue: 'Test Ground'
            })
        });
        matchId = res.data.id;
        console.log('✅ Match created:', matchId);
    } catch (err) {
        console.error('Create match failed:', err.data || err);
    }
};

const checkMatchStatus = async (expectedStatus, useFilter = false) => {
    try {
        let url = `${BASE_URL}/matches`;
        if (useFilter && expectedStatus) url += `?status=${expectedStatus}`;

        const res = await request(url);
        const matches = res.data.matches || [];

        if (matchId) {
            const match = matches.find(m => m.id == matchId);
            if (match) {
                console.log(`🔎 Match ${matchId} Status: ${match.status} (Expected filter: ${expectedStatus || 'none'})`);
            } else if (useFilter) {
                console.log(`ℹ️ Match ${matchId} not found in filtered list (Correct if status mismatch)`);
            } else {
                console.error(`❌ Match ${matchId} not found in main list!`);
            }
        }

        console.log(`📊 Total matches returned${useFilter ? ' with filter ' + expectedStatus : ''}: ${matches.length}`);
    } catch (err) {
        console.error('Check status failed:', err.data || err);
    }
};

const runVerify = async () => {
    await login();
    await createFriendlyMatch();

    console.log('\n--- Checking Initial Status (Scheduled) ---');
    await checkMatchStatus(null, false); // All
    await checkMatchStatus('completed', true); // Should NOT have our new match
    await checkMatchStatus('live', true);
    await checkMatchStatus('scheduled', true); // Should have our new match (mapped from not_started) or similar
};

runVerify();
