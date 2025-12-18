const express = require("express");
const router = express.Router();
const { verifyToken, requireScope } = require("../middleware/authMiddleware");
const { validateSingleNumericParam } = require("../utils/inputValidation");
const { addPlayer, getMyPlayers, updatePlayer, deletePlayer, getPlayersByTeamId, getPlayers } = require("../controllers/playerController");

// Public
router.get("/team/:team_id", validateSingleNumericParam('team_id'), getPlayersByTeamId);
router.get("/", getPlayers);

// Protected routes
router.post("/", verifyToken, requireScope('player:manage'), addPlayer);
router.get("/my-players", verifyToken, requireScope('player:read'), getMyPlayers);
router.put("/:id", verifyToken, requireScope('player:manage'), validateSingleNumericParam('id'), updatePlayer);
router.delete("/:id", verifyToken, requireScope('player:manage'), validateSingleNumericParam('id'), deletePlayer);

module.exports = router;
