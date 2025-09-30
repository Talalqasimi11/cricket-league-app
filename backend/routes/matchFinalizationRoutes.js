const express = require("express");
const router = express.Router();
const verifyToken = require("../middleware/authMiddleware");
const { finalizeMatch } = require("../controllers/matchFinalizationController");

// ✅ Only captain of the match can finalize
router.post("/finalize", verifyToken, finalizeMatch);

module.exports = router;
