const jwt = require("jsonwebtoken");

// ✅ Middleware to verify JWT token
const verifyToken = (req, res, next) => {
  const authHeader = req.headers["authorization"];

  // Must start with "Bearer "
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Authorization header missing or malformed" });
  }

  const token = authHeader.split(" ")[1];

  try {
    // Verify token with secret
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Attach decoded payload (id, phone, etc.)
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(403).json({ error: "Invalid or expired token" });
  }
};

module.exports = verifyToken;
