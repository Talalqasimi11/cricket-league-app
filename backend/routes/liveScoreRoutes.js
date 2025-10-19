const express = require("express");
const router = express.Router();
const { verifyToken: authMiddleware, requireScope } = require("../middleware/authMiddleware");
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

// Get live score
router.get("/:match_id", getLiveScore);

// Optional alias routes for consolidation
router.post('/deliveries', authMiddleware, requireScope('match:score'), addBall);

module.exports = router;
