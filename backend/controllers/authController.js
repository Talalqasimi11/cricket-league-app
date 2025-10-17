const db = require("../config/db");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const crypto = require("crypto");
require("dotenv").config();

// ========================
// REGISTER CAPTAIN
// ========================
const registerCaptain = async (req, res) => {
    const { phone_number, password, team_name, team_location, team_logo_url } = req.body; // ✅ ADDED team_logo_url

  if (!phone_number || !password || !team_name || !team_location) {
    return res.status(400).json({ error: "All fields are required" });
  }

  // Basic phone and password validation (E.164-ish and min length)
  const phoneRegex = /^\+?[1-9]\d{7,14}$/;
  if (!phoneRegex.test(String(phone_number))) {
    return res.status(400).json({ error: "Invalid phone number format" });
  }
  if (String(password).length < 8) {
    return res.status(400).json({ error: "Password must be at least 8 characters" });
  }

  try {
    // Step 0: Check if phone number already exists
    const [existing] = await db.query(
      "SELECT id FROM users WHERE phone_number = ?",
      [phone_number]
    );
    if (existing.length > 0) {
      return res.status(409).json({ error: "Phone number already registered" });
    }

    // Step 1: Create owner (user)
    const passwordHash = await bcrypt.hash(password, 12);
    const [userResult] = await db.query(
      "INSERT INTO users (phone_number, password_hash) VALUES (?, ?)",
      [phone_number, passwordHash]
    );

    const ownerId = userResult.insertId;

    // Step 2: Create team linked with owner (also set historical captain_id for back-compat)
    // ✅ ADDED team_logo_url to the INSERT statement
    await db.query(
      "INSERT INTO teams (team_name, team_location, team_logo_url, matches_played, matches_won, trophies, owner_id) VALUES (?, ?, ?, 0, 0, 0, ?)",
      [team_name, team_location, team_logo_url || null, ownerId]
    );

    res.status(201).json({ message: "Owner and team registered successfully" });
  } catch (err) {
    console.error("❌ Error in registerCaptain:", err);
    if (err && err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: "Phone number already registered" });
    }
    res.status(500).json({ error: "Server error", details: err.message });
  }
};

