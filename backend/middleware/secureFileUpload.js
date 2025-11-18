const multer = require('multer');
const sharp = require('sharp');
const path = require('path');
const fs = require('fs').promises;
const { logger } = require('../utils/logger');

// Security constants
const SECURITY_CONFIG = {
  MAX_FILE_SIZE: 5 * 1024 * 1024, // 5MB
  ALLOWED_TYPES: ['image/jpeg', 'image/png', 'image/webp'],
  ALLOWED_EXTENSIONS: ['.jpg', '.jpeg', '.png', '.webp'],
  TARGET_SIZE: 1000, // Resize images to 1000px max dimension
  QUALITY: 85, // JPEG/WebP quality
  UPLOAD_DIR: path.join(__dirname, '../uploads'),
  PLAYER_UPLOAD_DIR: path.join(__dirname, '../uploads/players'),
  TEAM_UPLOAD_DIR: path.join(__dirname, '../uploads/teams')
};

// Create upload directories if they don't exist
async function ensureDirectories() {
  try {
    await fs.mkdir(SECURITY_CONFIG.PLAYER_UPLOAD_DIR, { recursive: true });
    await fs.mkdir(SECURITY_CONFIG.TEAM_UPLOAD_DIR, { recursive: true });
    await fs.mkdir(SECURITY_CONFIG.UPLOAD_DIR, { recursive: true });
  } catch (error) {
    logger.error('Failed to create upload directories:', error);
  }
}

// Initialize directories on module load
ensureDirectories();

