const express = require("express");
const cors = require("cors");
require("dotenv").config();

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

const app = express();
app.use(cors());
app.use(express.json());

// ✅ Routes
app.use("/api/tournament-summary", teamTournamentSummaryRoutes);
app.use("/api/player-stats", playerStatsRoutes);
const ballByBallRoutes = require("./routes/ballByBallRoutes");
app.use("/api/deliveries", ballByBallRoutes);
const liveScoreViewerRoutes = require("./routes/liveScoreViewerRoutes");
app.use("/api/viewer/live-score", liveScoreViewerRoutes);
const scorecardRoutes = require("./routes/scorecardRoutes");
app.use("/api/viewer/scorecard", scorecardRoutes);

app.use("/api/auth", authRoutes);
app.use("/api/teams", teamRoutes);
// app.use("/api/matches", matchRoutes);
app.use("/api/players", playerRoutes);
app.use("/api/tournaments", tournamentRoutes);
app.use("/api/tournament-teams", tournamentTeamRoutes);
app.use("/api/tournament-matches", tournamentMatchRoutes); // ✅ Register here
app.use("/api/live", liveScoreRoutes);

// ✅ Start server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`✅ Server running on http://localhost:${PORT}`));
