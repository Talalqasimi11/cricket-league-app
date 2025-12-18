const { db } = require("../config/db");

/**
 * 📊 Get statistics overview for dashboard
 */
const getStatsOverview = async (req, res) => {
  try {
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

      // Active tournaments
      db.query("SELECT COUNT(*) as count FROM tournaments WHERE status NOT IN ('completed', 'abandoned')"),

      // ✅ FIXED: Fetch stats DIRECTLY from players table (User manual edits)
      db.query(`
        SELECT 
          player_name,
          id as player_id,
          runs,
          batting_average,
          matches_played,
          strike_rate,
          player_image_url
        FROM players 
        ORDER BY runs DESC, matches_played DESC 
        LIMIT 10
      `),

      // ✅ FIXED: Fetch stats DIRECTLY from teams table
      db.query(`
        SELECT 
          team_name,
          id as team_id,
          matches_won,
          matches_played,
          trophies,
          team_logo_url
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
    res.status(500).json({ error: "Failed to retrieve statistics" });
  }
};

/**
 * 📊 Get detailed player statistics
 */
const getPlayerStats = async (req, res) => {
  try {
    // ✅ FIXED: Removed JOIN with player_match_stats
    // Now selects columns directly from 'players' table
    const [players] = await db.query(`
      SELECT 
        p.player_name,
        p.id as player_id,
        p.player_role,
        t.team_name,
        p.runs as total_runs,
        p.matches_played,
        p.batting_average,
        p.strike_rate,
        p.wickets as wickets_taken,
        p.hundreds,
        p.fifties,
        p.player_image_url
      FROM players p
      LEFT JOIN teams t ON p.team_id = t.id
      ORDER BY p.runs DESC, p.wickets DESC
      LIMIT 50
    `);

    res.json({ players });
  } catch (err) {
    console.error("Player stats error:", err.message);
    res.status(500).json({ error: "Failed to retrieve player statistics" });
  }
};

/**
 * 📊 Get detailed team statistics
 */
const getTeamStats = async (req, res) => {
  try {
    // ✅ FIXED: Select directly from teams table columns
    const [teams] = await db.query(`
      SELECT 
        t.team_name,
        t.id as team_id,
        t.matches_played,
        t.matches_won,
        t.trophies,
        t.team_logo_url,
        (SELECT COUNT(*) FROM players WHERE team_id = t.id) as total_players,
        CASE 
          WHEN t.matches_played > 0 THEN (t.matches_won / t.matches_played) * 100 
          ELSE 0 
        END as win_percentage
      FROM teams t
      ORDER BY t.matches_won DESC, t.trophies DESC
      LIMIT 50
    `);

    res.json({ teams });
  } catch (err) {
    console.error("Team stats error:", err.message);
    res.status(500).json({ error: "Failed to retrieve team statistics" });
  }
};

module.exports = { getStatsOverview, getPlayerStats, getTeamStats };