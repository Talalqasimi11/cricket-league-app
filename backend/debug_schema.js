const { db } = require("./config/db");

async function checkSchema() {
    try {
        const [rows] = await db.query("DESCRIBE matches");
        console.log("Matches Table Columns:");
        rows.forEach(r => console.log(`${r.Field} | ${r.Null} | ${r.Default}`));
    } catch (err) {
        console.error(err);
    } finally {
        process.exit();
    }
}

checkSchema();
