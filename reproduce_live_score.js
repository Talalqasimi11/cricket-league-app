
const axios = require('axios');

const BASE_URL = 'http://localhost:5003/api';
// You might need to adjust the port if it's different. Backend usually runs on 5003 based on history.

async function runTest() {
    try {
        console.log("1. Creating a Match...");
        // We assume there are teams and a tournament. We'll pick existing ones or fail.
        // For simplicity, let's try to find an existing live match or create a simulated data flow.
        // Actually, checking 'getMatchLiveContext' output is easier directly via a script that imports the controller/db.

        // Changing approach: Use the existing check script style to inspect DB/Controller logic directly 
        // instead of full API integration test which might hit auth walls.

        const { db } = require('./backend/config/db');
        const { getLiveScore } = require('./backend/controllers/liveScoreController');

        // Mock Req/Res
        const mockRes = {
            json: (data) => console.log("JSON Response:", JSON.stringify(data, null, 2)),
            status: (code) => ({ json: (data) => console.log(`Status ${code}:`, data) })
        };

        // Find a live match
        const [matches] = await db.query("SELECT id FROM matches WHERE status='live' LIMIT 1");
        if (matches.length === 0) {
            console.log("No live matches found. Please start a match first.");
            return;
        }

        const matchId = matches[0].id;
        console.log(`Checking Live Score for Match ID: ${matchId}`);

        await getLiveScore({ params: { match_id: matchId } }, mockRes);

        process.exit(0);

    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

// We need to run this from the project root to access backend files
// But the user is in the root check? No, user workspace is root.
// We need to point to the correct paths.
