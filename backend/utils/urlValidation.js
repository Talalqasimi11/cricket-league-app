const { URL } = require('url');
const https = require('https');
const http = require('http');

// Allowed image file extensions
const ALLOWED_IMAGE_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg', '.bmp'];
const ALLOWED_IMAGE_MIME_TYPES = [
  'image/jpeg', 'image/jpg', 'image/png', 'image/gif', 
  'image/webp', 'image/svg+xml', 'image/bmp'
];

// Trusted image hosting domains
const TRUSTED_DOMAINS = [
  'imgur.com', 'i.imgur.com',
  'github.com', 'raw.githubusercontent.com',
  'cloudinary.com', 'res.cloudinary.com',
  'amazonaws.com', 's3.amazonaws.com',
  'googleapis.com', 'storage.googleapis.com',
  'dropbox.com', 'dl.dropboxusercontent.com',
  'drive.google.com', 'docs.google.com'
];

/**
 * Validates hostname against trusted domains
 * @param {string} hostname - The hostname to validate
 * @returns {boolean} - Whether the hostname is trusted
 */
const isTrustedHostname = (hostname) => {
  return TRUSTED_DOMAINS.some(domain => 
    hostname === domain || hostname.endsWith('.' + domain)
  );
};

/**
 * Validates file extension for image content (Supports URLs and Local Paths)
 * @param {string} urlStr - The URL or path to check
 * @returns {boolean} - Whether the URL has a valid image extension
 */
const hasValidImageExtension = (urlStr) => {
  if (!urlStr) return false;
  
  let pathname;
  try {
    // If it's a local path (e.g. /uploads/...), use a dummy base to parse
    if (urlStr.startsWith('/')) {
      pathname = urlStr.toLowerCase();
    } else {
      pathname = new URL(urlStr).pathname.toLowerCase();
    }
  } catch (e) {
    // Fallback for malformed URLs: check end of string ignoring query params
    const cleanPath = urlStr.split('?')[0].toLowerCase();
    return ALLOWED_IMAGE_EXTENSIONS.some(ext => cleanPath.endsWith(ext));
  }

  return ALLOWED_IMAGE_EXTENSIONS.some(ext => pathname.endsWith(ext));
};

/**
 * Validates content type by making a HEAD request (Remote URLs only)
 * @param {string} url - The URL to check
 * @returns {Promise<Object>} - { isValid: boolean, mimeType: string|null, error: string|null }
 */
const validateContentType = (url) => {
  return new Promise((resolve) => {
    // Skip network check for local paths
    if (url.startsWith('/')) {
        return resolve({ isValid: true, mimeType: null, error: null });
    }

    try {
      const parsedUrl = new URL(url);
      const client = parsedUrl.protocol === 'https:' ? https : http;
      
      const options = {
        hostname: parsedUrl.hostname,
        port: parsedUrl.port || (parsedUrl.protocol === 'https:' ? 443 : 80),
        path: parsedUrl.pathname + parsedUrl.search,
        method: 'HEAD',
        timeout: 5000, // 5 second timeout
        headers: {
          'User-Agent': 'CricketLeagueApp/1.0'
        }
      };

      const req = client.request(options, (res) => {
        const contentType = res.headers['content-type'];
        const mimeType = contentType ? contentType.split(';')[0].trim() : null;
        
        if (mimeType && ALLOWED_IMAGE_MIME_TYPES.includes(mimeType)) {
          resolve({ isValid: true, mimeType, error: null });
        } else {
          resolve({ 
            isValid: false, 
            mimeType, 
            error: `Invalid content type: ${mimeType || 'unknown'}. Expected image/*` 
          });
        }
      });

      req.on('error', (error) => {
        resolve({ 
          isValid: false, 
          mimeType: null, 
          error: `Failed to validate content type: ${error.message}` 
        });
      });

      req.on('timeout', () => {
        req.destroy();
        resolve({ 
          isValid: false, 
          mimeType: null, 
          error: 'Content type validation timed out' 
        });
      });

      req.end();
    } catch (e) {
      resolve({ isValid: false, mimeType: null, error: 'Invalid URL' });
    }
  });
};

// 

/**
 * Validates and normalizes team logo URLs with enhanced security checks
 * Allows both Remote URLs (http/s) and Local Paths (/uploads/...)
 * @param {string} url - The URL to validate
 * @param {number} maxLength - Maximum allowed URL length (default: 255)
 * @param {boolean} strictMode - Whether to enforce strict validation (default: false)
 * @returns {Object} - { isValid: boolean, normalizedUrl: string|null, error: string|null }
 */