// ========================
// LOGIN CAPTAIN
// ========================
const loginCaptain = async (req, res) => {
  const { phone_number, password } = req.body;

  if (!phone_number || !password) {
    return res.status(400).json({ error: "Phone number and password are required" });
  }

  try {
    // 0️⃣ Check for recent auth failures to implement progressive throttling
    const ipAddress = req.ip || req.socket?.remoteAddress || null;
    const [[{ failureCount }]] = await db.query(
      "SELECT COUNT(*) AS failureCount FROM auth_failures WHERE phone_number = ? AND failed_at > DATE_SUB(NOW(), INTERVAL 15 MINUTE)",
      [phone_number]
    );

    // Progressive lockout: More lenient in development/testing
    let requiredDelay = 0;
    const isDevelopment = process.env.NODE_ENV !== 'production';
    
    if (isDevelopment) {
      // Development: More lenient limits
      if (Number(failureCount) >= 20) {
        requiredDelay = 5 * 60 * 1000; // 5 minutes
      } else if (Number(failureCount) >= 10) {
        requiredDelay = 60 * 1000; // 1 minute
      } else if (Number(failureCount) >= 5) {
        requiredDelay = 30 * 1000; // 30 seconds
      }
    } else {
      // Production: Original strict limits
      if (Number(failureCount) >= 10) {
        requiredDelay = 30 * 60 * 1000; // 30 minutes
      } else if (Number(failureCount) >= 5) {
        requiredDelay = 5 * 60 * 1000; // 5 minutes
      } else if (Number(failureCount) >= 3) {
        requiredDelay = 60 * 1000; // 1 minute
      }
    }

    if (requiredDelay > 0) {
      const [[{ lastFailure }]] = await db.query(
        "SELECT UNIX_TIMESTAMP(MAX(failed_at)) * 1000 AS lastFailure FROM auth_failures WHERE phone_number = ?",
        [phone_number]
      );
      const timeSinceLastFailure = Date.now() - Number(lastFailure);
      if (timeSinceLastFailure < requiredDelay) {
        return res.status(429).json({ 
          error: "Too many failed login attempts. Please try again later.",
          retryAfter: Math.ceil((requiredDelay - timeSinceLastFailure) / 1000)
        });
      }
    }

    // 1️⃣ Find user
    const [rows] = await db.query(
      "SELECT * FROM users WHERE phone_number = ?",
      [phone_number]
    );

    if (rows.length === 0) {
      // Log failed attempt (no user found)
      await db.query(
        "INSERT INTO auth_failures (phone_number, ip_address, user_agent) VALUES (?, ?, ?)",
        [phone_number, ipAddress, req.headers['user-agent'] || null]
      );
      return res.status(404).json({ error: "User not found" });
    }

    const user = rows[0];

    // 2️⃣ Check password with bcrypt
    const passwordOk = await bcrypt.compare(password, user.password_hash || "");
    if (!passwordOk) {
      // Log failed password attempt
      await db.query(
        "INSERT INTO auth_failures (phone_number, ip_address, user_agent) VALUES (?, ?, ?)",
        [phone_number, ipAddress, req.headers['user-agent'] || null]
      );
      return res.status(401).json({ error: "Invalid credentials" });
    }

    // 3️⃣ SUCCESS - Clear auth failures for this phone number
    await db.query("DELETE FROM auth_failures WHERE phone_number = ?", [phone_number]);

    // 4️⃣ Create short-lived access token and long-lived refresh token
    const jwtPayload = { sub: user.id, phone_number: user.phone_number, iss: process.env.JWT_ISS, aud: process.env.JWT_AUD };
    const accessToken = jwt.sign(jwtPayload, process.env.JWT_SECRET, { expiresIn: "15m" });
    const refreshToken = jwt.sign({ sub: user.id, type: "refresh", iss: process.env.JWT_ISS, aud: process.env.JWT_AUD }, process.env.JWT_REFRESH_SECRET, { expiresIn: "7d" });

    // 5️⃣ Persist refresh token (basic blacklist table)
    await db.query("INSERT INTO refresh_tokens (user_id, token, is_revoked) VALUES (?, ?, 0)", [user.id, refreshToken]);

    // 6️⃣ Set httpOnly cookie with env-based security flags
    // Use sameSite: 'none' for cross-site flows (mobile/web); requires secure: true
    const isSecure = process.env.NODE_ENV === "production" || String(process.env.COOKIE_SECURE).toLowerCase() === "true";
    res.cookie("refresh_token", refreshToken, {
      httpOnly: true,
      secure: isSecure,
      sameSite: isSecure ? "none" : "lax", // 'none' requires secure; fallback to 'lax' for local dev
      path: "/api/auth",
      maxAge: 7 * 24 * 60 * 60 * 1000,
    });

    // 7️⃣ Respond access token and refresh token (for mobile clients)
    res.json({
      message: "Login successful",
      token: accessToken,
      refresh_token: refreshToken,
      user: { id: user.id, phone_number: user.phone_number },
    });
  } catch (err) {
    req.log?.error(err);
    res.status(500).json({ error: "Server error", details: err.message });
  }
};

// ========================
// REFRESH ACCESS TOKEN
// ========================
const refreshToken = async (req, res) => {
  // Accept refresh token from httpOnly cookie OR request body for mobile clients
  const tokenFromCookie = req.cookies && req.cookies.refresh_token;
  const tokenFromBody = req.body && req.body.refresh_token;
  const presented = tokenFromCookie || tokenFromBody;
  if (!presented) {
    return res.status(401).json({ error: "Refresh token missing" });
  }

  try {
    // Verify token signature and claims
    const payload = jwt.verify(presented, process.env.JWT_REFRESH_SECRET, {
      clockTolerance: 5,
      audience: process.env.JWT_AUD,
      issuer: process.env.JWT_ISS,
    });

    // Check not revoked
    const [rows] = await db.query("SELECT id, is_revoked, user_id FROM refresh_tokens WHERE token = ?", [presented]);
    if (rows.length === 0 || rows[0].is_revoked) {
      return res.status(401).json({ error: "Invalid refresh token" });
    }

    const userId = rows[0].user_id;

    // Optionally rotate refresh token (not enforced yet; returned when present)
    const rotate = String(process.env.ROTATE_REFRESH_ON_USE || '').toLowerCase() === 'true';
    let newRefresh = null;
    if (rotate) {
      // revoke old
      await db.query("UPDATE refresh_tokens SET is_revoked = 1, revoked_at = NOW() WHERE token = ?", [presented]);
      // issue new
      newRefresh = jwt.sign({ sub: userId, type: "refresh", iss: process.env.JWT_ISS, aud: process.env.JWT_AUD }, process.env.JWT_REFRESH_SECRET, { expiresIn: "7d" });
      await db.query("INSERT INTO refresh_tokens (user_id, token, is_revoked) VALUES (?, ?, 0)", [userId, newRefresh]);
      const isSecure = process.env.NODE_ENV === "production" || String(process.env.COOKIE_SECURE).toLowerCase() === "true";
      res.cookie("refresh_token", newRefresh, {
        httpOnly: true,
        secure: isSecure,
        sameSite: isSecure ? "none" : "lax", // 'none' requires secure; fallback to 'lax' for local dev
        path: "/api/auth",
        maxAge: 7 * 24 * 60 * 60 * 1000,
      });
    }

    const accessToken = jwt.sign({ sub: userId, iss: process.env.JWT_ISS, aud: process.env.JWT_AUD }, process.env.JWT_SECRET, { expiresIn: "15m" });
    return res.json(newRefresh ? { token: accessToken, refresh_token: newRefresh } : { token: accessToken });
  } catch (err) {
    if (err && err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: "Refresh token expired" });
    }
    return res.status(401).json({ error: "Invalid refresh token" });
  }
};

