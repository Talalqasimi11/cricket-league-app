const express = require("express");
const cors = require("cors");
const cookieParser = require("cookie-parser");
const helmet = require("helmet");
const { v4: uuidv4 } = require("uuid");
require("dotenv").config();
const validateEnv = require("./config/validateEnv");

const path = require('path');

// Import custom middleware
const { validate } = require("./middleware/validationMiddleware");
const { createRequestLogger } = require("./utils/logger");
const { combinedRateLimit, createDynamicRateLimit } = require("./middleware/rateLimitMiddleware");

// Initialize database connection
const { db, checkConnection } = require("./config/db");

const authRoutes = require("./routes/authRoutes");
const teamRoutes = require("./routes/teamRoutes");
const matchRoutes = require("./routes/matchRoutes");
const playerRoutes = require("./routes/playerRoutes");
const tournamentRoutes = require("./routes/tournamentRoutes");
const tournamentTeamRoutes = require("./routes/tournamentTeamRoutes");
const tournamentMatchRoutes = require("./routes/tournamentMatchRoutes"); // ✅ Add this
const liveScoreRoutes = require("./routes/liveScoreRoutes");
const { setIo } = require("./controllers/liveScoreController"); // ✅ Import setIo
const liveScoreViewerRoutes = require("./routes/liveScoreViewerRoutes");
const matchInningsRoutes = require("./routes/matchInningsRoutes");
const playerStatsRoutes = require("./routes/playerStatsRoutes");
const teamTournamentSummaryRoutes = require("./routes/teamTournamentSummaryRoutes");
const statsRoutes = require("./routes/statsRoutes");
const feedbackRoutes = require("./routes/feedbackRoutes");
const adminRoutes = require("./routes/adminRoutes");
const uploadRoutes = require("./routes/uploadRoutes");
const tournamentStatsRoutes = require("./routes/tournamentStatsRoutes");
const matchSummaryRoutes = require("./routes/matchSummaryRoutes");


validateEnv();

// Test database connection
(async () => {
  try {
    const conn = await db.getConnection();
    await conn.query("SELECT 1");
    conn.release();
    console.log("✅ Database 'cricket_league' ready");
    console.log("✅ MySQL connected successfully");
  } catch (error) {
    console.error("❌ Database connection failed:", error.message);
    console.error("❌ Please check your .env credentials:");
    console.error(`   - DB_HOST: ${process.env.DB_HOST}`);
    console.error(`   - DB_USER: ${process.env.DB_USER}`);
    console.error(`   - DB_NAME: ${process.env.DB_NAME}`);
    console.error("❌ Server cannot start without database. Exiting...");
    process.exit(1);
  }
})();

const app = express();

// Trust proxy headers (needed for ngrok and other reverse proxies)
app.set('trust proxy', true);

app.use((req, res, next) => {


  res.setHeader('ngrok-skip-browser-warning', 'true');
  next();
});

// Helper function to derive connectSrc from allowedOrigins (moved after allowedOrigins declaration)

// Security headers with helmet (moved after getConnectSrc function definition)

// Request ID middleware (must be before other middleware)
app.use((req, res, next) => {
  req.id = req.headers['x-request-id'] || uuidv4();
  res.setHeader('X-Request-ID', req.id);
  next();
});
// Configure CORS: allow credentials and restrict origins explicitly via CORS_ORIGINS
let allowedOrigins = (process.env.CORS_ORIGINS || "").split(",").map(s => s.trim()).filter(Boolean);

// For development, auto-add common localhost origins if empty
if (process.env.NODE_ENV !== 'production' && allowedOrigins.length === 0) {
  allowedOrigins = [
    'https://foveolar-louetta-unradiant.ngrok-free.dev',
    'http://localhost:3000',
    'http://localhost:5000',
    'http://localhost:5001', // Admin panel
    'http://localhost:8080', // Flutter web dev server
    'http://127.0.0.1:3000',
    'http://127.0.0.1:5000',
    'http://127.0.0.1:8080', // Flutter web dev dev server alternative
    'http://10.0.2.2:5000', // Android emulator
    'http://192.168.10.38:5000', // Computer IP for physical devices
  ];
  console.log('⚠️  Development mode: Auto-adding localhost origins for CORS');
} else if (process.env.NODE_ENV === 'production' && allowedOrigins.length === 0) {
  console.error('❌ Production mode requires CORS_ORIGINS environment variable to be set');
  process.exit(1);
}

