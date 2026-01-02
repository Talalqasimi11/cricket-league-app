const express = require("express");
const router = express.Router();
const { verifyToken: authMiddleware } = require("../middleware/authMiddleware");
const { validateSingleNumericParam } = require("../utils/inputValidation");
const {
  getAllTournamentMatches,
  createTournamentMatches,
  getTournamentMatches,
  getTournamentMatchById,
  updateTournamentMatch,
  startTournamentMatch,
  endTournamentMatch,
  deleteTournamentMatch,
  generateBracket, // Import this
  createFriendlyMatch,
  createManualMatch
} = require("../controllers/tournamentMatchController");
// ... existing routes ...

// ✅ New route for Friendly Matches
router.post("/friendly", authMiddleware, createFriendlyMatch);
router.post("/manual", authMiddleware, createManualMatch);

// ✅ Routes
router.get("/", getAllTournamentMatches); // public list across tournaments
router.post("/create", authMiddleware, createTournamentMatches);
router.get("/match/:id", validateSingleNumericParam('id'), getTournamentMatchById);
router.get("/:tournament_id", validateSingleNumericParam('tournament_id'), getTournamentMatches);
router.put("/update/:id", authMiddleware, validateSingleNumericParam('id'), updateTournamentMatch);
router.put("/start/:id", authMiddleware, validateSingleNumericParam('id'), startTournamentMatch);
router.put("/end/:id", authMiddleware, validateSingleNumericParam('id'), endTournamentMatch);
router.delete("/delete/:id", authMiddleware, validateSingleNumericParam('id'), deleteTournamentMatch);
router.post("/generate-bracket/:id", authMiddleware, validateSingleNumericParam('id'), generateBracket);

module.exports = router;
