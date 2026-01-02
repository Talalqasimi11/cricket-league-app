const { db } = require('./config/db');
require('dotenv').config();

async function createActivityLogsTable() {
    try {
        const createTableQuery = `
      CREATE TABLE IF NOT EXISTS user_activity_logs (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NULL,
        device_id VARCHAR(255),
        activity_type VARCHAR(50) NOT NULL,
        metadata JSON,
        ip_address VARCHAR(45),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `;

        await db.query(createTableQuery);
        console.log('user_activity_logs table created or already exists.');
        process.exit(0);
    } catch (error) {
        console.error('Error creating table:', error);
        process.exit(1);
    }
}

createActivityLogsTable();
