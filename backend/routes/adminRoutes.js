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
  deleteTeam,
  getAllTournaments,
  deleteTournament,
  createMatch,
  getAllMatches,
  getMatchDetails,
  updateMatch,
  deleteMatch,
} = require("../controllers/adminController");

// Apply authentication and authorization middleware to all admin routes
router.use(verifyToken);
router.use(requireAdmin);

// ========================
// DASHBOARD
// ========================
router.get("/dashboard", getDashboardStats);

// ========================
// USER MANAGEMENT
// ========================
router.get("/users", getAllUsers);
router.put("/users/:userId/admin", updateUserAdminStatus);
router.delete("/users/:userId", deleteUser);

// ========================
// TEAM MANAGEMENT
// ========================
router.get("/teams", getAllTeams);
router.get("/teams/:teamId", getTeamDetails);
router.put("/teams/:teamId", updateTeam);
router.delete("/teams/:teamId", deleteTeam);

// ========================
// TOURNAMENT MANAGEMENT
// ========================
router.get("/tournaments", getAllTournaments);
router.delete("/tournaments/:tournamentId", deleteTournament);

// ========================
// MATCH MANAGEMENT
// ========================
router.post("/matches", createMatch);           // Create new match
router.get("/matches", getAllMatches);          // List all matches (live/completed/upcoming)
router.get("/matches/:matchId", getMatchDetails); // Get specific match details
router.put("/matches/:matchId", updateMatch);     // Force update (status/overs)
router.delete("/matches/:matchId", deleteMatch);  // Delete match

module.exports = router;