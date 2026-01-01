const BASE_URL = 'http://localhost:5000/api';

async function runTest() {
    try {
        // 1. Login
        const loginRes = await fetch(`${BASE_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: 'admin@example.com', password: 'password123' })
        });

        if (!loginRes.ok) throw new Error(`Login failed: ${loginRes.status}`);
        const loginData = await loginRes.json();
        const token = loginData.token;
        const headers = {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
        };

        console.log("Logged in.");

        // 2. Create Match
        const matchRes = await fetch(`${BASE_URL}/matches`, {
            method: 'POST',
            headers: headers,
            body: JSON.stringify({
                team1_id: 1,
                team2_id: 2,
                date: new Date().toISOString(),
                venue: "Test Venue",
                overs: 10
            })
        });
        const matchData = await matchRes.json();
        const matchId = matchData.matchId;
        console.log(`Match Created: ${matchId}`);

        // 3. Start Innings
        await fetch(`${BASE_URL}/live/start-innings`, {
            method: 'POST',
            headers: headers,
            body: JSON.stringify({
                match_id: matchId,
                batting_team_id: 1,
                bowling_team_id: 2,
                inning_number: 1,
                striker_id: 1,
                non_striker_id: 2,
                bowler_id: 12
            })
        });
        console.log("Innings Started.");

        // 4. Fetch Context to get Inning ID
        const contextRes = await fetch(`${BASE_URL}/live/${matchId}`, { headers: headers });
        const contextData = await contextRes.json();
        const inningId = contextData.innings.find(i => i.status === 'in_progress').id;
        console.log(`Inning ID: ${inningId}`);

        // 5. Add Ball
        await fetch(`${BASE_URL}/live/ball`, {
            method: 'POST',
            headers: headers,
            body: JSON.stringify({
                match_id: matchId,
                inning_id: inningId,
                runs: 4, // Hit a boundary
                over_number: 0,
                ball_number: 1,
                batsman_id: 1,
                bowler_id: 12
            })
        });
        console.log("Ball Added (4 runs).");

        // 6. Verify Context Again
        const finalRes = await fetch(`${BASE_URL}/live/${matchId}`, { headers: headers });
        const finalData = await finalRes.json();
        const stats = finalData.player_stats;

        console.log("Player Stats:", JSON.stringify(stats, null, 2));

        const strikerStat = stats.find(p => p.player_id === 1);
        if (!strikerStat || strikerStat.runs !== 4 || strikerStat.balls_faced !== 1) {
            console.error("FAIL: Striker stats incorrect.", strikerStat);
        } else {
            console.log("SUCCESS: Striker stats correct.");
        }

        // Check extra fields in match_stats response like player_name
        if (finalData.player_stats.length > 0) {
            if (!finalData.player_stats[0].player_name) {
                console.error("FAIL: player_name missing in stats");
            } else {
                console.log("SUCCESS: player_name present:", finalData.player_stats[0].player_name);
            }
        }

    } catch (e) {
        console.error("Error:", e);
    }
}

runTest();
