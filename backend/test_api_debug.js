const BASE_URL = 'http://localhost:5000/api';

async function test() {
    try {
        // 1. Fetch all tournaments
        console.log('Fetching all tournaments...');
        const listRes = await fetch(`${BASE_URL}/tournaments`);
        const listData = await listRes.json();

        if (!listData.data || listData.data.length === 0) {
            console.log('No tournaments found.');
            return;
        }

        const tournamentId = listData.data[0].id;
        console.log('Fetching details for tournament:', tournamentId);

        // 2. Fetch Tournament Details
        const detailsRes = await fetch(`${BASE_URL}/tournaments/${tournamentId}`);
        const detailsData = await detailsRes.json();

        console.log('--- RESPONSE DATA ---');
        console.log(JSON.stringify(detailsData, null, 2));

    } catch (e) {
        console.error('Error:', e);
    }
}

test();
