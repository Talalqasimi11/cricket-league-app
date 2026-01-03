const { db } = require("../config/db");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const crypto = require("crypto");
const { getUserFriendlyMessage, mapDatabaseError } = require("../utils/errorMessages");
const { validateTeamLogoUrl } = require("../utils/urlValidation"); // Kept if needed for future profile updates
require("dotenv").config();

// Auth throttling constants (PRD-compliant)
const AUTH_THROTTLING = {
  WINDOW_MINUTES: 15,
  THRESHOLDS: {
    LEVEL_1: { failures: 3, delayMinutes: 1 },
    LEVEL_2: { failures: 5, delayMinutes: 5 },
    LEVEL_3: { failures: 10, delayMinutes: 30 }
  }
};

// Helper: Generate Access & Refresh Tokens
const generateTokens = (user) => {
  const isAdmin = user.is_admin || false;
  const roles = ['captain'];
  const scopes = ['team:read', 'team:manage', 'match:score', 'player:read', 'player:manage', 'tournament:manage'];

  if (isAdmin) {
    roles.push('admin');
    scopes.push('admin:manage', 'user:manage', 'team:admin');
  }

  const jwtPayload = {
    sub: user.id,
    phone_number: user.phone_number,
    email: user.email,
    roles: roles,
    scopes: scopes,
    typ: 'access',
    iss: process.env.JWT_ISS,
    aud: process.env.JWT_AUD
  };

  const accessToken = jwt.sign(jwtPayload, process.env.JWT_SECRET, { expiresIn: "1500m" });
  const refreshToken = jwt.sign(
    { sub: user.id, typ: "refresh", iss: process.env.JWT_ISS, aud: process.env.JWT_AUD },
    process.env.JWT_REFRESH_SECRET,
    { expiresIn: "700d" }
  );

  return { accessToken, refreshToken };
};

// Helper: Set Cookies
const setAuthCookies = (res, refreshToken, csrfToken) => {
  const isSecure = process.env.NODE_ENV === "production" || String(process.env.COOKIE_SECURE).toLowerCase() === "true";

  res.cookie("refresh_token", refreshToken, {
    httpOnly: true,
    secure: isSecure,
    sameSite: isSecure ? "none" : "lax",
    path: "/",
    maxAge: 700 * 24 * 60 * 60 * 1000, // 7 days
  });

  res.cookie("csrf-token", csrfToken, {
    httpOnly: false,
    secure: isSecure,
    sameSite: "lax",
    path: "/",
    maxAge: 700 * 24 * 60 * 60 * 1000,
  });
};