const validateTeamLogoUrl = (url, maxLength = 255, strictMode = false) => {
  // Allow null/undefined/empty values
  if (!url || url.trim() === '') {
    return { isValid: true, normalizedUrl: null, error: null };
  }

  const trimmedUrl = url.trim();

  // Check length
  if (trimmedUrl.length > maxLength) {
    return { 
      isValid: false, 
      normalizedUrl: null, 
      error: `URL must be ${maxLength} characters or less` 
    };
  }

  // ✅ 1. CHECK: Is this a local path? (starts with /)
  if (trimmedUrl.startsWith('/')) {
    // Even for local files, we ensure it has an image extension for basic security
    if (!hasValidImageExtension(trimmedUrl)) {
      return { 
        isValid: false, 
        normalizedUrl: null, 
        error: 'Local file must have a valid image extension (.jpg, .png, etc.)' 
      };
    }
    // It is a valid local path
    return { isValid: true, normalizedUrl: trimmedUrl, error: null };
  }

  // ✅ 2. CHECK: Remote URL validation
  try {
    const parsedUrl = new URL(trimmedUrl);
    
    // Only allow http and https schemes
    if (!['http:', 'https:'].includes(parsedUrl.protocol)) {
      return { 
        isValid: false, 
        normalizedUrl: null, 
        error: 'URL must use http or https protocol' 
      };
    }

    // Validate hostname in strict mode
    if (strictMode && !isTrustedHostname(parsedUrl.hostname)) {
      return { 
        isValid: false, 
        normalizedUrl: null, 
        error: 'URL hostname is not from a trusted domain' 
      };
    }

    // Check for valid image file extension
    if (strictMode && !hasValidImageExtension(trimmedUrl)) {
      return { 
        isValid: false, 
        normalizedUrl: null, 
        error: 'URL must point to a valid image file (.jpg, .png, .gif, .webp, .svg, .bmp)' 
      };
    }

    // Normalize to HTTPS if possible
    const normalizedUrl = parsedUrl.protocol === 'http:' 
      ? trimmedUrl.replace(/^http:/, 'https:')
      : trimmedUrl;

    return { 
      isValid: true, 
      normalizedUrl, 
      error: null 
    };
  } catch (error) {
    return { 
      isValid: false, 
      normalizedUrl: null, 
      error: 'Invalid URL format' 
    };
  }
};

/**
 * Validates player image URLs with enhanced security checks
 * @param {string} url - The URL to validate
 * @param {number} maxLength - Maximum allowed URL length (default: 255)
 * @param {boolean} strictMode - Whether to enforce strict validation (default: false)
 * @returns {Object} - { isValid: boolean, normalizedUrl: string|null, error: string|null }
 */
const validatePlayerImageUrl = (url, maxLength = 255, strictMode = false) => {
  return validateTeamLogoUrl(url, maxLength, strictMode);
};

/**
 * Async version of team logo URL validation with content type checking
 * @param {string} url - The URL to validate
 * @param {number} maxLength - Maximum allowed URL length (default: 255)
 * @param {boolean} strictMode - Whether to enforce strict validation (default: false)
 * @param {boolean} checkContentType - Whether to validate content type via HEAD request (default: false)
 * @returns {Promise<Object>} - { isValid: boolean, normalizedUrl: string|null, error: string|null }
 */
const validateTeamLogoUrlAsync = async (url, maxLength = 255, strictMode = false, checkContentType = false) => {
  // First do basic validation
  const basicValidation = validateTeamLogoUrl(url, maxLength, strictMode);
  if (!basicValidation.isValid) {
    return basicValidation;
  }

  // If content type checking is enabled, validate it (only for remote URLs)
  if (checkContentType && basicValidation.normalizedUrl && !basicValidation.normalizedUrl.startsWith('/')) {
    const contentTypeValidation = await validateContentType(basicValidation.normalizedUrl);
    if (!contentTypeValidation.isValid) {
      return {
        isValid: false,
        normalizedUrl: null,
        error: contentTypeValidation.error
      };
    }
  }

  return basicValidation;
};

/**
 * Async version of player image URL validation with content type checking
 * @param {string} url - The URL to validate
 * @param {number} maxLength - Maximum allowed URL length (default: 255)
 * @param {boolean} strictMode - Whether to enforce strict validation (default: false)
 * @param {boolean} checkContentType - Whether to validate content type via HEAD request (default: false)
 * @returns {Promise<Object>} - { isValid: boolean, normalizedUrl: string|null, error: string|null }
 */
const validatePlayerImageUrlAsync = async (url, maxLength = 255, strictMode = false, checkContentType = false) => {
  return validateTeamLogoUrlAsync(url, maxLength, strictMode, checkContentType);
};

module.exports = {
  validateTeamLogoUrl,
  validatePlayerImageUrl,
  validateTeamLogoUrlAsync,
  validatePlayerImageUrlAsync,
  validateContentType,
  isTrustedHostname,
  hasValidImageExtension
};