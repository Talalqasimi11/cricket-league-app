
const fs = require('fs');
const path = require('path');
const { db } = require('../config/db');

async function dumpSchema() {
    try {
        const [tables] = await db.query('SHOW TABLES');
        const tableNames = tables.map(t => Object.values(t)[0]);

        let fullSchema = "-- Database Schema Dump\n\n";
        fullSchema += "SET FOREIGN_KEY_CHECKS = 0;\n\n";

        for (const tableName of tableNames) {
            const [createResult] = await db.query(`SHOW CREATE TABLE \`${tableName}\``);
            const createSql = createResult[0]['Create Table'];
            fullSchema += `-- Table structure for table \`${tableName}\`\n`;
            fullSchema += `DROP TABLE IF EXISTS \`${tableName}\`;\n`;
            fullSchema += `${createSql};\n\n`;
        }

        fullSchema += "SET FOREIGN_KEY_CHECKS = 1;\n";

        const outputPath = path.resolve(__dirname, '../schema.sql');
        fs.writeFileSync(outputPath, fullSchema);
        console.log(`✅ Schema dumped successfully to ${outputPath}`);
        process.exit(0);
    } catch (error) {
        console.error('❌ Error dumping schema:', error);
        process.exit(1);
    }
}

dumpSchema();
