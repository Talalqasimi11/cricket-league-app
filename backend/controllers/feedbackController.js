const { db } = require("../config/db");

// ==========================================
// ⚙️ CONFIGURATION & CONSTANTS
// ==========================================

const CONFIG = {
  MIN_LENGTH: 5,
  MAX_LENGTH: 1000,
  // Simple rate limit: Max 3 feedback submissions per hour per user/IP
  RATE_LIMIT: {
    WINDOW_SECONDS: 3600, // 1 hour
    MAX_REQUESTS: 3
  }
};

// Initialize Profanity Filter (Pre-compiled for performance)
// Instead of looping through arrays on every request, we use one optimized Regex.
const PROFANITY_FILTER_ENABLED = process.env.PROFANITY_FILTER_ENABLED === 'true';

let profanityRegex = null;

if (PROFANITY_FILTER_ENABLED) {
  const rawList = process.env.PROFANITY_FILTER 
    ? process.env.PROFANITY_FILTER.split(',') 
    : ['spam', 'scam', 'fake', 'bot']; // Default sanitized list

  // Clean list and escape special regex characters just in case
  const cleanedList = rawList
    .map(w => w.trim().toLowerCase().replace(/[.*+?^${}()|[\]\\]/g, '\\$&'))
    .filter(w => w.length > 0);

  if (cleanedList.length > 0) {
    // Creates a single regex like: /\b(spam|scam|fake|bot)\b/i
    profanityRegex = new RegExp(`\\b(${cleanedList.join('|')})\\b`, 'i');
  }
}

// ==========================================
// 🛡️ HELPER FUNCTIONS
// ==========================================

/**
 * Checks if the user/IP is spamming feedback
 */
const checkRateLimit = async (userId, ipAddress) => {
  try {
    // Logic: If user is logged in, throttle by User ID. If not, throttle by IP.
    const query = userId 
      ? "SELECT COUNT(*) as count FROM feedback WHERE user_id = ? AND created_at > DATE_SUB(NOW(), INTERVAL ? SECOND)"
      : "SELECT COUNT(*) as count FROM feedback WHERE user_id IS NULL AND created_at > DATE_SUB(NOW(), INTERVAL ? SECOND)"; // Note: You'd need an IP column in DB to throttle anons effectively, assuming User ID for now.
    
    // Note: For production without an IP column in the feedback table, 
    // we strictly rate limit authenticated users. For anonymous, we might skip DB check or assume 0.
    const params = userId ? [userId, CONFIG.RATE_LIMIT.WINDOW_SECONDS] : null;

    if (!params) return true; // Skip check for anonymous if no IP tracking in DB

    const [[{ count }]] = await db.query(query, params);
    return Number(count) < CONFIG.RATE_LIMIT.MAX_REQUESTS;
  } catch (e) {
    // Fail open (allow request) if rate limit DB check fails to avoid blocking legitimate traffic on DB hiccup
    console.warn("Rate limit check failed:", e.message);
    return true;
  }
};

/**
 * Validates and sanitizes input payload
 */
const validateInput = (message) => {
  if (!message) return { valid: false, error: "Message is required" };

  // Normalize: Collapse multiple spaces to single space, trim
  const normalized = String(message).trim().replace(/\s+/g, ' ');

  if (normalized.length < CONFIG.MIN_LENGTH) {
    return { valid: false, error: `Message must be at least ${CONFIG.MIN_LENGTH} characters` };
  }

  if (normalized.length > CONFIG.MAX_LENGTH) {
    return { valid: false, error: `Message cannot exceed ${CONFIG.MAX_LENGTH} characters` };
  }

  if (profanityRegex && profanityRegex.test(normalized)) {
    return { valid: false, error: "Inappropriate content detected. Please use respectful language." };
  }

  return { valid: true, value: normalized };
};

// ==========================================
// 🎮 CONTROLLER
// ==========================================

const createFeedback = async (req, res) => {
  const userId = req.user?.id || null;
  const { message, contact } = req.body || {};
  
  // 1. Validation
  const validation = validateInput(message);
  if (!validation.valid) {
    // If profanity detected, log it internally for abuse monitoring
    if (validation.error.includes("Inappropriate")) {
      console.warn(`⚠️ Profanity detected. User: ${userId || 'Anon'}, IP: ${req.ip}`);
    }
    return res.status(400).json({ error: validation.error });
  }

  try {
    // 2. Rate Limiting (Prevent Spam)
    const isAllowed = await checkRateLimit(userId, req.ip);
    if (!isAllowed) {
      return res.status(429).json({ error: "You are sending feedback too quickly. Please try again later." });
    }

    // 3. Sanitization of optional fields
    const sanitizedContact = contact ? String(contact).trim().substring(0, 100) : null; // Cap contact length

    // 4. Database Insertion
    await db.query(
      "INSERT INTO feedback (user_id, message, contact) VALUES (?, ?, ?)",
      [userId, validation.value, sanitizedContact]
    );
    
    return res.status(201).json({ message: "Feedback received. Thank you!" });

  } catch (err) {
    console.error("createFeedback: Database error", { 
      message: err.message, 
      code: err.code, 
      userId,
      // Don't log full message payload to avoid polluting logs with potentially huge strings
    });
    return res.status(500).json({ error: "Server error" });
  }
};

module.exports = { createFeedback };