const path = require('path');
require("dotenv").config({ path: path.resolve(__dirname, '../.env') });
const { db } = require("../config/db");

async function addColumn() {
    try {
        console.log("Adding sequence column...");
        await db.query("ALTER TABLE ball_by_ball ADD COLUMN sequence INT DEFAULT 0");
        console.log("✅ Column added successfully");
    } catch (err) {
        if (err.code === 'ER_DUP_FIELDNAME') {
            console.log("⚠️ Column already exists");
        } else {
            console.error("❌ Error:", err);
        }
    } finally {
        await db.end();
    }
}

addColumn();
