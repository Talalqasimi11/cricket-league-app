const express = require("express");
const router = express.Router();
const { getStatsOverview, getPlayerStats, getTeamStats } = require("../controllers/statsController");

// 📊 Statistics overview for dashboard
router.get("/overview", getStatsOverview);

// 📊 Detailed player statistics
router.get("/players", getPlayerStats);

// 📊 Detailed team statistics
router.get("/teams", getTeamStats);

// 📊 Tournament statistics (placeholder for future expansion)
router.get("/tournaments", getStatsOverview);

// 📊 Match statistics (placeholder for future expansion)
router.get("/matches", getStatsOverview);

module.exports = router;