// ========================
// REGISTER CAPTAIN
// ========================
const registerCaptain = async (req, res) => {
  const { phone_number, email, password } = req.body;

  // Input Validation
  if (!password) return res.status(400).json({ error: "Password is required" });
  if (!phone_number && !email) return res.status(400).json({ error: "Either phone number or email is required" });
  if (phone_number && email) return res.status(400).json({ error: "Provide either phone number OR email, not both" });
  if (String(password).length < 8) return res.status(400).json({ error: getUserFriendlyMessage("AUTH_WEAK_PASSWORD") });

  if (phone_number) {
    const phoneRegex = /^\+?[1-9]\d{7,14}$/;
    if (!phoneRegex.test(String(phone_number))) return res.status(400).json({ error: getUserFriendlyMessage("AUTH_INVALID_PHONE") });
  }

  if (email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(String(email))) return res.status(400).json({ error: "Invalid email format" });
  }

  try {
    // Check Existence
    let existingQuery = phone_number ? "SELECT id FROM users WHERE phone_number = ?" : "SELECT id FROM users WHERE email = ?";
    let existingParams = phone_number ? [phone_number] : [email];

    const [existing] = await db.query(existingQuery, existingParams);
    if (existing.length > 0) {
      return res.status(409).json({
        error: phone_number ? getUserFriendlyMessage("AUTH_PHONE_ALREADY_EXISTS") : "Email already registered"
      });
    }

    // Create User
    const passwordHash = await bcrypt.hash(password, 12);
    const insertQuery = phone_number
      ? "INSERT INTO users (phone_number, password_hash) VALUES (?, ?)"
      : "INSERT INTO users (email, password_hash) VALUES (?, ?)";

    const [userResult] = await db.query(insertQuery, [phone_number || email, passwordHash]);
    const ownerId = userResult.insertId;

    // Fetch full user for token generation (need is_admin)
    const [userRows] = await db.query("SELECT * FROM users WHERE id = ?", [ownerId]);
    const newUser = userRows[0];

    // Issue Tokens
    const { accessToken, refreshToken } = generateTokens(newUser);
    const csrfToken = crypto.randomBytes(32).toString('hex');

    await db.query("INSERT INTO refresh_tokens (user_id, token, is_revoked) VALUES (?, ?, 0)", [ownerId, refreshToken]);
    setAuthCookies(res, refreshToken, csrfToken);

    // Response
    const response = {
      message: "Registration successful",
      token: accessToken,
      user: { id: ownerId, phone_number, email }
    };

    const isMobileClient = req.headers['x-client-type'] === 'mobile';
    if (process.env.ALLOW_REFRESH_IN_BODY === 'true' && isMobileClient) {
      response.refresh_token = refreshToken;
    }

    res.status(201).json(response);

  } catch (err) {
    req.log?.error("registerCaptain: Database error", { error: err.message, code: err.code });
    if (err && err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({
        error: phone_number ? getUserFriendlyMessage("AUTH_PHONE_ALREADY_EXISTS") : "Email already registered"
      });
    }
    res.status(500).json({ error: "Server error", details: err.message, stack: err.stack });
  }
};

// ========================
// LOGIN CAPTAIN
// ========================
const loginCaptain = async (req, res) => {
  const { phone_number, email, password } = req.body;

  if (!password) return res.status(400).json({ error: "Password is required" });
  if (!phone_number && !email) return res.status(400).json({ error: "Either phone number or email is required" });
  if (phone_number && email) return res.status(400).json({ error: "Provide either phone number OR email, not both" });

  const loginIdentifier = phone_number || email;
  const isPhoneLogin = !!phone_number;
  const identifierField = isPhoneLogin ? 'phone_number' : 'email';
  const ipAddress = req.ip || req.socket?.remoteAddress || null;

  try {
    // 0️⃣ Throttling Check
    const [[{ failureCount }]] = await db.query(
      `SELECT COUNT(*) AS failureCount FROM auth_failures
       WHERE ${identifierField} = ? AND ip_address = ? AND failed_at > DATE_SUB(NOW(), INTERVAL 15 MINUTE) AND resolved_at IS NULL`,
      [loginIdentifier, ipAddress]
    );

    const count = Number(failureCount);
    let delayMs = 0;

    if (count >= AUTH_THROTTLING.THRESHOLDS.LEVEL_3.failures) delayMs = AUTH_THROTTLING.THRESHOLDS.LEVEL_3.delayMinutes * 60000;
    else if (count >= AUTH_THROTTLING.THRESHOLDS.LEVEL_2.failures) delayMs = AUTH_THROTTLING.THRESHOLDS.LEVEL_2.delayMinutes * 60000;
    else if (count >= AUTH_THROTTLING.THRESHOLDS.LEVEL_1.failures) delayMs = AUTH_THROTTLING.THRESHOLDS.LEVEL_1.delayMinutes * 60000;

    if (delayMs > 0) {
      const [[{ lastFailure }]] = await db.query(
        `SELECT UNIX_TIMESTAMP(MAX(failed_at)) * 1000 AS lastFailure FROM auth_failures
         WHERE ${identifierField} = ? AND ip_address = ? AND resolved_at IS NULL`,
        [loginIdentifier, ipAddress]
      );
      const timePassed = Date.now() - Number(lastFailure);
      if (timePassed < delayMs) {
        return res.status(429).json({
          error: "Too many failed login attempts. Please try again later.",
          retryAfter: Math.ceil((delayMs - timePassed) / 1000)
        });
      }
    }

    // 1️⃣ Find User
    const [rows] = await db.query(`SELECT * FROM users WHERE ${identifierField} = ?`, [loginIdentifier]);

    if (rows.length === 0) {
      await db.query(`INSERT INTO auth_failures (${identifierField}, ip_address, user_agent) VALUES (?, ?, ?)`,
        [loginIdentifier, ipAddress, req.headers['user-agent'] || null]);
      return res.status(404).json({ error: "User not found" });
    }

    const user = rows[0];

    // 2️⃣ Verify Password
    const match = await bcrypt.compare(password, user.password_hash || "");
    if (!match) {
      await db.query(`INSERT INTO auth_failures (${identifierField}, ip_address, user_agent) VALUES (?, ?, ?)`,
        [loginIdentifier, ipAddress, req.headers['user-agent'] || null]);
      return res.status(401).json({ error: "Invalid credentials" });
    }

    // 3️⃣ Clear Failures
    await db.query(
      `UPDATE auth_failures SET resolved_at = NOW()
       WHERE ${identifierField} = ? AND ip_address = ? AND resolved_at IS NULL`,
      [loginIdentifier, ipAddress]
    );

    // 4️⃣ Issue Tokens
    const { accessToken, refreshToken } = generateTokens(user);
    const csrfToken = crypto.randomBytes(32).toString('hex');

    // 5️⃣ Persist & Respond
    await db.query("INSERT INTO refresh_tokens (user_id, token, is_revoked) VALUES (?, ?, 0)", [user.id, refreshToken]);
    setAuthCookies(res, refreshToken, csrfToken);

    const response = {
      message: "Login successful",
      token: accessToken,
      user: { id: user.id, phone_number: user.phone_number, email: user.email }
    };

    if (process.env.ALLOW_REFRESH_IN_BODY === 'true' && req.headers['x-client-type'] === 'mobile') {
      response.refresh_token = refreshToken;
    }

    res.json(response);

  } catch (err) {
    req.log?.error(err);
    res.status(500).json({ error: "Server error", details: err.message });
  }
};

