const express = require('express');
const router = express.Router();
const activityController = require('../controllers/activityController');
// const authMiddleware = require('../middleware/authMiddleware'); // Uncomment if admin protection required

// Public route to log activity (app might not be logged in yet)
router.post('/log', activityController.logActivity);

// Admin routes (should be protected in prod)
router.get('/logs', activityController.getLogs);
router.get('/stats', activityController.getStats);

module.exports = router;
