const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");
const {
  createTournament,
  getTournaments,
  updateTournament,
  deleteTournament
} = require("../controllers/tournamentController");

// Protected routes
router.post("/create", authMiddleware, createTournament);
router.get("/", getTournaments);
router.put("/update", authMiddleware, updateTournament);
router.delete("/delete", authMiddleware, deleteTournament);

module.exports = router;