// ========================
// LOGOUT - revoke refresh tokens
// ========================
const logout = async (req, res) => {
  const tokenFromCookie = req.cookies && req.cookies.refresh_token;
  const tokenFromBody = req.body && req.body.refresh_token;
  try {
    if (tokenFromCookie) {
      await db.query("UPDATE refresh_tokens SET is_revoked = 1, revoked_at = NOW() WHERE token = ?", [tokenFromCookie]);
    }
    if (tokenFromBody) {
      await db.query("UPDATE refresh_tokens SET is_revoked = 1, revoked_at = NOW() WHERE token = ?", [tokenFromBody]);
    }
    res.clearCookie("refresh_token", { path: "/api/auth" });
    return res.status(200).json({ message: "Logged out" });
  } catch (err) {
    req.log?.error(err);
    return res.status(500).json({ error: "Server error" });
  }
};

// ========================
// PASSWORD RESET FLOW
// ========================
const requestPasswordReset = async (req, res) => {
  const { phone_number } = req.body || {};
  if (!phone_number) {
    return res.status(400).json({ error: "Phone number is required" });
  }

  try {
    const [users] = await db.query("SELECT id FROM users WHERE phone_number = ?", [phone_number]);
    if (users.length === 0) {
      // Respond success to avoid user enumeration
      return res.json({ message: "If the account exists, a reset was initiated" });
    }
    const userId = users[0].id;

    // Throttle: max 1 request per 15 minutes per user
    const [[{ cnt }]] = await db.query(
      "SELECT COUNT(*) AS cnt FROM password_resets WHERE user_id = ? AND created_at > DATE_SUB(NOW(), INTERVAL 15 MINUTE)",
      [userId]
    );
    if (Number(cnt) >= 1) {
      return res.status(429).json({ error: "Too many requests. Please try again later." });
    }

    // Invalidate any active tokens (single-active token policy)
    await db.query("UPDATE password_resets SET used_at = NOW() WHERE user_id = ? AND used_at IS NULL AND expires_at > NOW()", [userId]);

    const rawToken = crypto.randomBytes(24).toString("hex");
    const tokenHash = await bcrypt.hash(rawToken, 12);
    const expiresMinutes = 15;
    await db.query(
      "INSERT INTO password_resets (user_id, token_hash, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? MINUTE))",
      [userId, tokenHash, expiresMinutes]
    );

    // In production, send via SMS/Email. For development, return token for UX testing
    return res.json({ message: "Reset initiated", token: rawToken });
  } catch (err) {
    req.log?.error(err);
    return res.status(500).json({ error: "Server error" });
  }
};

const verifyPasswordReset = async (req, res) => {
  const { phone_number, token } = req.body || {};
  if (!phone_number || !token) {
    return res.status(400).json({ error: "phone_number and token are required" });
  }
  try {
    const [users] = await db.query("SELECT id FROM users WHERE phone_number = ?", [phone_number]);
    if (users.length === 0) return res.status(400).json({ error: "Invalid reset token" });
    const userId = users[0].id;

    const [rows] = await db.query(
      "SELECT id, token_hash FROM password_resets WHERE user_id = ? AND used_at IS NULL AND expires_at > NOW() ORDER BY id DESC LIMIT 1",
      [userId]
    );
    if (rows.length === 0) return res.status(400).json({ error: "Invalid or expired reset token" });
    const ok = await bcrypt.compare(token, rows[0].token_hash || "");
    if (!ok) return res.status(400).json({ error: "Invalid or expired reset token" });
    return res.json({ valid: true });
  } catch (err) {
    req.log?.error(err);
    return res.status(500).json({ error: "Server error" });
  }
};

