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
const allowedOrigins = (process.env.CORS_ORIGINS || "").split(",").map(s => s.trim()).filter(Boolean);
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

// Rate limiter for login
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
});

// ✅ Routes
app.use("/api/tournament-summary", teamTournamentSummaryRoutes);
app.use("/api/player-stats", playerStatsRoutes);
const ballByBallRoutes = require("./routes/ballByBallRoutes");
app.use("/api/deliveries", ballByBallRoutes);
const liveScoreViewerRoutes = require("./routes/liveScoreViewerRoutes");
app.use("/api/viewer/live-score", liveScoreViewerRoutes);
const scorecardRoutes = require("./routes/scorecardRoutes");
app.use("/api/viewer/scorecard", scorecardRoutes);

// Mount auth with rate-limited login
app.use("/api/auth", (req, res, next) => {
  if (req.path === '/login') return loginLimiter(req, res, next);
  return next();
}, authRoutes);
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
