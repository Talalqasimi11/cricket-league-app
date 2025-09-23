const express = require("express");
const router = express.Router();
const matchController = require("../controllers/matchController");
const verifyToken = require("../middleware/authMiddleware");

router.post("/create", verifyToken, matchController.createMatch);
router.get("/", matchController.getAllMatches);

module.exports = router;
