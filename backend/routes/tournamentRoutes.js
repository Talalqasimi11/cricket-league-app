const express = require("express");
const router = express.Router();
const { verifyToken: authMiddleware, requireScope } = require("../middleware/authMiddleware");
const {
  createTournament,
  getTournaments,
  updateTournament,
  deleteTournament,
  startTournament
} = require("../controllers/tournamentController");

// Tournament routes following REST conventions
router.post("/", authMiddleware, requireScope('tournament:manage'), createTournament);
router.get("/", getTournaments);
router.put("/:id", authMiddleware, requireScope('tournament:manage'), updateTournament);
router.put("/:id/start", authMiddleware, requireScope('tournament:manage'), startTournament);
router.delete("/:id", authMiddleware, requireScope('tournament:manage'), deleteTournament);

// Legacy aliases for backward compatibility
router.post("/create", authMiddleware, requireScope('tournament:manage'), createTournament);
router.put("/update", authMiddleware, requireScope('tournament:manage'), updateTournament);
router.delete("/delete", authMiddleware, requireScope('tournament:manage'), deleteTournament);

module.exports = router;
