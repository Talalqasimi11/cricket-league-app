const express = require("express");
const router = express.Router();
const { verifyToken: authMiddleware } = require("../middleware/authMiddleware");
const { validateSingleNumericParam } = require("../utils/inputValidation");
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
router.get("/:tournament_id", validateSingleNumericParam('tournament_id'), getTournamentMatches);
router.put("/update/:id", authMiddleware, validateSingleNumericParam('id'), updateTournamentMatch);
router.put("/start/:id", authMiddleware, validateSingleNumericParam('id'), startTournamentMatch);
router.put("/end/:id", authMiddleware, validateSingleNumericParam('id'), endTournamentMatch);
router.delete("/delete/:id", authMiddleware, validateSingleNumericParam('id'), deleteTournamentMatch);

module.exports = router;
