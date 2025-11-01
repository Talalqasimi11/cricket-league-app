// Token Management Utilities

/**
 * Store authentication token in localStorage
 */
export const storeToken = (token) => {
  if (!token) return false;
  try {
    localStorage.setItem('admin_token', token);
    return true;
  } catch (err) {
    console.error('Failed to store token:', err);
    return false;
  }
};

/**
 * Retrieve authentication token from localStorage
 */
export const getToken = () => {
  try {
    return localStorage.getItem('admin_token');
  } catch (err) {
    console.error('Failed to retrieve token:', err);
    return null;
  }
};

/**
 * Clear authentication token from localStorage
 */
export const clearToken = () => {
  try {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user');
    return true;
  } catch (err) {
    console.error('Failed to clear token:', err);
    return false;
  }
};

/**
 * Store user data in localStorage
 */
export const storeUserData = (userData) => {
  if (!userData) return false;
  try {
    localStorage.setItem('admin_user', JSON.stringify(userData));
    return true;
  } catch (err) {
    console.error('Failed to store user data:', err);
    return false;
  }
};

/**
 * Retrieve user data from localStorage
 */
export const getUserData = () => {
  try {
    const userData = localStorage.getItem('admin_user');
    return userData ? JSON.parse(userData) : null;
  } catch (err) {
    console.error('Failed to retrieve user data:', err);
    return null;
  }
};

/**
 * Check if token is valid and not expired
 * Note: This is a basic check. For production, decode JWT and check exp claim
 */
export const isTokenValid = () => {
  const token = getToken();
  if (!token) return false;
  
  // Basic check - token exists
  // In production, you would decode the JWT and check the exp claim
  return !!token;
};

/**
 * Decode JWT token and extract payload
 * WARNING: This decodes the token locally but doesn't verify the signature.
 * Always validate tokens on the backend.
 */
export const decodeToken = (token) => {
  try {
    const base64Url = token.split('.')[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = decodeURIComponent(
      atob(base64)
        .split('')
        .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join('')
    );
    return JSON.parse(jsonPayload);
  } catch (err) {
    console.error('Failed to decode token:', err);
    return null;
  }
};

/**
 * Check if token is expired
 */
export const isTokenExpired = (token) => {
  try {
    const decoded = decodeToken(token);
    if (!decoded || !decoded.exp) return true;
    
    // Check if expiration time is in the past (with 1-minute buffer)
    const expirationTime = decoded.exp * 1000; // Convert to milliseconds
    const currentTime = new Date().getTime();
    const bufferTime = 60 * 1000; // 1 minute buffer
    
    return currentTime > expirationTime - bufferTime;
  } catch (err) {
    console.error('Failed to check token expiration:', err);
    return true;
  }
};

/**
 * Get time until token expiration
 */
export const getTokenExpirationTime = (token) => {
  try {
    const decoded = decodeToken(token);
    if (!decoded || !decoded.exp) return null;
    
    const expirationTime = decoded.exp * 1000;
    const currentTime = new Date().getTime();
    const timeUntilExpiration = expirationTime - currentTime;
    
    return Math.max(0, timeUntilExpiration);
  } catch (err) {
    console.error('Failed to get token expiration time:', err);
    return null;
  }
};

/**
 * Setup token expiration listener
 * Logs out user when token expires
 */
export const setupTokenExpirationListener = (onExpired) => {
  const token = getToken();
  if (!token) return null;
  
  const timeUntilExpiration = getTokenExpirationTime(token);
  if (!timeUntilExpiration) return null;
  
  // Set timeout to trigger onExpired callback when token expires
  return setTimeout(() => {
    clearToken();
    if (onExpired) onExpired();
  }, timeUntilExpiration);
};

/**
 * Check if user is authenticated
 */
export const isAuthenticated = () => {
  const token = getToken();
  const userData = getUserData();
  return !!token && !!userData && isTokenValid();
};
