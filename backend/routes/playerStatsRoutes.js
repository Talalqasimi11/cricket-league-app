const express = require("express");
const router = express.Router();
const {
  getTopRunScorers,
  getTopWicketTakers,
  getPlayerStats,
} = require("../controllers/playerStatsController");

// ✅ Leaderboards
router.get("/:tournament_id/top-runs", getTopRunScorers);
router.get("/:tournament_id/top-wickets", getTopWicketTakers);

// ✅ Player full stats
router.get("/:tournament_id/player/:player_id", getPlayerStats);

module.exports = router;
