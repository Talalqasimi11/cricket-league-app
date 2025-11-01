const multer = require('multer');
const path = require('path');
const fs = require('fs');
const sharp = require('sharp');

// Create upload directories
const uploadDirs = {
  players: 'uploads/players',
  teams: 'uploads/teams',
  temporary: 'uploads/temp'
};

Object.values(uploadDirs).forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

// Configure storage
const storage = multer.memoryStorage();

// File filter for images
const fileFilter = (req, file, cb) => {
  const allowedMimes = ['image/jpeg', 'image/png', 'image/webp'];
  const allowedExts = ['.jpg', '.jpeg', '.png', '.webp'];

  if (allowedMimes.includes(file.mimetype)) {
    const ext = path.extname(file.originalname).toLowerCase();
    if (allowedExts.includes(ext)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file extension'), false);
    }
  } else {
    cb(new Error('Invalid file type. Only JPEG, PNG, and WebP are allowed'), false);
  }
};

// Configure multer
const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB max
  },
});

/**
 * Process and save image
 * @param {Buffer} fileBuffer - Image buffer from multer
 * @param {String} uploadDir - Directory to save the image
 * @param {String} filename - Desired filename
 * @returns {Promise<String>} - Relative path to saved image
 */
async function processAndSaveImage(fileBuffer, uploadDir, filename) {
  try {
    // Ensure directory exists
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }

    const timestamp = Date.now();
    const filenameWithoutExt = path.parse(filename).name;
    const finalFilename = `${filenameWithoutExt}_${timestamp}.webp`;
    const filepath = path.join(uploadDir, finalFilename);

    // Process image with sharp: compress and convert to WebP
    await sharp(fileBuffer)
      .resize(800, 800, {
        fit: 'cover',
        position: 'center',
      })
      .webp({ quality: 85 })
      .toFile(filepath);

    // Return relative path for database storage
    return filepath.replace(/\\/g, '/');
  } catch (error) {
    throw new Error(`Image processing failed: ${error.message}`);
  }
}

/**
 * Delete image file
 * @param {String} imagePath - Relative path to image
 */
function deleteImage(imagePath) {
  try {
    if (imagePath && fs.existsSync(imagePath)) {
      fs.unlinkSync(imagePath);
      return true;
    }
  } catch (error) {
    console.error(`Failed to delete image: ${error.message}`);
  }
  return false;
}

/**
 * Get full image URL
 * @param {String} imagePath - Relative path to image
 * @param {String} baseUrl - Base URL of the server
 * @returns {String} - Full URL to image
 */
function getImageUrl(imagePath, baseUrl) {
  if (!imagePath) return null;
  return `${baseUrl}/api/uploads/${imagePath}`;
}

module.exports = {
  upload,
  uploadDirs,
  processAndSaveImage,
  deleteImage,
  getImageUrl,
};
