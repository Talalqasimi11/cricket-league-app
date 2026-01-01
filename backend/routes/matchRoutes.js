const express = require("express");
const router = express.Router();
const { verifyToken, requireScope } = require("../middleware/authMiddleware");
const {
    getLiveMatches,
    getMatchById,
    getAllMatches,
    createMatch,
    getMyMatches,
    deleteMatch
} = require("../controllers/matchController");

// Public routes for live matches
router.get("/", getAllMatches);
router.get("/live", getLiveMatches);
router.get("/my", verifyToken, getMyMatches);
router.get("/:id/live", getMatchById);

// Protected routes
router.post("/", verifyToken, requireScope('match:score'), createMatch);
router.delete("/:id", verifyToken, requireScope('match:score'), deleteMatch);

module.exports = router;
