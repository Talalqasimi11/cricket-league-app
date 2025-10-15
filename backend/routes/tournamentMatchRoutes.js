const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");
const {
  getAllTournamentMatches,
  createTournamentMatches,
  getTournamentMatches,
  updateTournamentMatch,
  startTournamentMatch,
  endTournamentMatch,
  deleteTournamentMatch
} = require("../controllers/tournamentMatchController");

// ✅ Routes
router.get("/", getAllTournamentMatches); // public list across tournaments
router.post("/create", authMiddleware, createTournamentMatches);
router.get("/:tournament_id", getTournamentMatches);
router.put("/update/:id", authMiddleware, updateTournamentMatch);
router.put("/start/:id", authMiddleware, startTournamentMatch);
router.put("/end/:id", authMiddleware, endTournamentMatch);
router.delete("/delete/:id", authMiddleware, deleteTournamentMatch);

module.exports = router;
