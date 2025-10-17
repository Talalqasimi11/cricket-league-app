const jwt = require("jsonwebtoken");

// ✅ Middleware to verify JWT token with aud/iss and clock tolerance
const verifyToken = (req, res, next) => {
  console.log("🔍 verifyToken - URL:", req.url);
  console.log("🔍 verifyToken - Authorization header:", req.headers["authorization"]);
  
  const authHeader = req.headers["authorization"]; 
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    console.log("❌ verifyToken - No valid authorization header");
    return res.status(401).json({ error: "Authorization header missing or malformed" });
  }

  const token = authHeader.split(" ")[1];
  console.log("🔍 verifyToken - Token length:", token.length);

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET, {
      audience: process.env.JWT_AUD,
      issuer: process.env.JWT_ISS,
      clockTolerance: 5,
    });

    console.log("🔍 verifyToken - Decoded token:", decoded);

    req.user = {
      id: parseInt(decoded.sub || decoded.id),
      phone_number: decoded.phone_number,
      scopes: decoded.scopes || [],
      roles: decoded.roles || [],
      raw: decoded,
    };
    
    console.log("🔍 verifyToken - Parsed user:", req.user);
    return next();
  } catch (err) {
    console.log("❌ verifyToken - JWT error:", err.message);
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

module.exports = { verifyToken, requireScope };
