// [file: routes/teamRoutes.js]
const express = require("express");
const router = express.Router();
const { verifyToken, requireScope } = require("../middleware/authMiddleware");
const { validateSingleNumericParam } = require("../utils/inputValidation");
const { createMyTeam, getMyTeam, updateMyTeam, getAllTeams, getTeamById, deleteMyTeam, createTemporaryTeam } = require("../controllers/teamController");

// Public routes
router.get("/", getAllTeams);

// ✅ Added: Create temporary/unregistered team (Authenticated)
router.post("/", verifyToken, requireScope('team:manage'), createTemporaryTeam);

// Protected routes
router.post("/my-team", verifyToken, requireScope('team:manage'), createMyTeam);
router.get("/my-team", verifyToken, requireScope('team:read'), getMyTeam);
router.put("/update", verifyToken, requireScope('team:manage'), updateMyTeam);
router.delete("/my-team", verifyToken, requireScope('team:manage'), deleteMyTeam);

// Public route (must be after specific routes)
router.get("/:id", validateSingleNumericParam('id'), getTeamById);

module.exports = router;