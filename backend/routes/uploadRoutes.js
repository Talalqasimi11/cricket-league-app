// backend/routes/uploadRoutes.js
const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { db } = require('../config/db');

// --- 1. Configure Storage Engine ---
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    // Use path.join to ensure we create the folder in the correct place relative to this file
    // This goes up one level (..) to backend, then creates 'uploads'
    let uploadPath = path.join(__dirname, '../uploads');

    // Determine folder based on the API route used
    if (req.originalUrl.includes('/player')) {
      uploadPath = path.join(uploadPath, 'player');
    } else if (req.originalUrl.includes('/team')) {
      uploadPath = path.join(uploadPath, 'team');
    } else {
      uploadPath = path.join(uploadPath, 'others');
    }

    // Create directory if it doesn't exist (recursive: true handles parent folders too)
    if (!fs.existsSync(uploadPath)) {
      fs.mkdirSync(uploadPath, { recursive: true });
    }

    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    // Unique filename: fieldname-timestamp-random.ext
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, file.fieldname + '-' + uniqueSuffix + ext);
  }
});

// --- 2. File Filter (Security) ---
const fileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Only image files are allowed!'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 } // 5MB limit
});

// --- 3. Routes ---

// ✅ PLAYER Upload Route
// POST /api/uploads/player/:id
router.post('/player/:id', upload.single('photo'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No file uploaded' });

    const playerId = req.params.id;

    // Store the URL path (accessible from frontend)
    // We use forward slashes / for URLs regardless of OS
    const imageUrl = `/uploads/player/${req.file.filename}`;

    // Update the Player record in DB directly
    await db.query('UPDATE players SET player_image_url = ? WHERE id = ?', [imageUrl, playerId]);

    res.json({
      message: 'Player photo uploaded successfully',
      imageUrl: imageUrl
    });
  } catch (err) {
    console.error("Upload Error:", err);
    res.status(500).json({ error: 'Server error during upload' });
  }
});

// ✅ TEAM Upload Route
// POST /api/uploads/team/:id
router.post('/team/:id', upload.single('logo'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No file uploaded' });

    const teamId = req.params.id;
    const imageUrl = `/uploads/team/${req.file.filename}`;

    // Update the Team record in DB directly
    await db.query('UPDATE teams SET team_logo_url = ? WHERE id = ?', [imageUrl, teamId]);

    res.json({
      message: 'Team logo uploaded successfully',
      imageUrl: imageUrl
    });
  } catch (err) {
    console.error("Upload Error:", err);
    res.status(500).json({ error: 'Server error during upload' });
  }
});

// ✅ TEMP Upload Route (for creation flows)
// POST /api/uploads/temp
router.post('/temp', upload.single('file'), (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No file uploaded' });

    const imageUrl = `/uploads/others/${req.file.filename}`;

    res.json({
      message: 'File uploaded successfully',
      imageUrl: imageUrl
    });
  } catch (err) {
    console.error("Upload Error:", err);
    res.status(500).json({ error: 'Server error during upload' });
  }
});

module.exports = router;