// ========================
// REFRESH ACCESS TOKEN
// ========================
const refreshToken = async (req, res) => {
  const tokenFromCookie = req.cookies && req.cookies.refresh_token;
  const tokenFromBody = req.body && req.body.refresh_token;
  const presented = tokenFromCookie || tokenFromBody;

  if (!presented) return res.status(401).json({ error: "Refresh token missing" });

  // CSRF check for browser clients
  if (tokenFromCookie && !tokenFromBody) {
    const csrf = req.get('X-CSRF-Token');
    const expected = req.cookies['csrf-token'];
    if (!csrf || !expected || csrf !== expected) return res.status(403).json({ error: "CSRF token mismatch" });
  }

  try {
    // Verify JWT
    const payload = jwt.verify(presented, process.env.JWT_REFRESH_SECRET, {
      clockTolerance: 5,
      audience: process.env.JWT_AUD,
      issuer: process.env.JWT_ISS,
    });

    // Check DB status
    const [rows] = await db.query("SELECT id, is_revoked, user_id FROM refresh_tokens WHERE token = ?", [presented]);
    if (rows.length === 0 || rows[0].is_revoked) return res.status(401).json({ error: "Invalid refresh token" });

    const userId = rows[0].user_id;
    const rotate = process.env.NODE_ENV === 'production' || String(process.env.ROTATE_REFRESH_ON_USE || '').toLowerCase() === 'true';

    let newRefresh = null;

    // Rotation Logic
    if (rotate) {
      await db.query("UPDATE refresh_tokens SET is_revoked = 1, revoked_at = NOW() WHERE token = ?", [presented]);

      // Fetch user to regenerate tokens with fresh roles
      const [userRows] = await db.query("SELECT * FROM users WHERE id = ?", [userId]);
      const user = userRows[0];

      const tokens = generateTokens(user); // Re-using helper
      newRefresh = tokens.refreshToken;

      await db.query("INSERT INTO refresh_tokens (user_id, token, is_revoked) VALUES (?, ?, 0)", [userId, newRefresh]);

      const newCsrf = crypto.randomBytes(32).toString('hex');
      setAuthCookies(res, newRefresh, newCsrf);
      res.set('X-Refresh-Rotated', 'true');
    }

    // Issue Access Token
    // We fetch the user again to ensure the access token has the latest roles/claims
    const [userRows] = await db.query("SELECT * FROM users WHERE id = ?", [userId]);
    const user = userRows[0];
    const { accessToken } = generateTokens(user);

    const response = { token: accessToken };
    if (newRefresh && tokenFromBody) {
      response.refresh_token = newRefresh;
    }

    return res.json(response);

  } catch (err) {
    if (err && err.name === 'TokenExpiredError') return res.status(401).json({ error: "Refresh token expired" });
    return res.status(401).json({ error: "Invalid refresh token" });
  }
};

