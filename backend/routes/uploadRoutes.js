const express = require('express');
const router = express.Router();
const { upload, uploadDirs, processAndSaveImage, deleteImage, getImageUrl } = require('../utils/uploadUtils');
const { verifyToken } = require('../middleware/authMiddleware');

/**
 * Upload player photo
 * POST /api/uploads/player/:playerId
 */
router.post('/player/:playerId', verifyToken, upload.single('photo'), async (req, res) => {
  try {
    const { playerId } = req.params;
    const { db } = require('../config/db');

    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    if (!playerId || isNaN(playerId)) {
      return res.status(400).json({ error: 'Invalid player ID' });
    }

    // Get current player data to delete old image if exists
    const conn = await db.getConnection();
    try {
      const rows = await conn.query('SELECT image_url FROM players WHERE id = ?', [playerId]);
      if (rows.length > 0 && rows[0].image_url) {
        deleteImage(rows[0].image_url);
      }

      // Process and save new image
      const imagePath = await processAndSaveImage(
        req.file.buffer,
        uploadDirs.players,
        req.file.originalname
      );

      // Update player record with new image path
      await conn.query('UPDATE players SET image_url = ? WHERE id = ?', [imagePath, playerId]);

      const baseUrl = `${req.protocol}://${req.get('host')}`;
      const imageUrl = getImageUrl(imagePath, baseUrl);

      res.json({
        message: 'Player photo uploaded successfully',
        imagePath,
        imageUrl,
      });
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('Player photo upload error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * Upload team photo/logo
 * POST /api/uploads/team/:teamId
 */
router.post('/team/:teamId', verifyToken, upload.single('logo'), async (req, res) => {
  try {
    const { teamId } = req.params;
    const { db } = require('../config/db');

    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    if (!teamId || isNaN(teamId)) {
      return res.status(400).json({ error: 'Invalid team ID' });
    }

    const conn = await db.getConnection();
    try {
      // Get current team data to delete old image if exists
      const rows = await conn.query('SELECT logo_url FROM teams WHERE id = ?', [teamId]);
      if (rows.length > 0 && rows[0].logo_url) {
        deleteImage(rows[0].logo_url);
      }

      // Process and save new image
      const imagePath = await processAndSaveImage(
        req.file.buffer,
        uploadDirs.teams,
        req.file.originalname
      );

      // Update team record with new image path
      await conn.query('UPDATE teams SET logo_url = ? WHERE id = ?', [imagePath, teamId]);

      const baseUrl = `${req.protocol}://${req.get('host')}`;
      const imageUrl = getImageUrl(imagePath, baseUrl);

      res.json({
        message: 'Team logo uploaded successfully',
        imagePath,
        imageUrl,
      });
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('Team logo upload error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * Get image by path
 * GET /api/uploads/:imagePath
 */
// TODO: Fix route syntax for catch-all in this Express/path-to-regexp version
// router.get('/**', (req, res) => {
//   try {
//     const imagePath = req.path.substring(1); // Remove leading slash
//     const fullPath = imagePath.replace(/^\//, ''); // Remove leading slash if any

//     // Security: prevent path traversal
//     if (fullPath.includes('..') || fullPath.startsWith('/')) {
//       return res.status(403).json({ error: 'Invalid path' });
//     }

//     const fs = require('fs');
//     const path = require('path');

//     const filePath = path.join(__dirname, '..', fullPath);

//     // Verify the file exists and is in allowed directories
//     const realPath = fs.realpathSync(filePath);
//     const allowedBasePaths = Object.values(uploadDirs).map(dir =>
//       fs.realpathSync(path.join(__dirname, '..', dir))
//     );

//     const isAllowed = allowedBasePaths.some(basePath => realPath.startsWith(basePath));

//     if (!isAllowed || !fs.existsSync(filePath)) {
//       return res.status(404).json({ error: 'Image not found' });
//     }

//     // Set cache headers
//     res.set('Cache-Control', 'public, max-age=86400'); // 24 hours
//     res.set('ETag', `"${Date.now()}"`);

//     res.sendFile(filePath);
//   } catch (error) {
//     console.error('Image retrieval error:', error.message);
//     res.status(500).json({ error: 'Failed to retrieve image' });
//   }
// });

/**
 * Delete image
 * DELETE /api/uploads/:type/:id
 */
router.delete('/:type/:id', verifyToken, async (req, res) => {
  try {
    const { type, id } = req.params;
    const { db } = require('../config/db');

    if (!['player', 'team'].includes(type) || !id || isNaN(id)) {
      return res.status(400).json({ error: 'Invalid type or ID' });
    }

    const conn = await db.getConnection();
    try {
      const table = type === 'player' ? 'players' : 'teams';
      const imageColumn = type === 'player' ? 'image_url' : 'logo_url';

      // Get current image path
      const rows = await conn.query(
        `SELECT ${imageColumn} as image_url FROM ${table} WHERE id = ?`,
        [id]
      );

      if (rows.length === 0) {
        return res.status(404).json({ error: `${type} not found` });
      }

      if (rows[0].image_url) {
        deleteImage(rows[0].image_url);
      }

      // Clear image from database
      await conn.query(
        `UPDATE ${table} SET ${imageColumn} = NULL WHERE id = ?`,
        [id]
      );

      res.json({ message: `${type} image deleted successfully` });
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('Image deletion error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
