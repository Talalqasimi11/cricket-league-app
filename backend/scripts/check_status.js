const path = require('path');
require("dotenv").config({ path: path.resolve(__dirname, '../.env') });
const { db } = require("../config/db");

async function checkStatus() {
    try {
        const [rows] = await db.query("SHOW COLUMNS FROM matches LIKE 'status'");
        console.log(JSON.stringify(rows, null, 2));
    } catch (err) {
        console.error(err);
    } finally {
        process.exit();
    }
}

checkStatus();
