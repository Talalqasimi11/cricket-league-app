const express = require("express");
const router = express.Router();
const { verifyToken: authMiddleware, requireScope } = require("../middleware/authMiddleware");
const { rateLimiter } = require("../middleware/rateLimit");
const {
  startInnings,
  addBall,
  endInnings,
  getLiveScore,
} = require("../controllers/liveScoreController");

// Start new innings
router.post("/start-innings", authMiddleware, requireScope('match:score'), startInnings);

// Add ball entry (auto check)
router.post("/ball", authMiddleware, requireScope('match:score'), addBall);

// Manually end innings
router.post("/end-innings", authMiddleware, requireScope('match:score'), endInnings);

// Get live score with rate limiting
router.get("/:match_id", rateLimiter(100, 15), getLiveScore);

// Optional alias routes for consolidation
router.post('/deliveries', authMiddleware, requireScope('match:score'), addBall);

module.exports = router;
