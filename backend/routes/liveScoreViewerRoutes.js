const express = require("express");
const router = express.Router();
const { getLiveScoreViewer } = require("../controllers/liveScoreViewerController");

// Public route: viewer can see live score
router.get("/:match_id", getLiveScoreViewer);

module.exports = router;