// ========================
// LOGOUT
// ========================
const logout = async (req, res) => {
  const fromCookie = req.cookies && req.cookies.refresh_token;
  const fromBody = req.body && req.body.refresh_token;

  try {
    if (fromCookie) await db.query("UPDATE refresh_tokens SET is_revoked = 1, revoked_at = NOW() WHERE token = ?", [fromCookie]);
    if (fromBody) await db.query("UPDATE refresh_tokens SET is_revoked = 1, revoked_at = NOW() WHERE token = ?", [fromBody]);

    const isSecure = process.env.NODE_ENV === "production" || String(process.env.COOKIE_SECURE).toLowerCase() === "true";
    res.clearCookie("refresh_token", { path: "/", secure: isSecure, sameSite: isSecure ? "none" : "lax" });
    res.clearCookie("csrf-token", { path: "/", secure: isSecure, sameSite: "lax" });

    return res.status(200).json({ message: "Logged out" });
  } catch (err) {
    req.log?.error(err);
    return res.status(500).json({ error: mapDatabaseError(err) });
  }
};

// ========================
// PASSWORD RESET REQUEST
// ========================
const requestPasswordReset = async (req, res) => {
  const { phone_number } = req.body || {};
  if (!phone_number) return res.status(400).json({ error: "Phone number is required" });

  try {
    const [users] = await db.query("SELECT id FROM users WHERE phone_number = ?", [phone_number]);
    if (users.length === 0) return res.json({ message: "If the account exists, a reset was initiated" }); // No enum
    const userId = users[0].id;

    // Throttle: 1 req / 15 min
    const [[{ cnt }]] = await db.query(
      "SELECT COUNT(*) AS cnt FROM password_resets WHERE user_id = ? AND created_at > DATE_SUB(NOW(), INTERVAL 15 MINUTE)",
      [userId]
    );
    if (Number(cnt) >= 1) return res.status(429).json({ error: "Too many requests. Please try again later." });

    // Invalidate old tokens
    await db.query("UPDATE password_resets SET used_at = NOW() WHERE user_id = ? AND used_at IS NULL AND expires_at > NOW()", [userId]);

    // Generate Token
    const rawToken = crypto.randomBytes(48).toString("hex");
    const tokenHash = await bcrypt.hash(rawToken, 12);
    await db.query(
      "INSERT INTO password_resets (user_id, token_hash, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 15 MINUTE))",
      [userId, tokenHash]
    );

    const response = { message: "Reset initiated" };
    // Dev-only token return
    if (process.env.NODE_ENV !== 'production' && process.env.RETURN_RESET_TOKEN_IN_BODY === 'true') {
      response.token = rawToken;
    }

    return res.json(response);
  } catch (err) {
    req.log?.error(err);
    return res.status(500).json({ error: mapDatabaseError(err) });
  }
};

// ========================
// VERIFY RESET TOKEN
// ========================
const verifyPasswordReset = async (req, res) => {
  const { phone_number, token } = req.body || {};
  if (!phone_number || !token) return res.status(400).json({ error: "phone_number and token are required" });

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
    return res.status(500).json({ error: mapDatabaseError(err) });
  }
};

