const express = require("express");
const router = express.Router();
const { getTournamentSummary } = require("../controllers/teamTournamentSummaryController");

// ✅ Public (anyone can see points table)
router.get("/:tournament_id", getTournamentSummary);

module.exports = router;
