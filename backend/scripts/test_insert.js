const path = require('path');
require("dotenv").config({ path: path.resolve(__dirname, '../.env') });
const { db } = require("../config/db");

async function testInsert() {
    try {
        // Ensure user exists
        const [users] = await db.query("SELECT id FROM users LIMIT 1");
        let userId = users.length > 0 ? users[0].id : 1;

        // Create dummy teams
        const [t1] = await db.query("INSERT INTO teams (team_name, owner_id) VALUES (?, ?)", ["T1", userId]);
        const [t2] = await db.query("INSERT INTO teams (team_name, owner_id) VALUES (?, ?)", ["T2", userId]);

        console.log("Teams created:", t1.insertId, t2.insertId);

        // Try insert
        const query = `INSERT INTO matches (team1_id, team2_id, overs, status, match_datetime, venue, tournament_id) 
                   VALUES (?, ?, ?, 'scheduled', ?, ?, NULL)`;
        const params = [t1.insertId, t2.insertId, 5, new Date(), "Test"];

        console.log("Executing query:", query);
        console.log("Params:", params);

        const [res] = await db.query(query, params);
        console.log("Insert success:", res.insertId);

    } catch (err) {
        console.error("Insert failed:", err);
    } finally {
        process.exit();
    }
}

testInsert();
