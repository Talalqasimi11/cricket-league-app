const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");

const {
  addTournamentTeam,
  getTournamentTeams,
  deleteTournamentTeam,
  updateTournamentTeam, // ✅ imported
} = require("../controllers/tournamentTeamController");

// ✅ Routes
router.post("/add", authMiddleware, addTournamentTeam);
router.get("/:tournament_id", getTournamentTeams);
router.delete("/delete", authMiddleware, deleteTournamentTeam);
router.put("/update", authMiddleware, updateTournamentTeam);

module.exports = router;