// Production CORS validation - enforce HTTPS-only origins
if (process.env.NODE_ENV === 'production') {
  const httpOrigins = allowedOrigins.filter(origin => origin.startsWith('http://'));
  const wildcardOrigins = allowedOrigins.filter(origin => origin.includes('*'));

  if (httpOrigins.length > 0) {
    console.error('❌ Production mode requires HTTPS-only origins. HTTP origins detected:', httpOrigins.join(', '));
    console.error('❌ Please update CORS_ORIGINS to use HTTPS protocols only');
    process.exit(1);
  }

  if (wildcardOrigins.length > 0) {
    console.error('❌ Production mode does not allow wildcard origins. Detected:', wildcardOrigins.join(', '));
    console.error('❌ Please specify exact origin URLs in CORS_ORIGINS');
    process.exit(1);
  }

  console.log('✅ CORS production security validation passed');
}

console.log('✅ CORS allowed origins:', allowedOrigins.length > 0 ? allowedOrigins.join(', ') : 'none (production requires CORS_ORIGINS)');
console.log('💡 For physical devices, add your computer\'s IP (e.g., http://192.168.1.100:5000) to CORS_ORIGINS env var');

// Additional validation: warn if COOKIE_SECURE is true but HTTP origins exist
if (process.env.COOKIE_SECURE === 'true') {
  const httpOrigins = allowedOrigins.filter(origin => origin.startsWith('http://'));
  if (httpOrigins.length > 0) {
    console.warn('⚠️  COOKIE_SECURE is enabled but HTTP origins detected:', httpOrigins.join(', '));
    console.warn('⚠️  Cookies will not work with HTTP origins when COOKIE_SECURE=true');
  }
}

// Helper function to derive connectSrc from allowedOrigins
const getConnectSrc = () => {
  const baseSources = ["'self'"];
  const wsSources = allowedOrigins.map(origin => {
    if (origin.startsWith('https://')) {
      return origin.replace('https://', 'wss://');
    } else if (origin.startsWith('http://')) {
      return origin.replace('http://', 'ws://');
    }
    return origin;
  });
  return [...baseSources, ...allowedOrigins, ...wsSources];
};

// Security headers with helmet
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: getConnectSrc(),
      fontSrc: ["'self'"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'none'"],
    },
  },
  crossOriginEmbedderPolicy: false, // Disable for development compatibility
}));

// Logging middleware - must be added after basic middleware but before routes
app.use(createRequestLogger({
  logAllRequests: process.env.NODE_ENV !== 'production',
  logErrors: true,
  logPerformance: true,
  excludePaths: ['/health', '/favicon.ico'],
  slowRequestThreshold: 1000
}));

// Dynamic rate limiting for suspicious activity
app.use(createDynamicRateLimit({
  windowMs: 60 * 1000, // 1 minute base window
  maxRequests: 2000, // Increased for dashboard and live polling
  increaseFactor: 1.5,
  maxWindowMs: 15 * 60 * 1000 // Max 15 minute window
}));

// Production validation: warn when credentials=true but no HTTPS origins
if (process.env.NODE_ENV === 'production') {
  const hasHttpsOrigins = allowedOrigins.some(origin => origin.startsWith('https://'));
  if (!hasHttpsOrigins) {
    console.warn('⚠️  Production mode with credentials=true but no HTTPS origins configured');
  }
}

// CORS origin callback function
const corsOriginCallback = (origin, callback) => {
  // In production, require explicit origin matches
  if (process.env.NODE_ENV === 'production') {
    if (!origin) {
      console.warn('🚫 CORS rejected null origin in production');
      return callback(new Error('CORS: Null origin not allowed in production'), false);
    }

    if (allowedOrigins.includes(origin)) {
      return callback(null, true);
    }

    console.warn(`🚫 CORS rejected origin: ${origin}`);
    return callback(new Error(`CORS: Origin ${origin} not allowed`), false);
  }

  // In development, allow null origin for non-browser requests
  if (!origin) return callback(null, true);

  if (allowedOrigins.includes(origin)) {
    return callback(null, true);
  }

  // NOTE: If you are testing on phone and get CORS errors, 
  // you might need to add your dynamic IP to allowedOrigins temporarily here
  // or add it to your .env file
  console.warn(`🚫 CORS rejected origin: ${origin}`);
  return callback(new Error(`CORS: Origin ${origin} not allowed`), false);
};

// Configure CORS with preflight handler
app.use(cors({
  origin: corsOriginCallback,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'X-Requested-With', 'X-CSRF-Token', 'Authorization', 'x-client-type'],
  exposedHeaders: ['X-Refresh-Rotated'],
}));

