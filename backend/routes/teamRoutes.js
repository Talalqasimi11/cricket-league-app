const express = require("express");
const router = express.Router();
const { verifyToken } = require("../middleware/authMiddleware");
const { getMyTeam, updateMyTeam, getAllTeams, getTeamById } = require("../controllers/teamController");

// Public route
router.get("/all", getAllTeams);
router.get("/:id", getTeamById);

// Protected routes
router.get("/my-team", (req, res, next) => {
  console.log("🔍 Route /my-team hit!");
  next();
}, verifyToken, getMyTeam);
router.put("/update", verifyToken, updateMyTeam);

module.exports = router;
