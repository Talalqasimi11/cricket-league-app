const { createTournament } = require('../controllers/tournamentController');
const { db } = require('../config/db');

// Mock Response Object
const mockRes = () => {
    const res = {};
    res.status = (code) => {
        res.statusCode = code;
        return res;
    };
    res.json = (data) => {
        console.log(`[Response] Status: ${res.statusCode}, Data: `, JSON.stringify(data, null, 2));
        return res;
    };
    res.send = (data) => {
        console.log(`[Response] Status: ${res.statusCode}, Data: `, data);
        return res;
    };
    return res;
};

async function runTest() {
    console.log('--- Starting Controller Logic Test ---');

    // Test Case 1: Valid Payload (with start_date)
    console.log("\n1. Testing with Valid Payload (including start_date)...");
    const validReq = {
        body: {
            tournament_name: "UnitTest Tourney " + Date.now(),
            location: "Test Venue",
            overs: 10,
            type: "knockout",
            start_date: new Date().toISOString()
        },
        user: { id: 1 }, // Mock user
        log: { error: console.error } // Mock logger
    };

    try {
        await createTournament(validReq, mockRes());
    } catch (e) {
        console.error("Test 1 Failed:", e);
    }

    // Test Case 2: Invalid Payload (missing start_date)
    console.log("\n2. Testing with Invalid Payload (missing start_date)...");
    const invalidReq = {
        body: {
            tournament_name: "UnitTest Tourney Fail",
            location: "Test Venue",
            overs: 10,
            type: "knockout"
            // Missing start_date
        },
        user: { id: 1 },
        log: { error: console.error }
    };

    try {
        await createTournament(invalidReq, mockRes());
    } catch (e) {
        console.error("Test 2 Failed:", e);
    }

    // Cleanup
    console.log("\nTest finished. Closing DB pool...");
    try {
        // We need to wait a bit because the controller might be async
        // and db pool might need time to close if connections are active.
        await db.end();
    } catch (e) {
        // Ignore close errors
    }
}

runTest();
