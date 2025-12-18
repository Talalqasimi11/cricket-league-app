const path = require('path');
require("dotenv").config({ path: path.resolve(__dirname, '../.env') });
const { db } = require("../config/db");

async function checkTeams() {
    try {
        const [teams] = await db.query("SELECT * FROM teams WHERE id IN (20, 21)");
        console.log("Teams:", JSON.stringify(teams, null, 2));

        const [users] = await db.query("SELECT * FROM users");
        console.log("All Users:", JSON.stringify(users, null, 2));

    } catch (err) {
        console.error("Error:", err);
    } finally {
        await db.end();
    }
}

checkTeams();
