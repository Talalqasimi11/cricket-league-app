
const { db } = require('../config/db');

describe('Database Connection Debug', () => {
    it('should connect to database and execute query', async () => {
        try {
            const [rows] = await db.execute('SELECT 1 as val');
            expect(rows[0].val).toBe(1);
        } catch (err) {
            console.error('Debug Test DB Error:', err);
            throw err;
        } finally {
            await db.end();
        }
    });
});
