const BASE_URL = 'http://localhost:3000/api';
let token = '';
let tournamentId = '';
let team1Id = '';
let team2Id = '';

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
            if (res.status === 200 && data === "") data = {}; // Handle empty OK
        }

        if (!res.ok) {
            throw { status: res.status, data };
        }
        return { status: res.status, data };
    } catch (err) {
        throw err;
    }
};

const getOrRegisterUser = async (email, password, username) => {
    try {
        const res = await request(`${BASE_URL}/auth/login`, {
            method: 'POST',
            body: JSON.stringify({ email, password })
        });
        return res.data.token;
    } catch (e) {
        // Register if login fails
        try {
            const res = await request(`${BASE_URL}/auth/register`, {
                method: 'POST',
                body: JSON.stringify({ email, password, username })
            });
            return res.data.token;
        } catch (regErr) {
            console.error('Login and Register failed for ' + email, regErr);
            throw regErr;
        }
    }
};

const getOrCreateTeam = async (name, loc) => {
    try {
        const res = await request(`${BASE_URL}/teams/my-team`);
        return res.data.id;
    } catch (e) {
        if (e.status === 404) {
            const res = await request(`${BASE_URL}/teams/my-team`, {
                method: 'POST',
                body: JSON.stringify({ team_name: name, team_location: loc })
            });
            return res.data.team.id;
        }
        throw e;
    }
}

const run = async () => {
    try {
        console.log('Authenticating users...');
        const tokenA = await getOrRegisterUser('admin@example.com', 'password123', 'admin');
        const tokenB = await getOrRegisterUser('user_b@example.com', 'password123', 'user_b');

        const t1Name = 'Team Winner ' + Date.now();
        const t2Name = 'Team Loser ' + Date.now();

        // 1. Create Tournament (User A)
        token = tokenA;
        console.log('Creating Tournament (User A)...');
        const tParams = { tournament_name: 'Test Comp ' + Date.now(), start_date: formatDate(new Date()), location: 'Virtual', overs: 5 };
        const tRes = await request(`${BASE_URL}/tournaments`, { method: 'POST', body: JSON.stringify(tParams) });
        tournamentId = tRes.data.tournament_id;
        console.log('✅ Tournament created ID:', tournamentId);

        // 2. Get/Create Teams
        console.log('Getting/Creating Team A (User A)...');
        team1Id = await getOrCreateTeam(t1Name, 'A');

        token = tokenB;
        console.log('Getting/Creating Team B (User B)...');
        team2Id = await getOrCreateTeam(t2Name, 'B');

        // 3. Register (User A)
        token = tokenA; // Switch back to User A (Tournament Owner)
        console.log('Registering Teams (User A)...');
        // Bulk add expects "team_ids" array
        await request(`${BASE_URL}/tournaments/${tournamentId}/teams`, {
            method: 'POST',
            body: JSON.stringify({ team_ids: [team1Id, team2Id] })
        });

        // 4. Start
        console.log('Starting Tournament...');
        await request(`${BASE_URL}/tournaments/${tournamentId}/start`, { method: 'POST' });

        // 5. Match
        console.log('Creating Manual Match...');
        const mRes = await request(`${BASE_URL}/tournament-matches/manual`, {
            method: 'POST',
            body: JSON.stringify({
                tournament_id: tournamentId,
                team1_name: t1Name,
                team2_name: t2Name,
                round: 'final',
                match_date: formatDate(new Date())
            })
        });
        const matchId = mRes.data.match.id;

        // 6. Start Match
        console.log('Starting Match...');
        await request(`${BASE_URL}/tournament-matches/${matchId}/start`, { method: 'POST' });

        // 7. End Match
        console.log('Ending Match...');
        await request(`${BASE_URL}/tournament-matches/${matchId}/end`, {
            method: 'POST',
            body: JSON.stringify({ winner_id: team1Id })
        });

        // 8. Verify
        console.log('Verifying...');
        const tList = await request(`${BASE_URL}/tournaments`); // Get all
        // Check main list first
        const myT = tList.data.data.find(t => t.id == tournamentId);
        console.log(`Tournament Status in (All): ${myT.status}`);

        // Check filtered list
        const tListCompleted = await request(`${BASE_URL}/tournaments?status=completed`);
        const myTCompleted = tListCompleted.status === 200 ? (tListCompleted.data.data.find(t => t.id == tournamentId)) : null;

        console.log(`Tournament found in ?status=completed: ${!!myTCompleted}`);

        if (myT.status === 'completed') {
            console.log('✅ TEST PASSED: Tournament marked as completed.');
        } else {
            console.log('❌ TEST FAILED: Tournament is ' + myT.status);
        }
    } catch (e) {
        console.error('Unhandled Error:', JSON.stringify(e, null, 2));
    }
}

run();
