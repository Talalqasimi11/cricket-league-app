const axios = require('axios');

async function testViewerApi() {
    const matchId = 9; // The match ID from the user's error report
    const url = `http://localhost:5000/api/viewer/live-score/${matchId}`;

    console.log(`Testing Viewer API: ${url}`);
    try {
        const response = await axios.get(url);
        console.log('Response status:', response.status);
        console.log('Response data:', JSON.stringify(response.data, null, 2));
    } catch (error) {
        if (error.response) {
            console.log('Error Status:', error.response.status);
            console.log('Error Data:', error.response.data);
        } else {
            console.log('Error Message:', error.message);
        }
    }
}

testViewerApi();
