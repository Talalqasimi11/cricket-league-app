const { db } = require('./config/db');

async function setup() {
    try {
        // 1. Get Admin Team
        let [adminTeams] = await db.query(`
            SELECT t.id FROM teams t 
            JOIN users u ON t.owner_id = u.id 
            WHERE u.email = 'admin@example.com'
        `);

        let adminTeamId;
        if (adminTeams.length > 0) {
            adminTeamId = adminTeams[0].id;
        } else {
            console.log("Admin has no team? Please run creation logic via API or insert here.");
            // Insert admin team logic if needed, but assuming admin has team from prev runs
            const [adminUser] = await db.query("SELECT id FROM users WHERE email = 'admin@example.com'");
            if (adminUser.length === 0) throw new Error("Admin user not found");

            const [res] = await db.query("INSERT INTO teams (team_name, team_location, owner_id) VALUES ('Admin Team', 'HQ', ?)", [adminUser[0].id]);
            adminTeamId = res.insertId;
        }

        // 2. Ensure User C exists
        let [userC] = await db.query("SELECT id FROM users WHERE email = 'user_c@example.com'");
        let userCId;
        if (userC.length === 0) {
            const [res] = await db.query("INSERT INTO users (username, email, password_hash, phone_number) VALUES ('user_c', 'user_c@example.com', 'hash', '1234567890')");
            userCId = res.insertId;
        } else {
            userCId = userC[0].id;
        }

        // 3. Ensure Team C exists
        let [teamC] = await db.query("SELECT id FROM teams WHERE owner_id = ?", [userCId]);
        let teamCId;
        if (teamC.length === 0) {
            const [res] = await db.query("INSERT INTO teams (team_name, team_location, owner_id) VALUES ('User C Team', 'Loc C', ?)", [userCId]);
            teamCId = res.insertId;
        } else {
            teamCId = teamC[0].id;
        }

        console.log("TEAM_IDS=" + adminTeamId + "," + teamCId);

    } catch (e) {
        console.error(e);
    } finally {
        process.exit();
    }
}

setup();