// ========================
// CONFIRM RESET
// ========================
const confirmPasswordReset = async (req, res) => {
  const { phone_number, new_password } = req.body || {};
  if (!phone_number || !new_password) return res.status(400).json({ error: "Missing fields" });
  if (String(new_password).length < 8) return res.status(400).json({ error: "Password must be at least 8 characters" });

  try {
    const [users] = await db.query("SELECT id FROM users WHERE phone_number = ?", [phone_number]);
    if (users.length === 0) return res.status(404).json({ error: "User not found" });
    const userId = users[0].id;

    // Direct password update - OTP Verification REMOVED
    const newHash = await bcrypt.hash(new_password, 12);
    await db.query("UPDATE users SET password_hash = ? WHERE id = ?", [newHash, userId]);

    // Invalidate sessions
    await db.query("UPDATE refresh_tokens SET is_revoked = 1, revoked_at = NOW() WHERE user_id = ? AND is_revoked = 0", [userId]);

    return res.json({ message: "Password reset successful" });
  } catch (err) {
    req.log?.error(err);
    return res.status(500).json({ error: mapDatabaseError(err) });
  }
};

// ========================
// CHANGE PASSWORD (Authenticated)
// ========================
const changePassword = async (req, res) => {
  const userId = req.user && req.user.id;
  const { current_password, new_password } = req.body || {};

  if (!userId) return res.status(401).json({ error: "Unauthorized" });
  if (!current_password || !new_password) return res.status(400).json({ error: "Missing fields" });
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
    return res.status(500).json({ error: mapDatabaseError(err) });
  }
};

// ========================
// CHANGE PHONE (Authenticated)
// ========================
const changePhoneNumber = async (req, res) => {
  const userId = req.user && req.user.id;
  const { new_phone_number } = req.body || {};

  if (!userId) return res.status(401).json({ error: "Unauthorized" });
  const phoneRegex = /^\+?[1-9]\d{7,14}$/;
  if (!new_phone_number || !phoneRegex.test(String(new_phone_number))) return res.status(400).json({ error: "Invalid phone number" });

  try {
    const [exists] = await db.query("SELECT id FROM users WHERE phone_number = ? AND id <> ?", [new_phone_number, userId]);
    if (exists.length > 0) return res.status(409).json({ error: "Phone number already in use" });

    await db.query("UPDATE users SET phone_number = ? WHERE id = ?", [new_phone_number, userId]);
    return res.json({ message: "Phone number updated", phone_number: new_phone_number });
  } catch (err) {
    req.log?.error(err);
    return res.status(500).json({ error: mapDatabaseError(err) });
  }
};

// ========================
// UTILS: CSRF & Cleanup
// ========================
const getCsrfToken = async (req, res) => {
  try {
    const csrfToken = crypto.randomBytes(32).toString('hex');
    const isSecure = process.env.NODE_ENV === 'production';
    res.cookie("csrf-token", csrfToken, { httpOnly: false, secure: isSecure, sameSite: isSecure ? "none" : "lax", path: "/", maxAge: 7 * 24 * 60 * 60 * 1000 });
    res.json({ csrf_token: csrfToken });
  } catch (err) {
    res.status(500).json({ error: "Server error" });
  }
};

const clearAuthFailures = async (req, res) => {
  if (process.env.NODE_ENV === 'production') return res.status(404).json({ error: 'Not found' });
  try {
    await db.query(`DELETE FROM auth_failures WHERE (resolved_at IS NOT NULL AND resolved_at < DATE_SUB(NOW(), INTERVAL 24 HOUR)) OR (resolved_at IS NULL AND failed_at < DATE_SUB(NOW(), INTERVAL 7 DAY))`);
    res.json({ message: "Auth failures cleaned up" });
  } catch (err) {
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = { registerCaptain, loginCaptain, refreshToken, logout, requestPasswordReset, verifyPasswordReset, confirmPasswordReset, changePassword, changePhoneNumber, getCsrfToken, clearAuthFailures };