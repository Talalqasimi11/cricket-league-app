const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");

const {
  addTournamentTeam,
  getTournamentTeams,
  updateTournamentTeam,
  deleteTournamentTeam,
} = require("../controllers/tournamentTeamController");

// ✅ Routes
router.post("/add", authMiddleware, addTournamentTeam);
router.get("/:tournament_id", getTournamentTeams); // public
router.put("/update", authMiddleware, updateTournamentTeam);
router.delete("/delete", authMiddleware, deleteTournamentTeam);

module.exports = router;
