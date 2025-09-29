const express = require("express");
const router = express.Router();
const { createMatch } = require("../controllers/matchController");
const authMiddleware = require("../middleware/authMiddleware");

// Only logged-in captains can create matches
router.post("/create", authMiddleware, createMatch);

module.exports = router;
