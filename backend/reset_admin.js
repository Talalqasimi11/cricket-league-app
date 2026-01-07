const { db } = require('./config/db');
const bcrypt = require('bcryptjs');

async function resetAdmin() {
    try {
        const email = 'admin@example.com';
        const password = 'password123';
        const hashedPassword = await bcrypt.hash(password, 12);

        // Check if user exists
        const [users] = await db.query('SELECT * FROM users WHERE email = ?', [email]);

        if (users.length > 0) {
            console.log('Updating existing admin user...');
            await db.query('UPDATE users SET password_hash = ? WHERE email = ?', [hashedPassword, email]);
            console.log('✅ Admin password updated to:', password);
        } else {
            console.log('Creating new admin user...');
            // Need to know required fields. Assuming email/password_hash/username/is_admin
            // Based on authController, username is not always there but likely used.
            // Let's check db schema via generic insert or inspection if this fails.
            // Safe bet: username, email, password_hash
            await db.query('INSERT INTO users (email, password_hash, is_admin) VALUES (?, ?, 1)', [email, hashedPassword]);
            console.log('✅ Admin user created with password:', password);
        }

    } catch (e) {
        console.error('Error resetting admin:', e);
    } finally {
        process.exit();
    }
}

resetAdmin();
