const express = require("express");
const router = express.Router();
const {
  getPlayerStatsByMatch,
  getPlayerStatsByTournament,
} = require("../controllers/playerMatchStatsController");

// 📌 Player stats per match
router.get("/match/:match_id", getPlayerStatsByMatch);

// 📌 Player stats per tournament
router.get("/tournament/:tournament_id", getPlayerStatsByTournament);

module.exports = router;
