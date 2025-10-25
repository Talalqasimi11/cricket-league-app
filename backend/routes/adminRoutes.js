const express = require("express");
const router = express.Router();
const { verifyToken, requireAdmin } = require("../middleware/authMiddleware");
const {
  getDashboardStats,
  getAllUsers,
  updateUserAdminStatus,
  deleteUser,
  getAllTeams,
  getTeamDetails,
  updateTeam,
  deleteTeam
} = require("../controllers/adminController");

// Apply authentication and admin authorization to all routes
router.use(verifyToken);
router.use(requireAdmin);

// Dashboard routes
router.get("/dashboard", getDashboardStats);

// User management routes
router.get("/users", getAllUsers);
router.put("/users/:userId/admin", updateUserAdminStatus);
router.delete("/users/:userId", deleteUser);

// Team management routes
router.get("/teams", getAllTeams);
router.get("/teams/:teamId", getTeamDetails);
router.put("/teams/:teamId", updateTeam);
router.delete("/teams/:teamId", deleteTeam);

module.exports = router;
