const pool = require("../config/db");
const jwt = require("jsonwebtoken");
require("dotenv").config();

// ========================
// REGISTER CAPTAIN
// ========================
const registerCaptain = async (req, res) => {
  const { phone_number, password, team_name, team_location } = req.body;

  if (!phone_number || !password || !team_name || !team_location) {
    return res.status(400).json({ error: "All fields are required" });
  }

  try {
    // Step 0: Check if phone number already exists
    const [existing] = await pool.query(
      "SELECT id FROM users WHERE phone_number = ?",
      [phone_number]
    );
    if (existing.length > 0) {
      return res.status(409).json({ error: "Phone number already registered" });
    }

    // Step 1: Create captain (user)
    const [userResult] = await pool.query(
      "INSERT INTO users (phone_number, password_hash) VALUES (?, ?)",
      [phone_number, password] // plain password stored in password_hash for now
    );

    const captainId = userResult.insertId;

    // Step 2: Create team linked with captain
    await pool.query(
      "INSERT INTO teams (team_name, team_location, matches_played, matches_won, trophies, captain_id) VALUES (?, ?, 0, 0, 0, ?)",
      [team_name, team_location, captainId]
    );

    res.status(201).json({ message: "Captain and team registered successfully" });
  } catch (err) {
    console.error("❌ Error in registerCaptain:", err);
    res.status(500).json({ error: "Server error", details: err.message });
  }
};

// ========================
// LOGIN CAPTAIN
// ========================
const loginCaptain = async (req, res) => {
  const { phone_number, password } = req.body;

  if (!phone_number || !password) {
    return res.status(400).json({ error: "Phone number and password are required" });
  }

  try {
    // 1️⃣ Find user
    const [rows] = await pool.query(
      "SELECT * FROM users WHERE phone_number = ?",
      [phone_number]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: "Captain not found" });
    }

    const user = rows[0];

    // 2️⃣ Check password (plain text for now)
    if (user.password_hash !== password) {
      return res.status(401).json({ error: "Invalid password" });
    }

    // 3️⃣ Create JWT
    const token = jwt.sign(
      { id: user.id, phone_number: user.phone_number },
      process.env.JWT_SECRET,
      { expiresIn: "1d" }
    );

    // 4️⃣ Respond
    res.json({
      message: "Login successful",
      token,
      captain: {
        id: user.id,
        phone_number: user.phone_number,
      },
    });
  } catch (err) {
    console.error("❌ Error in loginCaptain:", err);
    res.status(500).json({ error: "Server error", details: err.message });
  }
};

module.exports = { registerCaptain, loginCaptain };
