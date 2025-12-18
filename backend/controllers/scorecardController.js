const { db } = require("../config/db");
const { logDatabaseError } = require("../utils/safeLogger");

// ==========================================
// 🏏 SCORECARD CONTROLLER
// ==========================================

/**
 * 📌 Get Match Scorecard
 * Aggregates Match Info, Innings, Batting & Bowling stats into a unified response.
 */
const getMatchScorecard = async (req, res) => {
  const match_id = Number(req.params.match_id);

  if (!match_id || isNaN(match_id)) {
    return res.status(400).json({ error: "Invalid match_id" });
  }

  try {
    // 1. Fetch all necessary data in PARALLEL for performance
    const [
      matchResult,
      inningsResult,
      battingResult,
      bowlingResult
    ] = await Promise.all([
      // Query 1: Match Basic Info
      db.query(
        `SELECT m.id, m.status, m.overs as max_overs, m.match_date, m.venue,
                t1.id as team1_id, t1.team_name as team1_name, t1.team_logo_url as team1_logo,
                t2.id as team2_id, t2.team_name as team2_name, t2.team_logo_url as team2_logo,
                wt.id as winner_id, wt.team_name as winner_name
         FROM matches m
         LEFT JOIN teams t1 ON m.team1_id = t1.id
         LEFT JOIN teams t2 ON m.team2_id = t2.id
         LEFT JOIN teams wt ON m.winner_team_id = wt.id
         WHERE m.id = ?`, 
        [match_id]
      ),

      // Query 2: Innings List
      db.query(
        `SELECT mi.id, mi.inning_number, mi.batting_team_id, mi.bowling_team_id,
                mi.runs, mi.wickets, mi.overs_decimal as overs, mi.legal_balls
         FROM match_innings mi
         WHERE mi.match_id = ?
         ORDER BY mi.inning_number ASC`, 
        [match_id]
      ),

      // Query 3: Detailed Batting Stats
      db.query(
        `SELECT pms.player_id, p.player_name, p.team_id,
                pms.runs, pms.balls_faced, pms.fours, pms.sixes, pms.is_out,
                CASE 
                  WHEN pms.balls_faced > 0 
                  THEN ROUND((pms.runs / pms.balls_faced) * 100, 2) 
                  ELSE 0.00 
                END AS strike_rate
         FROM player_match_stats pms
         JOIN players p ON pms.player_id = p.id
         WHERE pms.match_id = ? AND pms.balls_faced > 0  -- Only show players who batted
         ORDER BY pms.runs DESC`, 
        [match_id]
      ),

      // Query 4: Detailed Bowling Stats
      db.query(
        `SELECT pms.player_id, p.player_name, p.team_id,
                pms.balls_bowled, pms.runs_conceded, pms.wickets, pms.maiden_overs,
                CASE 
                  WHEN pms.balls_bowled > 0 
                  THEN ROUND((pms.runs_conceded / pms.balls_bowled) * 6, 2) 
                  ELSE 0.00 
                END AS economy
         FROM player_match_stats pms
         JOIN players p ON pms.player_id = p.id
         WHERE pms.match_id = ? AND pms.balls_bowled > 0 -- Only show players who bowled
         ORDER BY pms.wickets DESC, economy ASC`, 
        [match_id]
      )
    ]);

    const matches = matchResult[0];
    if (matches.length === 0) {
      return res.status(404).json({ error: "Match not found" });
    }
    const matchData = matches[0];
    const inningsData = inningsResult[0];
    const battingData = battingResult[0];
    const bowlingData = bowlingResult[0];

    // 2. Construct the Scorecard Structure
    const scorecard = inningsData.map(inning => {
      const battingTeamId = inning.batting_team_id;
      const bowlingTeamId = inning.bowling_team_id;

      // Determine Names
      const battingTeamName = (battingTeamId === matchData.team1_id) 
          ? matchData.team1_name : matchData.team2_name;
      
      const bowlingTeamName = (bowlingTeamId === matchData.team1_id) 
          ? matchData.team1_name : matchData.team2_name;

      // Filter stats for this specific inning based on Team ID
      // Batting stats belong to the batting team
      const inningBatting = battingData.filter(p => p.team_id === battingTeamId);
      
      // Bowling stats belong to the bowling team
      const inningBowling = bowlingData.filter(p => p.team_id === bowlingTeamId);

      return {
        inning_number: inning.inning_number,
        header: {
          batting_team: battingTeamName,
          bowling_team: bowlingTeamName,
          score: `${inning.runs}/${inning.wickets}`,
          overs: `${inning.overs} (${matchData.max_overs})`
        },
        stats: {
          batters: inningBatting,
          bowlers: inningBowling
        }
      };
    });

    // 3. Final Response
    res.json({
      match_info: {
        id: matchData.id,
        status: matchData.status,
        result: matchData.winner_id ? `${matchData.winner_name} won` : "Match Tied/In Progress",
        date: matchData.match_date,
        venue: matchData.venue,
        teams: {
          team1: { name: matchData.team1_name, logo: matchData.team1_logo },
          team2: { name: matchData.team2_name, logo: matchData.team2_logo }
        }
      },
      scorecard: scorecard
    });

  } catch (err) {
    logDatabaseError(req.log, "getMatchScorecard", err, { match_id });
    res.status(500).json({ error: "Server error retrieving scorecard" });
  }
};

module.exports = { getMatchScorecard };