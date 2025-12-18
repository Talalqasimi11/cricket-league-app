// Native fetch is available in Node 18+
// Suppress verification errors for self-signed or ngrok
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const API_URL = 'http://localhost:5000/api';

async function testAdmin() {
    try {
        console.log('1. Logging in as Admin...');
        const loginRes = await fetch(`${API_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                phone_number: '+91234567890',
                password: 'admin'
            })
        });

        console.log('   Login Status:', loginRes.status);
        if (!loginRes.ok) {
            const errText = await loginRes.text();
            throw new Error(`Login failed: ${errText}`);
        }

        const data = await loginRes.json();
        const { token, user } = data;
        console.log('   User:', user);
        console.log('   Token:', token ? 'Recieved' : 'Missing');

        if (!token) throw new Error('No token received');

        // Decode token
        const payload = JSON.parse(Buffer.from(token.split('.')[1], 'base64').toString());
        console.log('   Token Roles:', payload.roles);

        if (!payload.roles.includes('admin')) {
            console.error('❌ Token DOES NOT have admin role!');
        } else {
            console.log('✅ Token has admin role.');
        }

        const headers = {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
        };

        console.log('\n2. Fetching Matches...');
        const matchesRes = await fetch(`${API_URL}/admin/matches`, { headers });
        console.log('   Matches Status:', matchesRes.status);
        if (matchesRes.ok) {
            const matches = await matchesRes.json();
            console.log('   Matches Count:', matches.length);
        } else {
            console.error('   Failed to fetch matches:', await matchesRes.text());
        }

        console.log('\n3. Fetching Tournaments...');
        const tournRes = await fetch(`${API_URL}/admin/tournaments`, { headers });
        console.log('   Tournaments Status:', tournRes.status);
        if (tournRes.ok) {
            const tournaments = await tournRes.json();
            console.log('   Tournaments Count:', tournaments.length);
        } else {
            console.error('   Failed to fetch tournaments:', await tournRes.text());
        }

    } catch (e) {
        console.error('Test Failed:', e.message);
        console.error('Stack:', e.stack);
    }
}

// Redirect checking
const fs = require('fs');
const util = require('util');
const logFile = fs.createWriteStream('api_test_results.txt', { flags: 'w' });
const logStdout = process.stdout;

console.log = function (d) { //
    logFile.write(util.format(d) + '\n');
    logStdout.write(util.format(d) + '\n');
};

testAdmin();