// Global OPTIONS handler for preflight requests
app.use((req, res, next) => {
  if (req.method === 'OPTIONS') {
    return cors({
      origin: corsOriginCallback,
      credentials: true,
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'X-Requested-With', 'X-CSRF-Token', 'Authorization', 'x-client-type'],
      exposedHeaders: ['X-Refresh-Rotated'],
    })(req, res, next);
  }
  next();
});
app.use(express.json());
app.use(cookieParser());

// ✅ Routes


// Use Routes
app.use("/api/auth", authRoutes);
app.use("/api/teams", teamRoutes);
app.use("/api/matches", matchRoutes);
app.use("/api/matches", require("./routes/matchFinalizationRoutes"));
app.use("/api/players", playerRoutes);
app.use("/api/tournaments", tournamentRoutes);
app.use("/api/tournament-teams", tournamentTeamRoutes);
app.use("/api/tournament-matches", tournamentMatchRoutes);
app.use("/api/live", liveScoreRoutes);
app.use("/api/tournament-stats", tournamentStatsRoutes);
app.use("/api/match-summary", matchSummaryRoutes);
app.use("/api/tournament-summary", teamTournamentSummaryRoutes);
app.use("/api/player-stats", playerStatsRoutes);
const ballByBallRoutes = require("./routes/ballByBallRoutes");
app.use("/api/deliveries", ballByBallRoutes);
app.use("/api/viewer/live-score", liveScoreViewerRoutes);
const scorecardRoutes = require("./routes/scorecardRoutes");
app.use("/api/viewer/scorecard", scorecardRoutes);

app.use("/api/match-innings", matchInningsRoutes);
app.use("/api/stats", statsRoutes);
app.use("/api/feedback", feedbackRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/uploads", uploadRoutes);
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// ✅ Health Check Alias for Admin Panel
app.get("/api/health/ready", async (req, res) => {
  try {
    const isDbReady = await checkConnection();
    if (isDbReady) {
      res.status(200).json({
        status: 'ready',
        timestamp: new Date().toISOString(),
        version: process.env.APP_VERSION || 'dev',
        database: 'connected'
      });
    } else {
      res.status(503).json({
        status: 'not ready',
        timestamp: new Date().toISOString(),
        version: process.env.APP_VERSION || 'dev',
        database: 'disconnected'
      });
    }
  } catch (error) {
    res.status(503).json({
      status: 'not ready',
      timestamp: new Date().toISOString(),
      version: process.env.APP_VERSION || 'dev',
      database: 'error',
      error: error.message
    });
  }
});


// Health check endpoints
// Liveness probe - always returns 200 if server is running
app.get("/health/live", (req, res) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    version: process.env.APP_VERSION || 'dev'
  });
});

// Readiness probe - returns 200 only if DB is accessible, 503 otherwise
app.get("/health/ready", async (req, res) => {
  try {
    const isDbReady = await checkConnection();
    if (isDbReady) {
      res.status(200).json({
        status: 'ready',
        timestamp: new Date().toISOString(),
        version: process.env.APP_VERSION || 'dev',
        database: 'connected'
      });
    } else {
      res.status(503).json({
        status: 'not ready',
        timestamp: new Date().toISOString(),
        version: process.env.APP_VERSION || 'dev',
        database: 'disconnected'
      });
    }
  } catch (error) {
    res.status(503).json({
      status: 'not ready',
      timestamp: new Date().toISOString(),
      version: process.env.APP_VERSION || 'dev',
      database: 'error',
      error: error.message
    });
  }
});

// Legacy health endpoint for backward compatibility
app.get("/health", async (req, res) => {
  try {
    const isDbReady = await checkConnection();
    return res.status(200).json({
      status: 'ok',
      version: process.env.APP_VERSION || 'dev',
      database: isDbReady ? 'up' : 'down'
    });
  } catch (error) {
    return res.status(200).json({
      status: 'ok',
      version: process.env.APP_VERSION || 'dev',
      database: 'down'
    });
  }
});

// 404 handler
app.use((req, res) => res.status(404).json({ error: 'Not found' }));

// Error handler
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  req.log?.error(err);
  const errorResponse = { error: 'Internal Server Error' };
  if (process.env.NODE_ENV !== 'production') {
    errorResponse.details = err.message;
  }
  res.status(500).json(errorResponse);
});

// Create HTTP server for Socket.IO
const httpServer = require('http').createServer(app);

