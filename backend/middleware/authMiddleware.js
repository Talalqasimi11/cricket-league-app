const jwt = require("jsonwebtoken");

// ✅ Middleware to verify JWT token with aud/iss and clock tolerance
const verifyToken = (req, res, next) => {
  // Only log in debug mode and never log sensitive data
  if (process.env.LOG_LEVEL === 'debug') {
    req.log?.debug("verifyToken - URL:", req.url);
  }
  
  const authHeader = req.headers["authorization"]; 
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    if (process.env.LOG_LEVEL === 'debug') {
      req.log?.debug("verifyToken - No valid authorization header");
    }
    return res.status(401).json({ error: "Authorization header missing or malformed" });
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET, {
      audience: process.env.JWT_AUD,
      issuer: process.env.JWT_ISS,
      clockTolerance: 5,
    });

    // Validate token type
    if (decoded.typ !== 'access') {
      if (process.env.LOG_LEVEL === 'debug') {
        req.log?.debug("verifyToken - Invalid token type:", decoded.typ);
      }
      return res.status(401).json({ error: 'Invalid token type' });
    }

    // Validate sub field is a positive integer
    const userId = decoded.sub;
    if (!userId || !Number.isInteger(Number(userId)) || Number(userId) <= 0) {
      if (process.env.LOG_LEVEL === 'debug') {
        req.log?.debug("verifyToken - Invalid sub field in token");
      }
      return res.status(401).json({ error: 'Invalid token' });
    }

    req.user = {
      id: Number(userId),
      phone_number: decoded.phone_number,
      scopes: decoded.scopes || [],
      roles: decoded.roles || [],
    };
    
    if (process.env.LOG_LEVEL === 'debug') {
      req.log?.debug("verifyToken - Token verified for user:", req.user.id);
    }
    return next();
  } catch (err) {
    req.log?.error("JWT verification failed:", err.message);
    if (err && err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expired' });
    }
    return res.status(401).json({ error: 'Invalid token' });
  }
};

// Example scope guard (use 403 when forbidden)
const requireScope = (required) => (req, res, next) => {
  const scopes = req.user?.scopes || [];
  if (!scopes.includes(required)) {
    return res.status(403).json({ error: 'Forbidden' });
  }
  return next();
};

// Admin role guard - requires admin role in JWT token
const requireAdmin = (req, res, next) => {
  const roles = req.user?.roles || [];
  if (!roles.includes('admin')) {
    return res.status(403).json({ error: 'Admin access required' });
  }
  return next();
};

module.exports = { verifyToken, requireScope, requireAdmin };
