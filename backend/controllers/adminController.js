const { db } = require("../config/db");
const { getUserFriendlyMessage, mapDatabaseError } = require("../utils/errorMessages");

// ========================
// 📊 DASHBOARD STATISTICS
// ========================
const getDashboardStats = async (req, res) => {
  try {
    // Run all count queries in parallel for better performance
    const [
      [userRows],
      [adminRows],
      [teamRows],
      [tournRows],
      [matchRows],
      [liveMatchRows]
    ] = await Promise.all([
      db.query("SELECT COUNT(*) as total FROM users"),
      db.query("SELECT COUNT(*) as total FROM users WHERE is_admin = TRUE"),
      db.query("SELECT COUNT(*) as total FROM teams"),
      db.query("SELECT COUNT(*) as total FROM tournaments"),
      db.query("SELECT COUNT(*) as total FROM matches"),
      db.query("SELECT COUNT(*) as total FROM matches WHERE status = 'live'")
    ]);

    res.json({
      totalUsers: userRows[0].total || 0,
      totalAdmins: adminRows[0].total || 0,
      totalTeams: teamRows[0].total || 0,
      totalTournaments: tournRows[0].total || 0,
      totalMatches: matchRows[0].total || 0,
      totalLiveMatches: liveMatchRows[0].total || 0
    });
  } catch (err) {
    console.error("getDashboardStats: Unexpected error", { error: err.message });
    res.status(500).json({ error: "Server error retrieving stats" });
  }
};

// ========================
// 👥 USER MANAGEMENT
// ========================
const getAllUsers = async (req, res) => {
  try {
    const [users] = await db.query(`
      SELECT 
        u.id, 
        u.phone_number, 
        u.is_admin,
        t.team_name,
        t.team_location
      FROM users u
      LEFT JOIN teams t ON u.id = t.owner_id
      ORDER BY u.id DESC
    `);

    res.json(users);
  } catch (err) {
    console.error("getAllUsers: Database error", { error: err.message });
    res.status(500).json({ error: "Server error retrieving users" });
  }
};

const updateUserAdminStatus = async (req, res) => {
  const { userId } = req.params;
  const { is_admin } = req.body;

  if (typeof is_admin !== 'boolean') {
    return res.status(400).json({ error: "is_admin must be a boolean value" });
  }

  try {
    // Check if user exists and prevent self-demotion
    const [userCheck] = await db.query("SELECT id FROM users WHERE id = ?", [userId]);

    if (userCheck.length === 0) {
      return res.status(404).json({ error: "User not found" });
    }

    if (req.user.id === parseInt(userId) && !is_admin) {
      return res.status(400).json({ error: "Cannot remove your own admin privileges" });
    }

    await db.query("UPDATE users SET is_admin = ? WHERE id = ?", [is_admin, userId]);

    res.json({
      message: `User admin status updated to ${is_admin ? 'admin' : 'regular user'}`,
      user_id: userId,
      is_admin
    });
  } catch (err) {
    console.error("updateUserAdminStatus: Database error", { error: err.message });
    res.status(500).json({ error: "Server error updating user" });
  }
};

const deleteUser = async (req, res) => {
  const { userId } = req.params;

  try {
    const [userCheck] = await db.query("SELECT id, is_admin FROM users WHERE id = ?", [userId]);

    if (userCheck.length === 0) {
      return res.status(404).json({ error: "User not found" });
    }

    if (req.user.id === parseInt(userId)) {
      return res.status(400).json({ error: "Cannot delete your own account" });
    }

    if (userCheck[0].is_admin) {
      return res.status(403).json({ error: "Cannot delete other admin users" });
    }

    await db.query("DELETE FROM users WHERE id = ?", [userId]);

    res.json({ message: "User deleted successfully", user_id: userId });
  } catch (err) {
    console.error("deleteUser: Database error", { error: err.message });
    res.status(500).json({ error: "Server error deleting user" });
  }
};

// ========================
// 🛡️ TEAM MANAGEMENT
// ========================
const getAllTeams = async (req, res) => {
  try {
    const [teams] = await db.query(`
      SELECT 
        t.id,
        t.team_name,
        t.team_location,
        t.team_logo_url,
        t.matches_played,
        t.matches_won,
        t.trophies,
        u.phone_number as owner_phone,
        u.is_admin as owner_is_admin,
        COUNT(p.id) as player_count
      FROM teams t
      LEFT JOIN users u ON t.owner_id = u.id
      LEFT JOIN players p ON t.id = p.team_id
      GROUP BY t.id
      ORDER BY t.id DESC
    `);

    res.json(teams);
  } catch (err) {
    console.error("getAllTeams: Database error", { error: err.message });
    res.status(500).json({ error: "Server error retrieving teams" });
  }
};

