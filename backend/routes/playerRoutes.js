const express = require("express");
const router = express.Router();
const verifyToken = require("../middleware/authMiddleware");
const { addPlayer, getMyPlayers, updatePlayer, deletePlayer, getPlayersByTeamId } = require("../controllers/playerController");

// Public
router.get("/by-team/:team_id", getPlayersByTeamId);

// Protected routes
router.post("/add", verifyToken, addPlayer);
router.get("/my-players", verifyToken, getMyPlayers);
router.put("/update", verifyToken, updatePlayer);
router.delete("/delete", verifyToken, deletePlayer);

module.exports = router;
