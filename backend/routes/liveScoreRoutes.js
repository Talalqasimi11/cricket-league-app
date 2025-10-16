const express = require("express");
const router = express.Router();
const { verifyToken: authMiddleware } = require("../middleware/authMiddleware");
const {
  startInnings,
  addBall,
  endInnings,
  getLiveScore,
} = require("../controllers/liveScoreController");

// Start new innings
router.post("/start-innings", authMiddleware, startInnings);

// Add ball entry (auto check)
router.post("/ball", authMiddleware, addBall);

// Manually end innings
router.post("/end-innings", authMiddleware, endInnings);

// Get live score
router.get("/:match_id", getLiveScore);

// Optional alias routes for consolidation
router.post('/deliveries', authMiddleware, addBall);

module.exports = router;
