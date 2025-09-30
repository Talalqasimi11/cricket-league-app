const express = require("express");
const router = express.Router();
const verifyToken = require("../middleware/authMiddleware");
const {
  getInningsByMatch,
  getInningById,
  updateInnings,
  deleteInnings,
} = require("../controllers/matchInningsController");

// Public
router.get("/match/:match_id", getInningsByMatch);
router.get("/:id", getInningById);

// Protected (captain/admin)
router.put("/:id", verifyToken, updateInnings);
router.delete("/:id", verifyToken, deleteInnings);

module.exports = router;