const getTeamDetails = async (req, res) => {
  const { teamId } = req.params;

  try {
    const [teamResult] = await db.query(`
      SELECT t.*, u.phone_number as owner_phone, u.is_admin as owner_is_admin
      FROM teams t
      LEFT JOIN users u ON t.owner_id = u.id
      WHERE t.id = ?
    `, [teamId]);

    if (teamResult.length === 0) {
      return res.status(404).json({ error: "Team not found" });
    }

    const [players] = await db.query(`
      SELECT id, player_name, player_role, player_image_url, runs, matches_played, 
             hundreds, fifties, batting_average, strike_rate, wickets 
      FROM players WHERE team_id = ? ORDER BY player_name
    `, [teamId]);

    res.json({ team: teamResult[0], players });
  } catch (err) {
    console.error("getTeamDetails: Database error", { error: err.message });
    res.status(500).json({ error: "Server error retrieving team details" });
  }
};

const updateTeam = async (req, res) => {
  const { teamId } = req.params;
  const { team_name, team_location, team_logo_url } = req.body;

  if (!team_name || !team_location) {
    return res.status(400).json({ error: "Team name and location are required" });
  }

  try {
    const [result] = await db.query(
      "UPDATE teams SET team_name = ?, team_location = ?, team_logo_url = ? WHERE id = ?",
      [team_name, team_location, team_logo_url || null, teamId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Team not found" });
    }

    res.json({
      message: "Team updated successfully",
      team: { id: teamId, team_name, team_location, team_logo_url }
    });
  } catch (err) {
    console.error("updateTeam: Database error", { error: err.message });
    res.status(500).json({ error: "Server error updating team" });
  }
};

const deleteTeam = async (req, res) => {
  const { teamId } = req.params;

  try {
    // Check for existing matches to prevent data integrity issues
    const [matchCheck] = await db.query(`
      SELECT COUNT(*) as count FROM matches WHERE team1_id = ? OR team2_id = ?
    `, [teamId, teamId]);

    if (matchCheck[0].count > 0) {
      return res.status(400).json({
        error: "Cannot delete team with existing matches. Archive it instead."
      });
    }

    const [result] = await db.query("DELETE FROM teams WHERE id = ?", [teamId]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Team not found" });
    }

    res.json({ message: "Team deleted successfully", team_id: teamId });
  } catch (err) {
    console.error("deleteTeam: Database error", { error: err.message });
    res.status(500).json({ error: "Server error deleting team" });
  }
};

// ========================
// 🏆 TOURNAMENT MANAGEMENT
// ========================
const getAllTournaments = async (req, res) => {
  try {
    const [tournaments] = await db.query(`
      SELECT 
        t.id, t.tournament_name, t.start_date, t.end_date, t.status, t.location, 
        t.created_by, u.phone_number as creator_phone,
        (SELECT COUNT(*) FROM tournament_teams WHERE tournament_id = t.id) as team_count
      FROM tournaments t
      LEFT JOIN users u ON t.created_by = u.id
      ORDER BY t.start_date DESC
    `);

    res.json(tournaments);
  } catch (err) {
    console.error("getAllTournaments: Database error", { error: err.message });
    res.status(500).json({ error: "Server error retrieving tournaments" });
  }
};

const deleteTournament = async (req, res) => {
  const { tournamentId } = req.params;

  try {
    const [result] = await db.query("DELETE FROM tournaments WHERE id = ?", [tournamentId]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Tournament not found" });
    }

    res.json({ message: "Tournament deleted successfully", tournament_id: tournamentId });
  } catch (err) {
    console.error("deleteTournament: Database error", { error: err.message });
    res.status(500).json({ error: "Server error deleting tournament" });
  }
};

// ========================
// 🏏 MATCH MANAGEMENT
// ========================
const getAllMatches = async (req, res) => {
  try {
    const { status } = req.query;
    let query = `
      SELECT 
        m.id, m.status, m.overs, m.match_datetime as match_date, m.venue, m.winner_team_id,
        t1.team_name as team1_name, t2.team_name as team2_name,
        tr.tournament_name,
        (SELECT COUNT(*) FROM match_innings WHERE match_id = m.id) as innings_count
      FROM matches m
      LEFT JOIN teams t1 ON m.team1_id = t1.id
      LEFT JOIN teams t2 ON m.team2_id = t2.id
      LEFT JOIN tournaments tr ON m.tournament_id = tr.id
    `;

    const params = [];
    if (status) {
      query += " WHERE m.status = ?";
      params.push(status);
    }

    query += " ORDER BY m.id DESC LIMIT 100";

    const [matches] = await db.query(query, params);
    res.json(matches);
  } catch (err) {
    console.error("getAllMatches: Database error", { error: err.message });
    res.status(500).json({ error: "Server error retrieving matches" });
  }
};

const getMatchDetails = async (req, res) => {
  const { matchId } = req.params;
  try {
    const [matchResult] = await db.query(`
      SELECT m.*, m.match_datetime as match_date, t1.team_name as team1_name, t2.team_name as team2_name,
             tr.tournament_name, wt.team_name as winner_name
      FROM matches m
      LEFT JOIN teams t1 ON m.team1_id = t1.id
      LEFT JOIN teams t2 ON m.team2_id = t2.id
      LEFT JOIN teams wt ON m.winner_team_id = wt.id
      LEFT JOIN tournaments tr ON m.tournament_id = tr.id
      WHERE m.id = ?
    `, [matchId]);

    if (matchResult.length === 0) {
      return res.status(404).json({ error: "Match not found" });
    }

    const [innings] = await db.query(`
      SELECT mi.*, t.team_name as batting_team_name 
      FROM match_innings mi 
      LEFT JOIN teams t ON mi.batting_team_id = t.id
      WHERE match_id = ? ORDER BY inning_number
    `, [matchId]);

    const [balls] = await db.query("SELECT COUNT(*) as count FROM ball_by_ball WHERE match_id = ?", [matchId]);

    res.json({
      match: matchResult[0],
      innings,
      total_balls: balls[0].count
    });
  } catch (err) {
    console.error("getMatchDetails: Database error", { error: err.message });
    res.status(500).json({ error: "Server error retrieving match details" });
  }
};

const createMatch = async (req, res) => {
  const { tournament_id, team1_id, team2_id, match_date, venue, overs } = req.body;

  if (!team1_id || !team2_id || !match_date || !venue || !overs) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  if (team1_id === team2_id) {
    return res.status(400).json({ error: "Team 1 and Team 2 must be different" });
  }

  try {
    const [result] = await db.query(
      `INSERT INTO matches (tournament_id, team1_id, team2_id, match_datetime, venue, status, overs) 
       VALUES (?, ?, ?, ?, ?, 'not_started', ?)`,
      [tournament_id || null, team1_id, team2_id, match_date, venue, overs]
    );

    res.status(201).json({
      message: "Match created successfully",
      match_id: result.insertId
    });
  } catch (err) {
    console.error("createMatch: Database error", { error: err.message });
    res.status(500).json({ error: "Server error creating match" });
  }
};

const updateMatch = async (req, res) => {
  const { matchId } = req.params;
  const { status, overs, winner_team_id } = req.body;

  try {
    const updates = [];
    const values = [];

    if (status) { updates.push("status = ?"); values.push(status); }
    if (overs !== undefined) { updates.push("overs = ?"); values.push(overs); }
    if (winner_team_id !== undefined) { updates.push("winner_team_id = ?"); values.push(winner_team_id); }

    if (updates.length === 0) {
      return res.status(400).json({ error: "No valid fields to update" });
    }

    values.push(matchId);

    const [result] = await db.query(`UPDATE matches SET ${updates.join(", ")} WHERE id = ?`, values);

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Match not found" });
    }

    res.json({ message: "Match updated successfully", match_id: matchId });
  } catch (err) {
    console.error("updateMatch: Database error", { error: err.message });
    res.status(500).json({ error: "Server error updating match" });
  }
};

const deleteMatch = async (req, res) => {
  const { matchId } = req.params;
  try {
    const [result] = await db.query("DELETE FROM matches WHERE id = ?", [matchId]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Match not found" });
    }

    res.json({ message: "Match deleted successfully" });
  } catch (err) {
    console.error("deleteMatch: Database error", { error: err.message });
    res.status(500).json({ error: "Server error deleting match" });
  }
};

module.exports = {
  getDashboardStats,
  getAllUsers,
  updateUserAdminStatus,
  deleteUser,
  getAllTeams,
  getTeamDetails,
  updateTeam,
  deleteTeam,
  getAllTournaments,
  deleteTournament,
  getAllMatches,
  getMatchDetails,
  createMatch,
  updateMatch,
  deleteMatch
};