const { db } = require("../config/db");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const crypto = require("crypto");
const { getUserFriendlyMessage, mapDatabaseError } = require("../utils/errorMessages");
const { validateTeamLogoUrl } = require("../utils/urlValidation");
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

// ========================
// REGISTER CAPTAIN
// ========================
const registerCaptain = async (req, res) => {
    let { phone_number, password, team_name, team_location, team_logo_url } = req.body; // ✅ ADDED team_logo_url

  if (!phone_number || !password || !team_name || !team_location) {
    return res.status(400).json({ error: getUserFriendlyMessage("VALIDATION_REQUIRED_FIELD") });
  }

  // Basic phone and password validation (E.164-ish and min length)
  const phoneRegex = /^\+?[1-9]\d{7,14}$/;
  if (!phoneRegex.test(String(phone_number))) {
    return res.status(400).json({ error: getUserFriendlyMessage("AUTH_INVALID_PHONE") });
  }
  if (String(password).length < 8) {
    return res.status(400).json({ error: getUserFriendlyMessage("AUTH_WEAK_PASSWORD") });
  }

  // Validate team logo URL if provided
  if (team_logo_url !== undefined && team_logo_url !== null) {
    const urlValidation = validateTeamLogoUrl(team_logo_url);
    if (!urlValidation.isValid) {
      return res.status(400).json({ error: `Invalid team logo URL: ${urlValidation.error}` });
    }
    // Use normalized URL
    team_logo_url = urlValidation.normalizedUrl;
  }

  try {
    // Step 0: Check if phone number already exists
    const [existing] = await db.query(
      "SELECT id FROM users WHERE phone_number = ?",
      [phone_number]
    );
    if (existing.length > 0) {
      return res.status(409).json({ error: getUserFriendlyMessage("AUTH_PHONE_ALREADY_EXISTS") });
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

    // Step 3: Issue tokens on successful registration (same as login)
    // Check if user is admin
    const [adminCheck] = await db.query("SELECT is_admin FROM users WHERE id = ?", [ownerId]);
    const isAdmin = adminCheck.length > 0 && adminCheck[0].is_admin;
    
    const roles = ['captain'];
    const scopes = ['team:read', 'team:manage', 'match:score', 'player:manage', 'tournament:manage'];
    
    if (isAdmin) {
      roles.push('admin');
      scopes.push('admin:manage', 'user:manage', 'team:admin');
    }
    
    const jwtPayload = { 
      sub: ownerId, 
      phone_number: phone_number, 
      roles: roles,
      scopes: scopes,
      typ: 'access', // Token type for validation
      iss: process.env.JWT_ISS, 
      aud: process.env.JWT_AUD 
    };
    const accessToken = jwt.sign(jwtPayload, process.env.JWT_SECRET, { expiresIn: "15m" });
    const refreshToken = jwt.sign({ sub: ownerId, typ: "refresh", iss: process.env.JWT_ISS, aud: process.env.JWT_AUD }, process.env.JWT_REFRESH_SECRET, { expiresIn: "7d" });

    // Step 4: Persist refresh token (basic blacklist table)
    await db.query("INSERT INTO refresh_tokens (user_id, token, is_revoked) VALUES (?, ?, 0)", [ownerId, refreshToken]);

    // Step 5: Set httpOnly cookie with env-based security flags
    // Use sameSite: 'none' for cross-site flows (mobile/web); requires secure: true
    const isSecure = process.env.NODE_ENV === "production" || String(process.env.COOKIE_SECURE).toLowerCase() === "true";
    res.cookie("refresh_token", refreshToken, {
      httpOnly: true,
      secure: isSecure,
      sameSite: isSecure ? "none" : "lax", // 'none' requires secure; fallback to 'lax' for local dev
      path: "/",
      maxAge: 7 * 24 * 60 * 60 * 1000,
    });

    // Set CSRF token for web clients
    const csrfToken = crypto.randomBytes(32).toString('hex');
    res.cookie("csrf-token", csrfToken, {
      httpOnly: false, // Must be accessible to JavaScript for CSRF protection
      secure: isSecure,
      sameSite: "lax", // Use 'lax' for CSRF token regardless of environment
      path: "/",
      maxAge: 7 * 24 * 60 * 60 * 1000,
    });

    // Step 6: Respond access token and conditionally refresh token (for mobile clients)
    const response = {
      message: "Owner and team registered successfully",
      token: accessToken,
      user: { id: ownerId, phone_number: phone_number },
    };
    
    // Only include refresh token in body for mobile clients
    // For web clients, refresh tokens are handled via cookies only
    const isMobileClient = req.headers['x-client-type'] === 'mobile';
    const allowRefreshInBody = process.env.ALLOW_REFRESH_IN_BODY === 'true' && isMobileClient;
    
    if (allowRefreshInBody) {
      response.refresh_token = refreshToken;
    }

    res.status(201).json(response);
  } catch (err) {
    req.log?.error("registerCaptain: Database error", { error: err.message, code: err.code });
    if (err && err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: getUserFriendlyMessage("AUTH_PHONE_ALREADY_EXISTS") });
    }
    res.status(500).json({ error: "Server error" });
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
      "SELECT COUNT(*) AS failureCount FROM auth_failures WHERE phone_number = ? AND ip_address = ? AND failed_at > DATE_SUB(NOW(), INTERVAL 15 MINUTE) AND resolved_at IS NULL",
      [phone_number, ipAddress]
    );

    // Progressive lockout: PRD-compliant thresholds
    let requiredDelay = 0;
    const failureCountNum = Number(failureCount);
    
    // PRD thresholds: 3→1m, 5→5m, 10→30m in a 15m window
    if (failureCountNum >= AUTH_THROTTLING.THRESHOLDS.LEVEL_3.failures) {
      requiredDelay = AUTH_THROTTLING.THRESHOLDS.LEVEL_3.delayMinutes * 60 * 1000;
    } else if (failureCountNum >= AUTH_THROTTLING.THRESHOLDS.LEVEL_2.failures) {
      requiredDelay = AUTH_THROTTLING.THRESHOLDS.LEVEL_2.delayMinutes * 60 * 1000;
    } else if (failureCountNum >= AUTH_THROTTLING.THRESHOLDS.LEVEL_1.failures) {
      requiredDelay = AUTH_THROTTLING.THRESHOLDS.LEVEL_1.delayMinutes * 60 * 1000;
    }

    if (requiredDelay > 0) {
      const [[{ lastFailure }]] = await db.query(
        "SELECT UNIX_TIMESTAMP(MAX(failed_at)) * 1000 AS lastFailure FROM auth_failures WHERE phone_number = ? AND ip_address = ? AND resolved_at IS NULL",
        [phone_number, ipAddress]
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

    // 3️⃣ SUCCESS - Mark auth failures as resolved for this phone number and IP
    await db.query(
      "UPDATE auth_failures SET resolved_at = NOW() WHERE phone_number = ? AND ip_address = ? AND resolved_at IS NULL", 
      [phone_number, ipAddress]
    );

    // 4️⃣ Create short-lived access token and long-lived refresh token
    // Check if user is admin
    const isAdmin = user.is_admin || false;
    
    const roles = ['captain'];
    const scopes = ['team:read', 'team:manage', 'match:score', 'player:manage', 'tournament:manage'];
    
    if (isAdmin) {
      roles.push('admin');
      scopes.push('admin:manage', 'user:manage', 'team:admin');
    }
    
    const jwtPayload = { 
      sub: user.id, 
      phone_number: user.phone_number, 
      roles: roles,
      scopes: scopes,
      typ: 'access', // Token type for validation
      iss: process.env.JWT_ISS, 
      aud: process.env.JWT_AUD 
    };
    const accessToken = jwt.sign(jwtPayload, process.env.JWT_SECRET, { expiresIn: "15m" });
    const refreshToken = jwt.sign({ sub: user.id, typ: "refresh", iss: process.env.JWT_ISS, aud: process.env.JWT_AUD }, process.env.JWT_REFRESH_SECRET, { expiresIn: "7d" });

    // 5️⃣ Persist refresh token (basic blacklist table)
    await db.query("INSERT INTO refresh_tokens (user_id, token, is_revoked) VALUES (?, ?, 0)", [user.id, refreshToken]);

    // 6️⃣ Set httpOnly cookie with env-based security flags
    // Use sameSite: 'none' for cross-site flows (mobile/web); requires secure: true
    const isSecure = process.env.NODE_ENV === "production" || String(process.env.COOKIE_SECURE).toLowerCase() === "true";
    res.cookie("refresh_token", refreshToken, {
      httpOnly: true,
      secure: isSecure,
      sameSite: isSecure ? "none" : "lax", // 'none' requires secure; fallback to 'lax' for local dev
      path: "/",
      maxAge: 7 * 24 * 60 * 60 * 1000,
    });

    // Set CSRF token for web clients
    const csrfToken = crypto.randomBytes(32).toString('hex');
    res.cookie("csrf-token", csrfToken, {
      httpOnly: false, // Must be accessible to JavaScript for CSRF protection
      secure: isSecure,
      sameSite: "lax", // Use 'lax' for CSRF token regardless of environment
      path: "/",
      maxAge: 7 * 24 * 60 * 60 * 1000,
    });

    // 7️⃣ Respond access token and conditionally refresh token (for mobile clients)
    const response = {
      message: "Login successful",
      token: accessToken,
      user: { id: user.id, phone_number: user.phone_number },
    };
    
    // Only include refresh token in body for mobile clients
    // For web clients, refresh tokens are handled via cookies only
    const isMobileClient = req.headers['x-client-type'] === 'mobile';
    const allowRefreshInBody = process.env.ALLOW_REFRESH_IN_BODY === 'true' && isMobileClient;
    
    if (allowRefreshInBody) {
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
  // Accept refresh token from httpOnly cookie OR request body for mobile clients
  const tokenFromCookie = req.cookies && req.cookies.refresh_token;
  const tokenFromBody = req.body && req.body.refresh_token;
  const presented = tokenFromCookie || tokenFromBody;
  if (!presented) {
    return res.status(401).json({ error: "Refresh token missing" });
  }

  // CSRF protection for cookie-based refresh
  if (tokenFromCookie && !tokenFromBody) {
    const csrfToken = req.get('X-CSRF-Token');
    const expectedCsrfToken = req.cookies['csrf-token'];
    
    if (!csrfToken || !expectedCsrfToken || csrfToken !== expectedCsrfToken) {
      return res.status(403).json({ error: "CSRF token mismatch" });
    }
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

    // Enable rotation by default in production, optional in development
    const rotate = process.env.NODE_ENV === 'production' || 
                   String(process.env.ROTATE_REFRESH_ON_USE || '').toLowerCase() === 'true';
    let newRefresh = null;
    if (rotate) {
      // revoke old
      await db.query("UPDATE refresh_tokens SET is_revoked = 1, revoked_at = NOW() WHERE token = ?", [presented]);
      // issue new
      newRefresh = jwt.sign({ sub: userId, typ: "refresh", iss: process.env.JWT_ISS, aud: process.env.JWT_AUD }, process.env.JWT_REFRESH_SECRET, { expiresIn: "7d" });
      await db.query("INSERT INTO refresh_tokens (user_id, token, is_revoked) VALUES (?, ?, 0)", [userId, newRefresh]);
      const isSecure = process.env.NODE_ENV === "production" || String(process.env.COOKIE_SECURE).toLowerCase() === "true";
      res.cookie("refresh_token", newRefresh, {
        httpOnly: true,
        secure: isSecure,
        sameSite: isSecure ? "none" : "lax", // 'none' requires secure; fallback to 'lax' for local dev
        path: "/",
        maxAge: 7 * 24 * 60 * 60 * 1000,
      });

      // Set new CSRF token for web clients
      const newCsrfToken = crypto.randomBytes(32).toString('hex');
      res.cookie("csrf-token", newCsrfToken, {
        httpOnly: false, // Must be accessible to JavaScript for CSRF protection
        secure: isSecure,
        sameSite: "lax", // Use 'lax' for CSRF token regardless of environment
        path: "/",
        maxAge: 7 * 24 * 60 * 60 * 1000,
      });

      // Signal to client that refresh token was rotated
      res.set('X-Refresh-Rotated', 'true');
    }

    // Get user details for token claims
    const [userRows] = await db.query("SELECT phone_number, is_admin FROM users WHERE id = ?", [userId]);
    const user = userRows[0];
    
    const isAdmin = user.is_admin || false;
    const roles = ['captain'];
    const scopes = ['team:read', 'team:manage', 'match:score', 'player:manage', 'tournament:manage'];
    
    if (isAdmin) {
      roles.push('admin');
      scopes.push('admin:manage', 'user:manage', 'team:admin');
    }
    
    const accessToken = jwt.sign({ 
      sub: userId, 
      phone_number: user.phone_number,
      roles: roles,
      scopes: scopes,
      typ: 'access', // Token type for validation
      iss: process.env.JWT_ISS, 
      aud: process.env.JWT_AUD 
    }, process.env.JWT_SECRET, { expiresIn: "15m" });
    
    const response = { token: accessToken };
    
    // Always include refresh token in body when rotation occurs and token was presented in body
    if (newRefresh && tokenFromBody) {
      response.refresh_token = newRefresh;
    }
    
    // Set response header to indicate rotation occurred
    if (newRefresh) {
      res.setHeader('X-Refresh-Rotated', 'true');
    }
    
    return res.json(response);
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
    const isSecure = process.env.NODE_ENV === "production" || String(process.env.COOKIE_SECURE).toLowerCase() === "true";
    res.clearCookie("refresh_token", { 
      path: "/", 
      secure: isSecure, 
      sameSite: isSecure ? "none" : "lax" 
    });
    res.clearCookie("csrf-token", { 
      path: "/", 
      secure: isSecure, 
      sameSite: "lax" 
    });
    return res.status(200).json({ message: "Logged out" });
  } catch (err) {
    req.log?.error(err);
    return res.status(500).json({ error: mapDatabaseError(err) });
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

    const rawToken = crypto.randomBytes(48).toString("hex");
    const tokenHash = await bcrypt.hash(rawToken, 12);
    const expiresMinutes = 15;
    await db.query(
      "INSERT INTO password_resets (user_id, token_hash, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? MINUTE))",
      [userId, tokenHash, expiresMinutes]
    );

    // In production, send via SMS/Email. For development, return token for UX testing
    const response = { message: "Reset initiated" };
    
    // Only return token when explicitly allowed AND not in production
    const returnTokenInBody = process.env.RETURN_RESET_TOKEN_IN_BODY === 'true' && 
                             process.env.NODE_ENV !== 'production';
    
    if (returnTokenInBody) {
      response.token = rawToken;
      console.log(`⚠️  Password reset token returned in body for user ${userId} (development only)`);
    } else if (process.env.NODE_ENV !== 'production') {
      console.log(`🔒 Password reset token generated for user ${userId} but not returned (security)`);
    }
    
    return res.json(response);
  } catch (err) {
    req.log?.error(err);
    return res.status(500).json({ error: mapDatabaseError(err) });
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
    return res.status(500).json({ error: mapDatabaseError(err) });
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
    return res.status(500).json({ error: mapDatabaseError(err) });
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
    return res.status(500).json({ error: mapDatabaseError(err) });
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
    return res.status(500).json({ error: mapDatabaseError(err) });
  }
};

// ========================
// CSRF TOKEN ENDPOINT
// ========================
const getCsrfToken = async (req, res) => {
  try {
    const csrfToken = crypto.randomBytes(32).toString('hex');
    const isSecure = process.env.NODE_ENV === 'production';
    
    res.cookie("csrf-token", csrfToken, {
      httpOnly: true,
      secure: isSecure,
      sameSite: isSecure ? "none" : "lax",
      path: "/",
      maxAge: 7 * 24 * 60 * 60 * 1000,
    });
    
    res.json({ csrf_token: csrfToken });
  } catch (err) {
    req.log?.error(err);
    res.status(500).json({ error: "Server error" });
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
    // Clean up old resolved failures (older than 24 hours) and very old unresolved ones (older than 7 days)
    await db.query(`
      DELETE FROM auth_failures 
      WHERE (resolved_at IS NOT NULL AND resolved_at < DATE_SUB(NOW(), INTERVAL 24 HOUR))
         OR (resolved_at IS NULL AND failed_at < DATE_SUB(NOW(), INTERVAL 7 DAY))
    `);
    res.json({ message: "Auth failures cleaned up" });
  } catch (err) {
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = { registerCaptain, loginCaptain, refreshToken, logout, requestPasswordReset, verifyPasswordReset, confirmPasswordReset, changePassword, changePhoneNumber, getCsrfToken, clearAuthFailures };
