const db = require("../config/db");
const { getUserFriendlyMessage, mapDatabaseError } = require("../utils/errorMessages");

// ========================
// DASHBOARD STATISTICS
// ========================
const getDashboardStats = async (req, res) => {
  try {
    let totalUsers = 0;
    let totalAdmins = 0;
    let totalTeams = 0;
    let totalTournaments = 0;
    let totalMatches = 0;

    // Get user count
    try {
      const [userCountResult] = await db.query("SELECT COUNT(*) as total_users FROM users");
      totalUsers = userCountResult[0].total_users;
    } catch (err) {
      console.log('Warning: Could not get user count:', err.message);
    }

    // Get admin count
    try {
      const [adminCountResult] = await db.query("SELECT COUNT(*) as total_admins FROM users WHERE is_admin = TRUE");
      totalAdmins = adminCountResult[0].total_admins;
    } catch (err) {
      console.log('Warning: Could not get admin count:', err.message);
    }

    // Get team count
    try {
      const [teamCountResult] = await db.query("SELECT COUNT(*) as total_teams FROM teams");
      totalTeams = teamCountResult[0].total_teams;
    } catch (err) {
      console.log('Warning: Could not get team count:', err.message);
    }

    // Get tournament count
    try {
      const [tournamentCountResult] = await db.query("SELECT COUNT(*) as total_tournaments FROM tournaments");
      totalTournaments = tournamentCountResult[0].total_tournaments;
    } catch (err) {
      console.log('Warning: Could not get tournament count:', err.message);
    }

    // Get match count
    try {
      const [matchCountResult] = await db.query("SELECT COUNT(*) as total_matches FROM matches");
      totalMatches = matchCountResult[0].total_matches;
    } catch (err) {
      console.log('Warning: Could not get match count:', err.message);
    }

    res.json({
      totalUsers,
      totalAdmins,
      totalTeams,
      totalTournaments,
      totalMatches
    });
  } catch (err) {
    console.error("getDashboardStats: Unexpected error", { error: err.message });
    res.status(500).json({ error: "Server error" });
  }
};

// ========================
// USER MANAGEMENT
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
    req.log?.error("getAllUsers: Database error", { error: err.message });
    res.status(500).json({ error: "Server error" });
  }
};

const updateUserAdminStatus = async (req, res) => {
  const { userId } = req.params;
  const { is_admin } = req.body;

  if (typeof is_admin !== 'boolean') {
    return res.status(400).json({ error: "is_admin must be a boolean value" });
  }

  try {
    // Check if user exists
    const [userCheck] = await db.query("SELECT id FROM users WHERE id = ?", [userId]);
    if (userCheck.length === 0) {
      return res.status(404).json({ error: "User not found" });
    }

    // Prevent admin from removing their own admin status
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
    req.log?.error("updateUserAdminStatus: Database error", { error: err.message });
    res.status(500).json({ error: "Server error" });
  }
};

const deleteUser = async (req, res) => {
  const { userId } = req.params;

  try {
    // Check if user exists
    const [userCheck] = await db.query("SELECT id, is_admin FROM users WHERE id = ?", [userId]);
    if (userCheck.length === 0) {
      return res.status(404).json({ error: "User not found" });
    }

    // Prevent admin from deleting themselves
    if (req.user.id === parseInt(userId)) {
      return res.status(400).json({ error: "Cannot delete your own account" });
    }

    // Check if user is admin
    if (userCheck[0].is_admin) {
      return res.status(400).json({ error: "Cannot delete admin users" });
    }

    // Delete user (cascade will handle related data)
    await db.query("DELETE FROM users WHERE id = ?", [userId]);

    res.json({ 
      message: "User deleted successfully",
      user_id: userId 
    });
  } catch (err) {
    req.log?.error("deleteUser: Database error", { error: err.message });
    res.status(500).json({ error: "Server error" });
  }
};

// ========================
// TEAM MANAGEMENT
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
    req.log?.error("getAllTeams: Database error", { error: err.message });
    res.status(500).json({ error: "Server error" });
  }
};

const getTeamDetails = async (req, res) => {
  const { teamId } = req.params;

  try {
    // Get team info
    const [teamResult] = await db.query(`
      SELECT 
        t.*,
        u.phone_number as owner_phone,
        u.is_admin as owner_is_admin
      FROM teams t
      LEFT JOIN users u ON t.owner_id = u.id
      WHERE t.id = ?
    `, [teamId]);

    if (teamResult.length === 0) {
      return res.status(404).json({ error: "Team not found" });
    }

    // Get players
    const [players] = await db.query(`
      SELECT 
        id,
        player_name,
        player_role,
        player_image_url,
        runs,
        matches_played,
        hundreds,
        fifties,
        batting_average,
        strike_rate,
        wickets
      FROM players 
      WHERE team_id = ?
      ORDER BY player_name
    `, [teamId]);

    res.json({
      team: teamResult[0],
      players
    });
  } catch (err) {
    req.log?.error("getTeamDetails: Database error", { error: err.message });
    res.status(500).json({ error: "Server error" });
  }
};

const updateTeam = async (req, res) => {
  const { teamId } = req.params;
  const { team_name, team_location, team_logo_url } = req.body;

  if (!team_name || !team_location) {
    return res.status(400).json({ error: "Team name and location are required" });
  }

  try {
    // Check if team exists
    const [teamCheck] = await db.query("SELECT id FROM teams WHERE id = ?", [teamId]);
    if (teamCheck.length === 0) {
      return res.status(404).json({ error: "Team not found" });
    }

    await db.query(
      "UPDATE teams SET team_name = ?, team_location = ?, team_logo_url = ? WHERE id = ?",
      [team_name, team_location, team_logo_url || null, teamId]
    );

    res.json({ 
      message: "Team updated successfully",
      team_id: teamId,
      team_name,
      team_location,
      team_logo_url
    });
  } catch (err) {
    req.log?.error("updateTeam: Database error", { error: err.message });
    res.status(500).json({ error: "Server error" });
  }
};

const deleteTeam = async (req, res) => {
  const { teamId } = req.params;

  try {
    // Check if team exists
    const [teamCheck] = await db.query("SELECT id FROM teams WHERE id = ?", [teamId]);
    if (teamCheck.length === 0) {
      return res.status(404).json({ error: "Team not found" });
    }

    // Check if team has any matches (optional safety check)
    const [matchCheck] = await db.query(`
      SELECT COUNT(*) as match_count FROM matches 
      WHERE team1_id = ? OR team2_id = ?
    `, [teamId, teamId]);

    if (matchCheck[0].match_count > 0) {
      return res.status(400).json({ 
        error: "Cannot delete team with existing matches. Consider archiving instead." 
      });
    }

    // Delete team (cascade will handle related data)
    await db.query("DELETE FROM teams WHERE id = ?", [teamId]);

    res.json({ 
      message: "Team deleted successfully",
      team_id: teamId 
    });
  } catch (err) {
    req.log?.error("deleteTeam: Database error", { error: err.message });
    res.status(500).json({ error: "Server error" });
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
  deleteTeam
};
