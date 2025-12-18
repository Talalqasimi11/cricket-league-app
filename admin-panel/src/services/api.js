import axios from 'axios';

// Ensure this matches your backend port (often 5000 or 5001 or 3000)
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api';

// Create axios instance
const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 15000, // Increased to 15s for slower connections
});

// --- REQUEST INTERCEPTOR ---
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('admin_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    // Debug log: Check if we are actually sending the token
    console.log(`[API Request] ${config.method.toUpperCase()} ${config.url}`, config);
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// --- RESPONSE INTERCEPTOR ---
api.interceptors.response.use(
  (response) => {
    // Debug log: Check what data is actually coming back
    console.log(`[API Response] ${response.config.url}:`, response.data);
    return response;
  },
  (error) => {
    const originalRequest = error.config;

    // Handle Network Errors (Server down / CORS / Offline)
    if (!error.response) {
      console.error('Network Error:', error);
      error.userMessage = 'Cannot connect to server. Check your internet or if server is running.';
      return Promise.reject(error);
    }

    // Handle 401/403 (Unauthorized)
    if ((error.response.status === 401 || error.response.status === 403) && !originalRequest._retry) {
      console.warn('Unauthorized access. Logging out...');
      localStorage.removeItem('admin_token');
      localStorage.removeItem('admin_user');
      
      // Only reload if we aren't already at login to prevent loops
      if (window.location.pathname !== '/login') {
         window.location.href = '/'; 
      }
    }

    // Handle 429 (Rate Limit)
    if (error.response.status === 429) {
      error.userMessage = 'Too many requests. Please wait a moment.';
    }

    // Handle 500+ (Server Errors)
    if (error.response.status >= 500) {
      error.userMessage = 'Server error. Please try again later.';
    }

    // Extract readable error message
    const errorMessage = 
      error.response.data?.message || 
      error.response.data?.error || 
      error.userMessage || 
      'Something went wrong.';
    
    // Attach readable message to error object for UI to use
    error.userMessage = errorMessage;
    
    console.error('API Error:', errorMessage);
    return Promise.reject(error);
  }
);

// --- AUTH API ---
export const authAPI = {
  login: (phoneNumber, password) => {
    return api.post('/auth/login', {
      phone_number: phoneNumber,
      password
    });
  },
};

// --- ADMIN API ---
export const adminAPI = {
  // Dashboard
  getDashboardStats: () => api.get('/admin/dashboard'),

  // Users
  getAllUsers: () => api.get('/admin/users'),
  updateUserAdminStatus: (userId, isAdmin) =>
    api.put(`/admin/users/${userId}/admin`, { is_admin: isAdmin }),
  deleteUser: (userId) => api.delete(`/admin/users/${userId}`),

  // Teams
  getAllTeams: () => api.get('/admin/teams'),
  getTeamDetails: (teamId) => api.get(`/admin/teams/${teamId}`),
  updateTeam: (teamId, teamData) => api.put(`/admin/teams/${teamId}`, teamData),
  deleteTeam: (teamId) => api.delete(`/admin/teams/${teamId}`),

  // Tournaments
  getAllTournaments: () => api.get('/admin/tournaments'),
  createTournament: (data) => api.post('/admin/tournaments', data),
  updateTournament: (id, data) => api.put(`/admin/tournaments/${id}`, data),
  deleteTournament: (id) => api.delete(`/admin/tournaments/${id}`),

  // Matches
  getAllMatches: () => api.get('/admin/matches'),
  getMatchDetails: (matchId) => api.get(`/admin/matches/${matchId}`),
  createMatch: (matchData) => api.post('/admin/matches', matchData),
  updateMatch: (matchId, matchData) => api.put(`/admin/matches/${matchId}`, matchData),
  deleteMatch: (matchId) => api.delete(`/admin/matches/${matchId}`),

  // Missing Endpoints referenced in App.js (Added placeholders to prevent crashes)
  getSystemHealth: () => api.get('/admin/system-health'),
  getReports: () => api.get('/admin/reports'),
};

export default api;