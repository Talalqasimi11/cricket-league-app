const express = require("express");
const cors = require("cors");
const cookieParser = require("cookie-parser");
const helmet = require("helmet");
const pinoHttp = require("pino-http");
const { sanitizeObject } = require("./utils/safeLogger");
const { v4: uuidv4 } = require("uuid");
require("dotenv").config();
const validateEnv = require("./config/validateEnv");
const rateLimit = require("express-rate-limit");

// Initialize database connection
const { db, checkConnection } = require("./config/db");

const authRoutes = require("./routes/authRoutes");
const teamRoutes = require("./routes/teamRoutes");
// const matchRoutes = require("./routes/matchRoutes");
const playerRoutes = require("./routes/playerRoutes");
const tournamentRoutes = require("./routes/tournamentRoutes");
const tournamentTeamRoutes = require("./routes/tournamentTeamRoutes");
const tournamentMatchRoutes = require("./routes/tournamentMatchRoutes"); // ✅ Add this
const liveScoreRoutes = require("./routes/liveScoreRoutes");
const playerStatsRoutes = require("./routes/playerStatsRoutes");
const teamTournamentSummaryRoutes = require("./routes/teamTournamentSummaryRoutes");
const feedbackRoutes = require("./routes/feedbackRoutes");
const adminRoutes = require("./routes/adminRoutes");

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


app.use((req, res, next) => {
 

  res.setHeader('ngrok-skip-browser-warning', 'true');
  next();
});

// Helper function to derive connectSrc from allowedOrigins (moved after allowedOrigins declaration)

// Security headers with helmet (moved after getConnectSrc function definition)

app.use(pinoHttp({
  redact: [
    'req.headers.authorization', 
    'req.headers.cookie', 
    'res.headers.set-cookie',
    'req.headers.x-csrf-token',
    'req.headers.x-requested-with',
    'req.body.password',
    'req.body.current_password',
    'req.body.new_password',
    'req.body.refresh_token',
    'req.body.token',
    'req.body.phone_number'
  ],
  genReqId: (req) => req.headers['x-request-id'] || uuidv4(),
  serializers: {
    req(request) {
      // avoid logging bodies for auth endpoints and sensitive data
      const isAuth = request.url && request.url.startsWith('/api/auth');
      const isSensitive = request.url && (
        request.url.includes('/password') || 
        request.url.includes('/login') || 
        request.url.includes('/register')
      );
      
      const sanitizedHeaders = sanitizeObject(request.headers);
      
      return {
        method: request.method,
        url: request.url,
        headers: sanitizedHeaders,
        id: request.id,
        remoteAddress: request.socket?.remoteAddress,
        remotePort: request.socket?.remotePort,
        // Use request.body after express.json middleware, sanitize sensitive data
        body: (isAuth || isSensitive) ? undefined : sanitizeObject(request.body || {}),
        query: sanitizeObject(request.query || {}),
      };
    },
    res(response) {
      return { 
        statusCode: response.statusCode, 
        headers: sanitizeObject(response.getHeaders?.() || {})
      };
    }
  }
}));
// Configure CORS: allow credentials and restrict origins explicitly via CORS_ORIGINS
let allowedOrigins = (process.env.CORS_ORIGINS || "").split(",").map(s => s.trim()).filter(Boolean);

// For development, auto-add common localhost origins if empty
if (process.env.NODE_ENV !== 'production' && allowedOrigins.length === 0) {
  allowedOrigins = [
    'https://foveolar-louetta-unradiant.ngrok-free.dev',
    'http://localhost:3000',
    'http://localhost:5000',
    'http://localhost:8080', // Flutter web dev server
    'http://127.0.0.1:3000',
    'http://127.0.0.1:5000',
    'http://127.0.0.1:8080', // Flutter web dev server alternative
    'http://10.0.2.2:5000', // Android emulator
  ];
  console.log('⚠️  Development mode: Auto-adding localhost origins for CORS');
} else if (process.env.NODE_ENV === 'production' && allowedOrigins.length === 0) {
  console.error('❌ Production mode requires CORS_ORIGINS environment variable to be set');
  process.exit(1);
}

console.log('✅ CORS allowed origins:', allowedOrigins.length > 0 ? allowedOrigins.join(', ') : 'none (production requires CORS_ORIGINS)');
console.log('💡 For physical devices, add your computer\'s IP (e.g., http://192.168.1.100:5000) to CORS_ORIGINS env var');

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
app.use("/api/tournament-summary", teamTournamentSummaryRoutes);
app.use("/api/player-stats", playerStatsRoutes);
const ballByBallRoutes = require("./routes/ballByBallRoutes");
app.use("/api/deliveries", ballByBallRoutes);
const liveScoreViewerRoutes = require("./routes/liveScoreViewerRoutes");
app.use("/api/viewer/live-score", liveScoreViewerRoutes);
const scorecardRoutes = require("./routes/scorecardRoutes");
app.use("/api/viewer/scorecard", scorecardRoutes);

// Mount auth routes (rate limiting is handled in authRoutes.js)
app.use("/api/auth", authRoutes);
app.use("/api/teams", teamRoutes);
// app.use("/api/matches", matchRoutes);
app.use("/api/players", playerRoutes);
app.use("/api/tournaments", tournamentRoutes);
app.use("/api/tournament-teams", tournamentTeamRoutes);
app.use("/api/tournament-matches", tournamentMatchRoutes); // ✅ Register here
app.use("/api/live", liveScoreRoutes);
app.use("/api/feedback", feedbackRoutes);
app.use("/api/admin", adminRoutes);

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
  res.status(500).json({ error: 'Internal Server Error' });
});

// Create HTTP server for Socket.IO
const httpServer = require('http').createServer(app);

// Initialize Socket.IO with Redis adapter
const { Server } = require('socket.io');
const { createAdapter } = require('@socket.io/redis-adapter');
const redis = require('redis');

const pubClient = redis.createClient();
const subClient = pubClient.duplicate();

const io = new Server(httpServer, {
  cors: {
    origin: (process.env.CORS_ORIGINS || "").split(',').map(s => s.trim()).filter(Boolean),
    methods: ["GET", "POST"],
    credentials: true
  }
});

io.adapter(createAdapter(pubClient, subClient));

// Socket.IO authentication middleware
io.of('/live-score').use(async (socket, next) => {
  try {
    const token = socket.handshake.auth.token;
    if (!token) return next(new Error('Authentication error'));
    const decoded = require('./middleware/authMiddleware').verifyToken(token);
    socket.user = decoded;
    next();
  } catch (err) {
    next(new Error('Invalid token'));
  }
});

// Socket.IO connection handler
io.of('/live-score').on('connection', (socket) => {
  socket.on('subscribe', (matchId) => {
    socket.join(`match:${matchId}`);
    console.log(`User ${socket.user.id} subscribed to match ${matchId}`);
  });

  socket.on('disconnect', () => {
    console.log(`User ${socket.user?.id} disconnected`);
  });
});

// ✅ Start server
const PORT = process.env.PORT || 5000;
httpServer.listen(PORT, () => console.log(`✅ Server running on http://localhost:${PORT}`));
