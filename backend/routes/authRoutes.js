const express = require('express');
const router = express.Router();
const { registerCaptain, loginCaptain } = require('../controllers/authController');

// Register new captain
router.post('/register', registerCaptain);

// Login existing captain
router.post('/login', loginCaptain);

module.exports = router;
