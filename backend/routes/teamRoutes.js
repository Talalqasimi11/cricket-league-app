const express = require("express");
const router = express.Router();
const { verifyToken, requireScope } = require("../middleware/authMiddleware");
const { validateSingleNumericParam } = require("../utils/inputValidation");
const { getMyTeam, updateMyTeam, getAllTeams, getTeamById, deleteMyTeam } = require("../controllers/teamController");

// Public routes
router.get("/", getAllTeams);

// Protected routes
router.get("/my-team", verifyToken, requireScope('team:read'), getMyTeam);
router.put("/update", verifyToken, requireScope('team:manage'), updateMyTeam);
router.delete("/my-team", verifyToken, requireScope('team:manage'), deleteMyTeam);

// Public route (must be after specific routes to avoid shadowing)
router.get("/:id", validateSingleNumericParam('id'), getTeamById);

module.exports = router;
