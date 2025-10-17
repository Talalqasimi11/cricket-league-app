const express = require("express");
const cors = require("cors");
const cookieParser = require("cookie-parser");
const pinoHttp = require("pino-http");
const { v4: uuidv4 } = require("uuid");
require("dotenv").config();
const validateEnv = require("./config/validateEnv");
const rateLimit = require("express-rate-limit");

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

validateEnv();

const app = express();
app.use(pinoHttp({
  redact: ['req.headers.authorization', 'req.headers.cookie', 'res.headers.set-cookie'],
  genReqId: (req) => req.headers['x-request-id'] || uuidv4(),
  serializers: {
    req(request) {
      // avoid logging bodies for auth endpoints
      const isAuth = request.url && request.url.startsWith('/api/auth');
      return {
        method: request.method,
        url: request.url,
        headers: request.headers,
        id: request.id,
        remoteAddress: request.socket?.remoteAddress,
        remotePort: request.socket?.remotePort,
        // only include body for non-auth
        body: isAuth ? undefined : request.raw && request.raw.body,
      };
    },
    res(response) {
      return { statusCode: response.statusCode, headers: response.getHeaders?.() };
    }
  }
}));
// Configure CORS: allow credentials and restrict origins explicitly via CORS_ORIGINS
let allowedOrigins = (process.env.CORS_ORIGINS || "").split(",").map(s => s.trim()).filter(Boolean);

// For development, auto-add common localhost origins if empty
if (process.env.NODE_ENV !== 'production' && allowedOrigins.length === 0) {
  allowedOrigins = [
    'http://localhost:3000',
    'http://localhost:5000',
    'http://localhost:8080', // Flutter web dev server
    'http://127.0.0.1:3000',
    'http://127.0.0.1:5000',
    'http://127.0.0.1:8080', // Flutter web dev server alternative
    'http://10.0.2.2:5000', // Android emulator
  ];
  console.log('⚠️  Development mode: Auto-adding localhost origins for CORS');
}

console.log('✅ CORS allowed origins:', allowedOrigins.length > 0 ? allowedOrigins.join(', ') : 'none (production requires CORS_ORIGINS)');
console.log('💡 For physical devices, add your computer\'s IP (e.g., http://192.168.1.100:5000) to CORS_ORIGINS env var');

app.use(cors({
  origin: (origin, callback) => {
    // Explicit allowlist only; when credentials are used, wildcard is not allowed
    if (!origin) return callback(null, true); // allow non-browser or same-origin
    if (allowedOrigins.includes(origin)) return callback(null, true);
    return callback(new Error('Not allowed by CORS'), false);
  },
  credentials: true,
}));
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

// Health check endpoint with DB ping
const db = require("./config/db");
app.get("/health", async (req, res) => {
  let dbOk = false;
  try {
    const conn = await db.getConnection();
    await conn.query("SELECT 1");
    conn.release();
    dbOk = true;
  } catch (_) {
    dbOk = false;
  }
  return res.status(200).json({ status: 'ok', version: process.env.APP_VERSION || 'dev', db: dbOk ? 'up' : 'down' });
});

// 404 handler
app.use((req, res) => res.status(404).json({ error: 'Not found' }));

// Error handler
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  req.log?.error(err);
  res.status(500).json({ error: 'Internal Server Error' });
});

// ✅ Start server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`✅ Server running on http://localhost:${PORT}`));
