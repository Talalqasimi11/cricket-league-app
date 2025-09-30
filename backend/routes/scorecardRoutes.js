const express = require("express");
const router = express.Router();
const { getMatchScorecard } = require("../controllers/scorecardController");

// Public route to view full scorecard after match
router.get("/:match_id", getMatchScorecard);

module.exports = router;
