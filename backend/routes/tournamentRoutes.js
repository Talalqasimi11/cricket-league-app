const express = require("express");
const router = express.Router();
const { verifyToken: authMiddleware, requireScope } = require("../middleware/authMiddleware");
const {
  createTournament,
  getTournaments,
  getTournamentById,
  updateTournament,
  deleteTournament,
  startTournament
} = require("../controllers/tournamentController");
const { addBulkTournamentTeams } = require("../controllers/tournamentTeamController");

// Tournament routes following REST conventions
router.post("/", authMiddleware, requireScope('tournament:manage'), createTournament);
router.get("/", getTournaments);
router.get("/:id", getTournamentById);
router.put("/:id", authMiddleware, requireScope('tournament:manage'), updateTournament);
router.put("/:id/start", authMiddleware, requireScope('tournament:manage'), startTournament);
router.delete("/:id", authMiddleware, requireScope('tournament:manage'), deleteTournament);

// Nested route for adding teams to a tournament (RESTful endpoint)
// POST /api/tournaments/:id/teams with body: { team_ids: [...] }
router.post("/:id/teams", authMiddleware, requireScope('tournament:manage'), (req, res, next) => {
  // Extract tournament_id from URL params and merge with body
  req.body.tournament_id = req.params.id;
  // Call the bulk add controller
  addBulkTournamentTeams(req, res, next);
});

// Legacy aliases for backward compatibility
router.post("/create", authMiddleware, requireScope('tournament:manage'), createTournament);
router.put("/update", authMiddleware, requireScope('tournament:manage'), updateTournament);
router.delete("/delete", authMiddleware, requireScope('tournament:manage'), deleteTournament);

module.exports = router;
