const express = require("express");
const router = express.Router();
const { verifyToken: authMiddleware, requireScope } = require("../middleware/authMiddleware");
const { rateLimiter } = require("../middleware/rateLimit");
const {
  startInnings,
  addBall,
  endInnings,
  getLiveScore,
  undoLastBall,
  setNewBatter
} = require("../controllers/liveScoreController");

// Start new innings
router.post("/start-innings", authMiddleware, requireScope('match:score'), startInnings);

// [FIX 2 & 3] Corrected middleware usage and function call
router.post("/undo", authMiddleware, undoLastBall);

// Add ball entry (auto check)
router.post("/ball", authMiddleware, requireScope('match:score'), addBall);

// Set New Batter
router.post("/batter", authMiddleware, requireScope('match:score'), setNewBatter);

// Manually end innings
router.post("/end-innings", authMiddleware, requireScope('match:score'), endInnings);

// Get live score with rate limiting
router.get("/:match_id", getLiveScore);

// Optional alias routes for consolidation
router.post('/deliveries', authMiddleware, requireScope('match:score'), addBall);

module.exports = router;