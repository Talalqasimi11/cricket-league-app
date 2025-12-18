const { db } = require("../config/db");
const { logDatabaseError } = require("../utils/safeLogger");

// ==========================================
// 🏆 TOURNAMENT SUMMARY & STANDINGS
// ==========================================

/**
 * 📌 Get Tournament Standings
 * Returns a ranked list of teams based on wins, points, and matches played.
 * Handles both Registered Teams (linked to 'teams' table) and Temporary Teams.
 */
const getTournamentSummary = async (req, res) => {
  const { tournament_id } = req.params;

  if (!tournament_id) {
    return res.status(400).json({ error: "Tournament ID is required" });
  }

  try {
    // 1. Check if tournament exists
    const [tournCheck] = await db.query("SELECT id FROM tournaments WHERE id = ?", [tournament_id]);
    if (tournCheck.length === 0) {
      return res.status(404).json({ error: "Tournament not found" });
    }

    // 2. Fetch Standings
    // We join `tournament_teams` (the roster) with `teams` (details) 
    // and `team_tournament_summary` (stats).
    const sql = `
      SELECT 
        -- Identify Team (Registered ID vs Temp ID)
        tt.id as tournament_team_id,
        COALESCE(t.id, tt.id) AS team_id,
        
        -- Team Details
        COALESCE(t.team_name, tt.temp_team_name) AS team_name,
        COALESCE(t.team_location, tt.temp_team_location) AS team_location,
        t.team_logo_url, -- Only registered teams have logos
        
        -- Stats from Summary Table
        IFNULL(s.matches_played, 0) AS matches_played,
        IFNULL(s.matches_won, 0) AS matches_won,
        (IFNULL(s.matches_played, 0) - IFNULL(s.matches_won, 0)) AS matches_lost,
        IFNULL(s.points, 0) AS points,
        
        -- Flag for frontend UI logic
        CASE WHEN tt.team_id IS NULL THEN 1 ELSE 0 END AS is_temp_team

      FROM tournament_teams tt
      LEFT JOIN teams t ON tt.team_id = t.id
      LEFT JOIN team_tournament_summary s 
        ON tt.tournament_id = s.tournament_id 
        AND (s.team_id = t.id) -- Stats linked via real team ID
        
      WHERE tt.tournament_id = ?
      
      -- Ranking Logic: Points > Wins > Matches Played
      ORDER BY 
        points DESC, 
        matches_won DESC, 
        matches_played DESC,
        team_name ASC
    `;

    const [rows] = await db.query(sql, [tournament_id]);

    // 3. Data Enrichment (e.g. Calculate Points if missing in DB)
    // If your DB triggers don't auto-calculate points, we do it here for safety.
    const standings = rows.map(row => {
      // Default scoring: 2 points for a win
      const calculatedPoints = row.points > 0 ? row.points : (row.matches_won * 2);
      
      return {
        ...row,
        points: calculatedPoints,
        // Determine form/streak could go here in future
      };
    });

    res.json(standings);

  } catch (err) {
    logDatabaseError(req.log, "getTournamentSummary", err, { tournamentId: tournament_id });
    res.status(500).json({ error: "Server error retrieving standings" });
  }
};

module.exports = { getTournamentSummary };