const db = require("../config/db");

/**
 * 📌 Get Tournament Standings
 */
const getTournamentSummary = async (req, res) => {
  const { tournament_id } = req.params;

  try {
    const [rows] = await db.query(
      `SELECT 
         COALESCE(t.id, tt.id) AS team_id,
         COALESCE(t.team_name, tt.temp_team_name) AS team_name,
         COALESCE(t.team_location, tt.temp_team_location) AS team_location,
         IFNULL(s.matches_played, 0) AS matches_played,
         IFNULL(s.matches_won, 0) AS matches_won,
         (IFNULL(s.matches_played, 0) - IFNULL(s.matches_won, 0)) AS matches_lost,
         CASE WHEN tt.team_id IS NULL THEN 1 ELSE 0 END AS is_temp
       FROM tournament_teams tt
       LEFT JOIN teams t ON tt.team_id = t.id
       LEFT JOIN team_tournament_summary s 
         ON tt.tournament_id = s.tournament_id AND tt.team_id = s.team_id
       WHERE tt.tournament_id = ?
       ORDER BY IFNULL(s.matches_won, 0) DESC, IFNULL(s.matches_played, 0) DESC`,
      [tournament_id]
    );

    res.json(rows);
  } catch (err) {
    console.error("❌ Error in getTournamentSummary:", err);
    res.status(500).json({ error: "Server error" });
  }
};

module.exports = { getTournamentSummary };