// Initialize Socket.IO with Redis adapter
// Initialize Socket.IO
const { Server } = require('socket.io');


// Redis client configuration

const io = new Server(httpServer, {
  cors: {
    origin: allowedOrigins,
    methods: ["GET", "POST"],
    credentials: true
  },
  // Socket.IO configuration
  pingTimeout: 60000,
  pingInterval: 25000,
  transports: ['websocket', 'polling'],
  allowUpgrades: true,
  upgradeTimeout: 10000,
  maxHttpBufferSize: 1e6 // 1MB
});


// ✅ Initialize controller with IO
setIo(io);

// Socket.IO authentication middleware
const liveScoreNamespace = io.of('/live-score');

liveScoreNamespace.use(async (socket, next) => {
  try {
    const token = socket.handshake.auth.token;
    if (token) {
      const decoded = require('./middleware/authMiddleware').verifyJWTToken(token);
      socket.user = decoded;
    }
    next();
  } catch (err) {
    // If token is invalid, we still allow connection but don't set socket.user (view-only mode)
    console.warn('WebSocket session could not be established (View-only mode):', err.message);
    next();
  }
});

// Room cleanup interval (every 5 minutes)
const cleanupInterval = setInterval(() => {
  liveScoreNamespace.adapter.rooms.forEach((_, room) => {
    if (room.startsWith('match:')) {
      const sockets = liveScoreNamespace.adapter.rooms.get(room);
      if (!sockets || sockets.size === 0) {
        console.log(`Cleaning up empty room: ${room}`);
        liveScoreNamespace.adapter.rooms.delete(room);
      }
    }
  });
}, 5 * 60 * 1000);

// Cleanup on server shutdown
process.on('SIGTERM', () => {
  clearInterval(cleanupInterval);
  io.close(() => {
    console.log('Socket.IO server closed');
  });
});

// Socket.IO connection handler
liveScoreNamespace.on('connection', (socket) => {
  console.log(`User ${socket.user?.id} connected`);

  // Track subscribed matches for cleanup
  const subscribedMatches = new Set();

  socket.on('subscribe', (payload) => {
    // Handle both primitive and object payloads (for frontend compatibility)
    const matchId = (payload && typeof payload === 'object') ? payload.matchId : payload;

    if (typeof matchId !== 'string' && typeof matchId !== 'number') {
      socket.emit('error', { message: 'Invalid match ID' });
      return;
    }

    const roomName = `match:${matchId}`;
    socket.join(roomName);
    subscribedMatches.add(matchId);
    console.log(`User ${socket.user?.id || 'guest'} subscribed to match ${matchId}`);

    // Notify client of successful subscription
    socket.emit('subscribed', { matchId });
  });

  socket.on('unsubscribe', (payload) => {
    const matchId = (payload && typeof payload === 'object') ? payload.matchId : payload;
    if (!matchId) return;

    const roomName = `match:${matchId}`;
    socket.leave(roomName);
    subscribedMatches.delete(matchId);
    console.log(`User ${socket.user?.id || 'guest'} unsubscribed from match ${matchId}`);
  });

  socket.on('disconnect', (reason) => {
    // Clean up all subscribed matches
    subscribedMatches.forEach(matchId => {
      const roomName = `match:${matchId}`;
      socket.leave(roomName);
    });
    subscribedMatches.clear();

    console.log(`User ${socket.user?.id || 'guest'} disconnected. Reason: ${reason}`);
  });

  socket.on('error', (error) => {
    console.error(`Socket Error for user ${socket.user?.id}:`, error);
  });
});

// Export app, server, and io instance for use in controllers and tests
module.exports = { app, server: httpServer, io };

// ✅ Start server only when run directly (not when imported for testing)
if (require.main === module) {
  const PORT = process.env.PORT || 5000;

  // '0.0.0.0' binds to ALL network interfaces (WiFi, Ethernet, etc.)
  httpServer.listen(PORT, '0.0.0.0', () => {
    console.log(`✅ Server running locally: http://localhost:${PORT}`);

    // --- Helper to print your Network IP automatically ---
    const { networkInterfaces } = require('os');
    const nets = networkInterfaces();

    for (const name of Object.keys(nets)) {
      for (const net of nets[name]) {
        // Skip over non-IPv4 and internal (i.e. 127.0.0.1) addresses
        if (net.family === 'IPv4' && !net.internal) {
          console.log(`📲 Connect from Phone:  http://${net.address}:${PORT}`);
        }
      }
    }
    // ----------------------------------------------------
  });
}