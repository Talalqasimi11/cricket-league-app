const { db } = require("../config/db");
require("dotenv").config();

const getMatchData = async (whereClause, params) => {
    const sql = `
    SELECT 
      m.id, m.status, m.match_datetime as match_date, m.venue, m.overs as max_overs,
      
      -- Tournament Info
      tr.id as tournament_id, tr.tournament_name,
      
      -- Team 1 Info
      t1.id as team1_id, t1.team_name as team1_name, t1.team_logo_url as team1_logo,
      
      -- Team 2 Info
      t2.id as team2_id, t2.team_name as team2_name, t2.team_logo_url as team2_logo,
      
      -- Inning 1 Data
      i1.id as i1_id, i1.batting_team_id as i1_batting_team, i1.runs as i1_runs, 
      i1.wickets as i1_wickets, i1.overs_decimal as i1_overs, i1.status as i1_status,
      
      -- Inning 2 Data
      i2.id as i2_id, i2.batting_team_id as i2_batting_team, i2.runs as i2_runs, 
      i2.wickets as i2_wickets, i2.overs_decimal as i2_overs, i2.status as i2_status,

      -- Current Status Helper
      CASE 
        WHEN m.status = 'completed' THEN 'Match Ended'
        WHEN i2.status = 'in_progress' THEN '2nd Innings'
        WHEN i1.status = 'in_progress' THEN '1st Innings'
        ELSE 'Not Started'
      END as match_phase

    FROM matches m
    LEFT JOIN teams t1 ON m.team1_id = t1.id
    LEFT JOIN teams t2 ON m.team2_id = t2.id
    LEFT JOIN tournaments tr ON m.tournament_id = tr.id
    -- Join specific innings based on inning_number
    LEFT JOIN match_innings i1 ON m.id = i1.match_id AND i1.inning_number = 1
    LEFT JOIN match_innings i2 ON m.id = i2.match_id AND i2.inning_number = 2
    ${whereClause}
    ORDER BY m.match_datetime DESC, m.id DESC
  `;

    console.log("Executing SQL...");
    const [rows] = await db.query(sql, params);
    return rows;
};

(async () => {
    try {
        console.log("Testing getAllMatches query with match_datetime...");
        const rows = await getMatchData("", []);
        console.log("Success! Rows fetched:", rows.length);
        process.exit(0);
    } catch (err) {
        console.error("❌ Error executing query:");
        console.error("Message:", err.message);
        console.error("SQL Message:", err.sqlMessage);
        process.exit(1);
    }
})();
