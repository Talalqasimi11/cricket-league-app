const router = require("express").Router();
const statsController = require("../controllers/tournamentStatsController");
// const { verifyToken } = require("../middleware/authMiddleware"); 
// Optional: Add auth middleware if you want stats to be private

// Routes for Tournament Stats
router.get("/:tournamentId/batting", statsController.getTopScorers);
router.get("/:tournamentId/bowling", statsController.getTopWicketTakers);
router.get("/:tournamentId/sixes", statsController.getSixesLeaderboard);
router.get("/:tournamentId/summary", statsController.getTournamentSummary);

module.exports = router;