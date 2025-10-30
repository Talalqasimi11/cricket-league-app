import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api';

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
    // Handle 401/403 - Token expired or access denied
    if (error.response?.status === 401 || error.response?.status === 403) {
      localStorage.removeItem('admin_token');
      localStorage.removeItem('admin_user');
      window.location.reload();
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