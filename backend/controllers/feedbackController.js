const db = require("../config/db");

// Configurable profanity filter list (could be moved to env or config file)
const PROFANITY_LIST = process.env.PROFANITY_FILTER 
  ? process.env.PROFANITY_FILTER.split(',').map(w => w.trim().toLowerCase())
  : [
      'fuck', 'shit', 'bitch', 'asshole', 'bastard', 'cunt', 'dick',
      'damn', 'piss', 'cock', 'pussy', 'slut', 'whore', 'fag', 'nigger'
    ];

const MAX_FEEDBACK_LENGTH = 1000;
const MIN_FEEDBACK_LENGTH = 5;

const createFeedback = async (req, res) => {
  const userId = req.user?.id || null;
  const { message, contact } = req.body || {};
  
  // Validate message presence and normalize
  if (!message) {
    return res.status(400).json({ error: "Message is required" });
  }
  
  const normalized = String(message).trim().replace(/\s+/g, ' '); // normalize whitespace
  
  // Length validation
  if (normalized.length < MIN_FEEDBACK_LENGTH) {
    return res.status(400).json({ error: `Message must be at least ${MIN_FEEDBACK_LENGTH} characters` });
  }
  
  if (normalized.length > MAX_FEEDBACK_LENGTH) {
    return res.status(400).json({ error: `Message cannot exceed ${MAX_FEEDBACK_LENGTH} characters` });
  }
  
  // Profanity filter with word boundary checks to reduce false positives
  const lowered = normalized.toLowerCase();
  const foundBadWord = PROFANITY_LIST.find((word) => {
    // Use word boundaries to avoid false positives (e.g., "assignment" shouldn't trigger "ass")
    const regex = new RegExp(`\\b${word}\\b`, 'i');
    return regex.test(lowered);
  });
  
  if (foundBadWord) {
    // Log for abuse monitoring without revealing specific word
    const ipAddress = req.ip || req.socket?.remoteAddress || null;
    console.warn(`⚠️  Profanity detected in feedback from IP ${ipAddress}, user ${userId}`);
    return res.status(400).json({ error: "Inappropriate content detected. Please use respectful language." });
  }
  
  try {
    // Optional: check for spam/abuse by rate limiting per IP or user
    const ipAddress = req.ip || req.socket?.remoteAddress || null;
    const userAgent = req.headers['user-agent'] || null;
    
    await db.query(
      "INSERT INTO feedback (user_id, message, contact) VALUES (?, ?, ?)",
      [userId, normalized, contact ? String(contact).trim() : null]
    );
    
    return res.status(201).json({ message: "Feedback received. Thank you!" });
  } catch (err) {
    console.error("❌ Error in createFeedback:", err);
    return res.status(500).json({ error: "Server error" });
  }
};

module.exports = { createFeedback };