const confirmPasswordReset = async (req, res) => {
  const { phone_number, token, new_password } = req.body || {};
  if (!phone_number || !token || !new_password) {
    return res.status(400).json({ error: "phone_number, token and new_password are required" });
  }
  if (String(new_password).length < 8) {
    return res.status(400).json({ error: "Password must be at least 8 characters" });
  }
  try {
    const [users] = await db.query("SELECT id FROM users WHERE phone_number = ?", [phone_number]);
    if (users.length === 0) return res.status(400).json({ error: "Invalid reset token" });
    const userId = users[0].id;

    const [rows] = await db.query(
      "SELECT id, token_hash FROM password_resets WHERE user_id = ? AND used_at IS NULL AND expires_at > NOW() ORDER BY id DESC LIMIT 1",
      [userId]
    );
    if (rows.length === 0) return res.status(400).json({ error: "Invalid or expired reset token" });
    const resetRow = rows[0];
    const ok = await bcrypt.compare(token, resetRow.token_hash || "");
    if (!ok) return res.status(400).json({ error: "Invalid or expired reset token" });

    const newHash = await bcrypt.hash(new_password, 12);
    await db.query("UPDATE users SET password_hash = ? WHERE id = ?", [newHash, userId]);
    await db.query("UPDATE password_resets SET used_at = NOW() WHERE id = ?", [resetRow.id]);
    await db.query("UPDATE refresh_tokens SET is_revoked = 1, revoked_at = NOW() WHERE user_id = ? AND is_revoked = 0", [userId]);

    return res.json({ message: "Password reset successful" });
  } catch (err) {
    req.log?.error(err);
    return res.status(500).json({ error: "Server error" });
  }
};

// ========================
// ACCOUNT MANAGEMENT
// ========================
const changePassword = async (req, res) => {
  const userId = req.user && req.user.id;
  const { current_password, new_password } = req.body || {};
  if (!userId) return res.status(401).json({ error: "Unauthorized" });
  if (!current_password || !new_password) return res.status(400).json({ error: "current_password and new_password are required" });
  if (String(new_password).length < 8) return res.status(400).json({ error: "Password must be at least 8 characters" });

  try {
    const [rows] = await db.query("SELECT password_hash FROM users WHERE id = ?", [userId]);
    if (rows.length === 0) return res.status(404).json({ error: "User not found" });
    const ok = await bcrypt.compare(current_password, rows[0].password_hash || "");
    if (!ok) return res.status(401).json({ error: "Current password is incorrect" });

    const hash = await bcrypt.hash(new_password, 12);
    await db.query("UPDATE users SET password_hash = ? WHERE id = ?", [hash, userId]);
    await db.query("UPDATE refresh_tokens SET is_revoked = 1, revoked_at = NOW() WHERE user_id = ? AND is_revoked = 0", [userId]);
    return res.json({ message: "Password changed" });
  } catch (err) {
    req.log?.error(err);
    return res.status(500).json({ error: "Server error" });
  }
};

const changePhoneNumber = async (req, res) => {
  const userId = req.user && req.user.id;
  const { new_phone_number } = req.body || {};
  if (!userId) return res.status(401).json({ error: "Unauthorized" });
  const phoneRegex = /^\+?[1-9]\d{7,14}$/;
  if (!new_phone_number || !phoneRegex.test(String(new_phone_number))) {
    return res.status(400).json({ error: "Invalid phone number format" });
  }
  try {
    const [exists] = await db.query("SELECT id FROM users WHERE phone_number = ? AND id <> ?", [new_phone_number, userId]);
    if (exists.length > 0) return res.status(409).json({ error: "Phone number already in use" });
    await db.query("UPDATE users SET phone_number = ? WHERE id = ?", [new_phone_number, userId]);
    return res.json({ message: "Phone number updated", phone_number: new_phone_number });
  } catch (err) {
    req.log?.error(err);
    return res.status(500).json({ error: "Server error" });
  }
};

// ========================
// TEST CLEANUP (Development only)
// ========================
const clearAuthFailures = async (req, res) => {
  if (process.env.NODE_ENV === 'production') {
    return res.status(404).json({ error: 'Not found' });
  }
  
  try {
    await db.query("DELETE FROM auth_failures WHERE failed_at < DATE_SUB(NOW(), INTERVAL 1 HOUR)");
    res.json({ message: "Auth failures cleared" });
  } catch (err) {
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = { registerCaptain, loginCaptain, refreshToken, logout, requestPasswordReset, verifyPasswordReset, confirmPasswordReset, changePassword, changePhoneNumber, clearAuthFailures };
