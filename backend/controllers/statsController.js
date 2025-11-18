const { db } = require("../config/db");

/**
 * 📊 Get statistics overview for dashboard
 * Returns aggregated statistics across the entire platform
 */
const getStatsOverview = async (req, res) => {
  try {
    // Get total counts in parallel for better performance
    const [
      [totalMatches],
      [totalTeams],
      [totalTournaments],
      [totalPlayers],
      [activeTournaments],
      [topPlayers],
      [topTeams]
    ] = await Promise.all([
      // Total matches
      db.query("SELECT COUNT(*) as count FROM matches"),

      // Total teams
      db.query("SELECT COUNT(*) as count FROM teams"),

      // Total tournaments
      db.query("SELECT COUNT(*) as count FROM tournaments"),

      // Total players
      db.query("SELECT COUNT(*) as count FROM players"),

      // Active tournaments (not completed)
      db.query("SELECT COUNT(*) as count FROM tournaments WHERE status NOT IN ('completed', 'abandoned')"),

      // Top players by total runs (include all players, even those without stats)
      db.query(`
        SELECT
          p.player_name,
          p.id as player_id,
          COALESCE(SUM(pms.runs), 0) as runs,
          CASE
            WHEN COUNT(pms.runs) > 0 THEN COALESCE(AVG(pms.runs), 0)
            ELSE 0
          END as batting_average,
          COUNT(DISTINCT pms.match_id) as matches_played,
          CASE
            WHEN COALESCE(SUM(pms.balls_faced), 0) > 0
            THEN ROUND((COALESCE(SUM(pms.runs), 0) / SUM(pms.balls_faced)) * 100, 2)
            ELSE 0
          END as strike_rate
        FROM players p
        LEFT JOIN player_match_stats pms ON p.id = pms.player_id
        GROUP BY p.id, p.player_name
        ORDER BY runs DESC, matches_played DESC
        LIMIT 10
      `),

      // Top teams by matches won
      db.query(`
        SELECT
          team_name,
          id as team_id,
          matches_won,
          matches_played,
          trophies
        FROM teams
        ORDER BY matches_won DESC, trophies DESC
        LIMIT 10
      `)
    ]);

    const overview = {
      total_matches: totalMatches[0].count,
      total_teams: totalTeams[0].count,
      total_tournaments: totalTournaments[0].count,
      total_players: totalPlayers[0].count,
      active_tournaments: activeTournaments[0].count,
    };

    res.json({
      overview,
      top_players: topPlayers,
      top_teams: topTeams,
    });

  } catch (err) {
    console.error("Stats overview error:", err.message);
    console.error("Full error:", err);
    res.status(500).json({
      error: "Failed to retrieve statistics",
      details: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
  }
};

/**
 * 📊 Get detailed player statistics
 */
const getPlayerStats = async (req, res) => {
  try {
    const [players] = await db.query(`
      SELECT
        p.player_name,
        p.id as player_id,
        p.player_role,
        t.team_name,
        COALESCE(SUM(pms.runs), 0) as total_runs,
        COALESCE(SUM(pms.balls_faced), 0) as total_balls_faced,
        COALESCE(AVG(pms.runs), 0) as batting_average,
        CASE
          WHEN SUM(pms.balls_faced) > 0 THEN (SUM(pms.runs) / SUM(pms.balls_faced)) * 100
          ELSE 0
        END as strike_rate,
        COALESCE(SUM(pms.balls_bowled), 0) as balls_bowled,
        COALESCE(SUM(pms.runs_conceded), 0) as runs_conceded,
        COALESCE(SUM(pms.wickets), 0) as wickets_taken,
        COUNT(DISTINCT pms.match_id) as matches_played,
        COALESCE(SUM(pms.fours), 0) as fours,
        COALESCE(SUM(pms.sixes), 0) as sixes,
        COALESCE(SUM(pms.catches), 0) as catches,
        COALESCE(SUM(pms.stumpings), 0) as stumpings
      FROM players p
      LEFT JOIN teams t ON p.team_id = t.id
      LEFT JOIN player_match_stats pms ON p.id = pms.player_id
      GROUP BY p.id, p.player_name, p.player_role, t.team_name
      ORDER BY total_runs DESC, wickets_taken DESC
      LIMIT 50
    `);

    res.json({ players });
  } catch (err) {
    console.error("Player stats error:", err.message);
    console.error("Full error:", err);
    res.status(500).json({
      error: "Failed to retrieve player statistics",
      details: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
  }
};

/**
 * 📊 Get detailed team statistics
 */
const getTeamStats = async (req, res) => {
  try {
    const [teams] = await db.query(`
      SELECT
        t.team_name,
        t.id as team_id,
        t.matches_played,
        t.matches_won,
        t.trophies,
        COUNT(DISTINCT p.id) as total_players,
        COALESCE(AVG(pms_team.runs), 0) as avg_runs_per_match,
        COALESCE(SUM(pms_team.wickets), 0) as total_wickets_taken,
        CASE
          WHEN t.matches_played > 0 THEN (t.matches_won / t.matches_played) * 100
          ELSE 0
        END as win_percentage
      FROM teams t
      LEFT JOIN players p ON t.id = p.team_id
      LEFT JOIN player_match_stats pms_team ON p.id = pms_team.player_id
      GROUP BY t.id, t.team_name, t.matches_played, t.matches_won, t.trophies
      ORDER BY win_percentage DESC, matches_won DESC
      LIMIT 50
    `);

    res.json({ teams });
  } catch (err) {
    console.error("Team stats error:", err.message);
    console.error("Full error:", err);
    res.status(500).json({
      error: "Failed to retrieve team statistics",
      details: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
  }
};

module.exports = { getStatsOverview, getPlayerStats, getTeamStats };
