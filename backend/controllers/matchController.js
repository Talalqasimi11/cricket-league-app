const db = require("../config/db");

// Create Match
exports.createMatch = async (req, res) => {
  try {
    const { tournament_id, team1_id, team2_id, overs } = req.body;

    const [result] = await db.query(
      `INSERT INTO matches (tournament_id, team1_id, team2_id, overs, status)
       VALUES (?, ?, ?, ?, 'live')`,
      [tournament_id, team1_id, team2_id, overs]
    );

    res.status(201).json({ message: "Match created", match_id: result.insertId });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Error creating match" });
  }
};

// Get All Matches
exports.getAllMatches = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT m.match_id, m.overs, m.status, 
              t1.team_name AS team1, 
              t2.team_name AS team2,
              m.winner_team_id
       FROM matches m
       JOIN teams t1 ON m.team1_id = t1.team_id
       JOIN teams t2 ON m.team2_id = t2.team_id`
    );

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Error fetching matches" });
  }
};
