const router = require("express").Router();
const summaryController = require("../controllers/matchSummaryController");

router.get("/:matchId/summary-card", summaryController.getMatchSummaryCard);

module.exports = router;