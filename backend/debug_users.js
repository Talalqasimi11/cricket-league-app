const { db } = require("./config/db");

async function checkUsers() {
    try {
        const [users] = await db.query("SELECT * FROM users LIMIT 1");
        console.log("User:", users[0]);
    } catch (err) {
        console.error(err);
    } finally {
        process.exit();
    }
}

checkUsers();
