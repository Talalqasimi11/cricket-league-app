const pool = require("../config/db");

const createFeedback = async (req, res) => {
  const userId = req.user?.id || null;
  const { message, contact } = req.body || {};
  if (!message || String(message).trim().length < 5) {
    return res.status(400).json({ error: "Message is too short" });
  }
  // Basic profanity/length guard
  const lowered = String(message).toLowerCase();
  const banned = ["shit", "fuck"];
  if (banned.some((w) => lowered.includes(w))) {
    return res.status(400).json({ error: "Inappropriate content" });
  }
  try {
    await pool.query(
      "INSERT INTO feedback (user_id, message, contact) VALUES (?, ?, ?)",
      [userId, String(message).trim(), contact ? String(contact).trim() : null]
    );
    return res.status(201).json({ message: "Feedback received" });
  } catch (err) {
    console.error("❌ Error in createFeedback:", err);
    return res.status(500).json({ error: "Server error" });
  }
};

module.exports = { createFeedback };