// Custom file filter for security
const fileFilter = (req, file, cb) => {
  // Check MIME type
  if (!SECURITY_CONFIG.ALLOWED_TYPES.includes(file.mimetype)) {
    logger.warn('File upload rejected - invalid MIME type', {
      filename: file.originalname,
      mimetype: file.mimetype,
      ip: req.ip,
      userId: req.user?.id,
      security: true,
      event: 'invalid_file_type'
    });
    return cb(new Error(`Invalid file type. Only ${SECURITY_CONFIG.ALLOWED_TYPES.join(', ')} are allowed.`), false);
  }

  // Check file extension
  const ext = path.extname(file.originalname).toLowerCase();
  if (!SECURITY_CONFIG.ALLOWED_EXTENSIONS.includes(ext)) {
    logger.warn('File upload rejected - invalid extension', {
      filename: file.originalname,
      extension: ext,
      ip: req.ip,
      userId: req.user?.id,
      security: true,
      event: 'invalid_file_extension'
    });
    return cb(new Error(`Invalid file extension. Only ${SECURITY_CONFIG.ALLOWED_EXTENSIONS.join(', ')} are allowed.`), false);
  }

  // Additional security checks
  if (!file.originalname || file.originalname.trim() === '') {
    logger.warn('File upload rejected - empty filename', {
      ip: req.ip,
      userId: req.user?.id,
      security: true,
      event: 'empty_filename'
    });
    return cb(new Error('Invalid file name.'), false);
  }

  // Check for suspicious filenames (containing special characters, .., etc.)
  if (/[<>:"\/\\|?*\x00-\x1f]/.test(file.originalname) || file.originalname.includes('..')) {
    logger.warn('File upload rejected - suspicious filename', {
      filename: file.originalname,
      ip: req.ip,
      userId: req.user?.id,
      security: true,
      event: 'suspicious_filename'
    });
    return cb(new Error('Invalid file name.'), false);
  }

  cb(null, true);
};

// Storage configuration with security
const createStorage = (directory) => {
  return multer.diskStorage({
    destination: async (req, file, cb) => {
      try {
        await fs.mkdir(directory, { recursive: true });
        cb(null, directory);
      } catch (error) {
        logger.error('Failed to create destination directory:', error);
        cb(error, directory);
      }
    },
    filename: (req, file, cb) => {
      // Generate secure filename
      const timestamp = Date.now();
      const random = Math.random().toString(36).substring(2, 8);
      const ext = path.extname(file.originalname).toLowerCase();
      const basename = path.basename(file.originalname, ext).replace(/[^a-zA-Z0-9_-]/g, '_');

      // Limit basename length
      const safeBasename = basename.substring(0, 50);
      const filename = `${timestamp}_${random}_${safeBasename}${ext}`;

      logger.info('File upload filename generated', {
        originalName: file.originalname,
        newName: filename,
        userId: req.user?.id,
        ip: req.ip
      });

      cb(null, filename);
    }
  });
};

// Create multer instances for different upload types
const uploadPlayer = multer({
  storage: createStorage(SECURITY_CONFIG.PLAYER_UPLOAD_DIR),
  fileFilter,
  limits: {
    fileSize: SECURITY_CONFIG.MAX_FILE_SIZE,
    files: 1
  }
});

const uploadTeam = multer({
  storage: createStorage(SECURITY_CONFIG.TEAM_UPLOAD_DIR),
  fileFilter,
  limits: {
    fileSize: SECURITY_CONFIG.MAX_FILE_SIZE,
    files: 1
  }
});

// Image processing middleware with Sharp
const processImage = async (req, res, next) => {
  if (!req.file) {
    return next();
  }

  const filePath = req.file.path;
  const tempPath = `${filePath}.processing`;

  try {
    // Get image metadata first
    const metadata = await sharp(filePath).metadata();

    // Skip processing if file is too small or already optimized
    if (metadata.size && metadata.size < 10000) {
      logger.info('Skipping image processing - file already small', {
        filename: req.file.filename,
        size: metadata.size
      });
      return next();
    }

    // Process and optimize image
    await sharp(filePath)
      .resize(SECURITY_CONFIG.TARGET_SIZE, SECURITY_CONFIG.TARGET_SIZE, {
        fit: 'inside',
        withoutEnlargement: true
      })
      .jpeg({
        quality: SECURITY_CONFIG.QUALITY,
        progressive: true,
        mozjpeg: true
      })
      .webp({
        quality: SECURITY_CONFIG.QUALITY,
        effort: 6
      })
      .png({
        quality: SECURITY_CONFIG.QUALITY,
        compressionLevel: 6
      })
      .toFile(tempPath);

    // Replace original file with processed version
    await fs.rename(tempPath, filePath);

    // Update file info
    const stats = await fs.stat(filePath);
    req.file.size = stats.size;

    logger.info('Image processed successfully', {
      filename: req.file.filename,
      originalSize: metadata.size || 'unknown',
      finalSize: stats.size,
      dimensions: `${metadata.width}x${metadata.height}`,
      userId: req.user?.id
    });

    next();
  } catch (error) {
    logger.error('Image processing failed:', error, {
      filename: req.file?.filename,
      userId: req.user?.id,
      ip: req.ip
    });

    // Clean up temp file if it exists
    try {
      await fs.unlink(tempPath);
    } catch (cleanupError) {
      // Ignore cleanup errors
    }

    // Continue with unprocessed file rather than failing
    next();
  }
};

// Cleanup orphaned files (run periodically)
const cleanupOrphanedFiles = async () => {
  const cleanupDirectory = async (dirPath, maxAge = 24 * 60 * 60 * 1000) => { // 24 hours
    try {
      const files = await fs.readdir(dirPath);
      const now = Date.now();

      for (const file of files) {
        const filePath = path.join(dirPath, file);
        const stats = await fs.stat(filePath);

        if (now - stats.mtime.getTime() > maxAge) {
          await fs.unlink(filePath);
          logger.info('Cleaned up orphaned file', { filePath });
        }
      }
    } catch (error) {
      logger.error('Cleanup failed:', error);
    }
  };

  // Clean up old processed temporary files
  setInterval(() => {
    cleanupDirectory(SECURITY_CONFIG.PLAYER_UPLOAD_DIR);
    cleanupDirectory(SECURITY_CONFIG.TEAM_UPLOAD_DIR);
  }, 60 * 60 * 1000); // Run every hour
};

// Start cleanup process
cleanupOrphanedFiles();

// Generate file URL helper
const generateFileUrl = (filename, type) => {
  const baseUrl = process.env.BASE_URL || `http://localhost:${process.env.PORT || 5000}`;
  return `${baseUrl}/api/uploads/${type}/${filename}`;
};

// Validation middleware for file existence
const validateFileExistence = async (req, res, next) => {
  if (!req.file) {
    return res.status(400).json({
      success: false,
      error: { message: 'No file uploaded' }
    });
  }

  // Verify file actually exists on disk
  try {
    await fs.access(req.file.path);
    next();
  } catch (error) {
    logger.error('Uploaded file not found on disk:', error, {
      filename: req.file.filename,
      userId: req.user?.id
    });

    return res.status(500).json({
      success: false,
      error: { message: 'File upload failed - file not saved' }
    });
  }
};

// Error handling middleware for multer errors
const handleUploadError = (error, req, res, next) => {
  if (error instanceof multer.MulterError) {
    logger.warn('Multer error:', error, {
      code: error.code,
      field: error.field,
      userId: req.user?.id,
      ip: req.ip,
      security: true
    });

    let message = 'File upload failed';
    switch (error.code) {
      case 'LIMIT_FILE_SIZE':
        message = `File too large. Maximum size is ${SECURITY_CONFIG.MAX_FILE_SIZE / (1024 * 1024)}MB`;
        break;
      case 'LIMIT_FILE_COUNT':
        message = 'Too many files uploaded';
        break;
      case 'LIMIT_FIELD_KEY':
        message = 'Invalid field name';
        break;
      default:
        message = 'File upload error';
    }

    return res.status(400).json({
      success: false,
      error: { message }
    });
  }

  if (error.message && error.message.includes('Invalid file')) {
    return res.status(400).json({
      success: false,
      error: { message: error.message }
    });
  }

  next(error);
};

module.exports = {
  uploadPlayer,
  uploadTeam,
  processImage,
  validateFileExistence,
  handleUploadError,
  generateFileUrl,
  SECURITY_CONFIG
};
