import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5001/api';

// Create axios instance
const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 10000, // 10 second timeout
});

// Add request interceptor to include auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('admin_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Add response interceptor to handle auth errors and token refresh
api.interceptors.response.use(
  (response) => response,
  (error) => {
    // Handle network errors
    if (!error.response) {
      console.error('Network error:', error.message);
      error.userMessage = 'Network connection failed. Please check your internet connection and try again.';
      return Promise.reject(error);
    }

    // Handle 401/403 - Token expired or access denied
    if (error.response?.status === 401 || error.response?.status === 403) {
      localStorage.removeItem('admin_token');
      localStorage.removeItem('admin_user');
      window.location.reload();
    }

    // Handle 429 - Rate limited
    if (error.response?.status === 429) {
      error.userMessage = 'Too many requests. Please wait a moment and try again.';
    }

    // Handle 500+ server errors
    if (error.response?.status >= 500) {
      error.userMessage = 'Server error occurred. Please try again later.';
    }

    // Handle 400 - Bad request with validation errors
    if (error.response?.status === 400 && error.response?.data?.validation) {
      const validationErrors = Object.values(error.response.data.validation).flat();
      error.userMessage = validationErrors.join(', ');
    }

    // Set default user message if not already set
    if (!error.userMessage) {
      error.userMessage = error.response?.data?.error ||
                         error.response?.data?.message ||
                         'An unexpected error occurred. Please try again.';
    }

    return Promise.reject(error);
  }
);

// Auth API
export const authAPI = {
  login: (phoneNumber, password) => {
    return api.post('/auth/login', { 
      phone_number: phoneNumber, 
      password 
    });
  },
};

// Admin API
export const adminAPI = {
  getDashboardStats: () => api.get('/admin/dashboard'),
  
  getAllUsers: () => api.get('/admin/users'),
  
  updateUserAdminStatus: (userId, isAdmin) => 
    api.put(`/admin/users/${userId}/admin`, { is_admin: isAdmin }),
  
  deleteUser: (userId) => api.delete(`/admin/users/${userId}`),
  
  getAllTeams: () => api.get('/admin/teams'),
  
  getTeamDetails: (teamId) => api.get(`/admin/teams/${teamId}`),
  
  updateTeam: (teamId, teamData) => api.put(`/admin/teams/${teamId}`, teamData),
  
  deleteTeam: (teamId) => api.delete(`/admin/teams/${teamId}`),
};

export default api;
