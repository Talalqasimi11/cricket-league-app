const express = require("express");
const router = express.Router();
const { verifyToken: authMiddleware } = require("../middleware/authMiddleware");
const { validateSingleNumericParam } = require("../utils/inputValidation");

const {
  addTournamentTeam,
  getTournamentTeams,
  updateTournamentTeam,
  deleteTournamentTeam,
} = require("../controllers/tournamentTeamController");

// ✅ Routes - Aligned with PRD specification
router.post("/", authMiddleware, addTournamentTeam); // Add team to tournament
router.get("/:tournament_id", validateSingleNumericParam('tournament_id'), getTournamentTeams); // Get tournament teams (public)
router.put("/", authMiddleware, updateTournamentTeam); // Update tournament team (extended functionality)
router.delete("/", authMiddleware, deleteTournamentTeam); // Remove tournament team (extended functionality)

module.exports = router;
