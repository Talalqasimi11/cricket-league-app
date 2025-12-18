const { db } = require("../config/db");
const { logDatabaseError } = require("../utils/safeLogger");

// ==========================================
// 📱 SOCIAL SHARING CONTROLLER
// ==========================================

/**
 * 📌 Get Match Summary Card
 * Generates a rich data payload for generating social media share images.
 * Returns: Tournament, Teams, Detailed Scores, Auto-generated Result Text, Top Performer.
 */
const getMatchSummaryCard = async (req, res) => {
  const { matchId } = req.params;

  if (!matchId) {
    return res.status(400).json({ error: "Match ID is required" });
  }

  try {
    // 🚀 Optimized Single Query using Common Table Expressions (CTE) & Window Functions
    const sql = `
      WITH TopPerformer AS (
        SELECT 
          p.player_name,
          pms.runs,
          pms.balls_faced,
          pms.wickets,
          pms.runs_conceded,
          (pms.runs + (pms.wickets * 20)) as fantasy_points
        FROM player_match_stats pms
        JOIN players p ON pms.player_id = p.id
        WHERE pms.match_id = ?
        ORDER BY fantasy_points DESC
        LIMIT 1
      )
      SELECT 
        m.id, m.status, m.match_date, m.venue,
        tr.tournament_name,
        
        -- Team Info
        t1.team_name as team1_name, t1.team_logo_url as team1_logo,
        t2.team_name as team2_name, t2.team_logo_url as team2_logo,
        
        -- Result Info
        m.winner_team_id,
        wt.team_name as winner_name,
        
        -- Innings Data (Pivot Logic)
        MAX(CASE WHEN mi.inning_number = 1 THEN mi.runs END) as inn1_runs,
        MAX(CASE WHEN mi.inning_number = 1 THEN mi.wickets END) as inn1_wickets,
        MAX(CASE WHEN mi.inning_number = 1 THEN mi.overs_decimal END) as inn1_overs,
        MAX(CASE WHEN mi.inning_number = 1 THEN mi.batting_team_id END) as inn1_batting_team,
        
        MAX(CASE WHEN mi.inning_number = 2 THEN mi.runs END) as inn2_runs,
        MAX(CASE WHEN mi.inning_number = 2 THEN mi.wickets END) as inn2_wickets,
        MAX(CASE WHEN mi.inning_number = 2 THEN mi.overs_decimal END) as inn2_overs,
        MAX(CASE WHEN mi.inning_number = 2 THEN mi.batting_team_id END) as inn2_batting_team,

        -- Top Player (Subquery)
        (SELECT player_name FROM TopPerformer) as mom_name,
        (SELECT runs FROM TopPerformer) as mom_runs,
        (SELECT wickets FROM TopPerformer) as mom_wickets

      FROM matches m
      LEFT JOIN tournaments tr ON m.tournament_id = tr.id
      LEFT JOIN teams t1 ON m.team1_id = t1.id
      LEFT JOIN teams t2 ON m.team2_id = t2.id
      LEFT JOIN teams wt ON m.winner_team_id = wt.id
      LEFT JOIN match_innings mi ON m.id = mi.match_id
      WHERE m.id = ?
      GROUP BY m.id
    `;

    const [rows] = await db.query(sql, [matchId, matchId]);

    if (rows.length === 0) {
      return res.status(404).json({ error: "Match not found" });
    }

    const data = rows[0];

    // Helper to format score string "145/3 (18.4)"
    const formatScore = (runs, wickets, overs) => {
      if (runs === null) return null;
      return `${runs}/${wickets} (${overs} ov)`;
    };

    // Generate intelligent result text
    let resultText = "Match in Progress";
    if (data.status === 'completed') {
      if (data.winner_team_id) {
        // Logic: Did they win by runs or wickets?
        if (data.winner_team_id === data.inn1_batting_team) {
          // Team batting first won -> Won by Runs
          const runDiff = (data.inn1_runs || 0) - (data.inn2_runs || 0);
          resultText = `${data.winner_name} won by ${runDiff} runs`;
        } else {
          // Team batting second won -> Won by Wickets
          const wicketsLeft = 10 - (data.inn2_wickets || 0);
          resultText = `${data.winner_name} won by ${wicketsLeft} wickets`;
        }
      } else {
        resultText = "Match Tied";
      }
    }

    // Construct rich response
    res.json({
      meta: {
        tournament: data.tournament_name || "Friendly Match",
        date: data.match_date,
        venue: data.venue,
        status: data.status
      },
      teams: {
        home: { name: data.team1_name, logo: data.team1_logo },
        away: { name: data.team2_name, logo: data.team2_logo }
      },
      scores: {
        first_innings: formatScore(data.inn1_runs, data.inn1_wickets, data.inn1_overs),
        second_innings: formatScore(data.inn2_runs, data.inn2_wickets, data.inn2_overs)
      },
      result: resultText,
      top_performer: data.mom_name ? {
        name: data.mom_name,
        display_stats: `${data.mom_runs} runs • ${data.mom_wickets} wkts`
      } : null
    });

  } catch (err) {
    logDatabaseError(req.log, "getMatchSummaryCard", err, { matchId });
    res.status(500).json({ error: "Server error generating summary" });
  }
};

module.exports = { getMatchSummaryCard };