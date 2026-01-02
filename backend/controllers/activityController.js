const { db } = require('../config/db');

// Request logger middleware integration could be done here ensuring we don’t block
exports.logActivity = async (req, res) => {
    try {
        const { user_id, device_id, activity_type, metadata } = req.body;
        // Basic validation
        if (!activity_type) {
            return res.status(400).json({ error: 'activity_type is required' });
        }

        const ip_address = req.ip || req.connection.remoteAddress;

        const query = `
            INSERT INTO user_activity_logs (user_id, device_id, activity_type, metadata, ip_address)
            VALUES (?, ?, ?, ?, ?)
        `;

        // Use JSON.stringify for metadata if it's an object, or null
        const meta = metadata ? JSON.stringify(metadata) : null;

        await db.query(query, [user_id || null, device_id || null, activity_type, meta, ip_address]);

        res.status(201).json({ message: 'Activity logged successfully' });
    } catch (error) {
        console.error('Error logging activity:', error);
        res.status(500).json({ error: 'Failed to log activity' });
    }
};

exports.getLogs = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const offset = (page - 1) * limit;

        const countQuery = 'SELECT COUNT(*) as total FROM user_activity_logs';
        const [countResult] = await db.query(countQuery);
        const total = countResult[0].total;

        // Fetch logs with user details if available
        const query = `
            SELECT l.*, u.username, u.email 
            FROM user_activity_logs l
            LEFT JOIN users u ON l.user_id = u.id
            ORDER BY l.created_at DESC
            LIMIT ? OFFSET ?
        `;

        const [logs] = await db.query(query, [limit, offset]);

        // Parse metadata JSON
        const parsedLogs = logs.map(log => ({
            ...log,
            metadata: typeof log.metadata === 'string' ? JSON.parse(log.metadata) : log.metadata
        }));

        res.status(200).json({
            logs: parsedLogs,
            pagination: {
                current_page: page,
                total_pages: Math.ceil(total / limit),
                total_items: total,
                items_per_page: limit
            }
        });
    } catch (error) {
        console.error('Error fetching activity logs:', error);
        res.status(500).json({ error: 'Failed to fetch activity logs' });
    }
};

exports.getStats = async (req, res) => {
    try {
        // Today's total opens
        const todayStart = new Date();
        todayStart.setHours(0, 0, 0, 0);

        const [opensResult] = await db.query(
            "SELECT COUNT(*) as count FROM user_activity_logs WHERE activity_type = 'APP_OPEN' AND created_at >= ?",
            [todayStart]
        );

        // Active devices (unique) in last 24h
        const yesterday = new Date(new Date().getTime() - 24 * 60 * 60 * 1000);
        const [activeDevicesResult] = await db.query(
            "SELECT COUNT(DISTINCT device_id) as count FROM user_activity_logs WHERE created_at >= ?",
            [yesterday]
        );

        // Active users (unique) in last 24h
        const [activeUsersResult] = await db.query(
            "SELECT COUNT(DISTINCT user_id) as count FROM user_activity_logs WHERE user_id IS NOT NULL AND created_at >= ?",
            [yesterday]
        );

        res.status(200).json({
            today_opens: opensResult[0].count,
            active_devices_24h: activeDevicesResult[0].count,
            active_users_24h: activeUsersResult[0].count
        });

    } catch (error) {
        console.error('Error fetching activity stats:', error);
        res.status(500).json({ error: 'Failed to fetch stats' });
    }
};
