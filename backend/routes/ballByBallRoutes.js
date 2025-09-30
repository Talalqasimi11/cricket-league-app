const express = require("express");
const router = express.Router();
const BallByBallController = require("../controllers/BallByBallController");
const verifyToken = require("../middleware/authMiddleware");

// Record a delivery (scorer only)
router.post("/", verifyToken, BallByBallController.addDelivery);

// Fetch deliveries of a match
router.get("/match/:match_id", BallByBallController.getDeliveriesByMatch);

// Fetch deliveries of an innings
router.get("/innings/:innings_id", BallByBallController.getDeliveriesByInnings);

// Delete a delivery (admin only)
router.delete("/:delivery_id", verifyToken, BallByBallController.deleteDelivery);

module.exports = router;
