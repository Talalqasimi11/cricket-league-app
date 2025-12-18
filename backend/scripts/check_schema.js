const path = require('path');
require("dotenv").config({ path: path.resolve(__dirname, '../.env') });
const { db } = require("../config/db");

async function checkSchema() {
    try {
        const [rows] = await db.query("DESCRIBE ball_by_ball");
        console.log(JSON.stringify(rows, null, 2));
    } catch (err) {
        console.error(err);
    } finally {
        process.exit();
    }
}

checkSchema();
