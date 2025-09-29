const express = require("express");
const router = express.Router();
const verifyToken = require("../middleware/authMiddleware");
const { getMyTeam, updateMyTeam, getAllTeams } = require("../controllers/teamController");

// Public route
router.get("/all", getAllTeams);

// Protected routes
router.get("/my-team", verifyToken, getMyTeam);
router.put("/update", verifyToken, updateMyTeam);

module.exports = router;
