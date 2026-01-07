import React, { useState } from 'react';
import { authAPI } from '../services/api';

const Login = ({ onLogin, onToast }) => {
  const [formData, setFormData] = useState({
    identifier: '',
    password: ''
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [showPassword, setShowPassword] = useState(false);

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
    setError('');
  };

  // Check if it's a phone number (digits and potential +)
  const isPhoneNumber = (val) => {
    // Basic check: looks like a phone number not an email
    return /^[\d\+\-\(\)\s]+$/.test(val);
  };

  const formatPhoneNumber = (phone) => {
    // Remove all non-digit characters
    const cleaned = phone.replace(/\D/g, '');
    // Return as E.164 format starting with +
    return cleaned.startsWith('+') ? phone : '+' + cleaned;
  };

  const validateInput = (identifier) => {
    if (identifier.includes('@')) {
      // Simple email regex
      return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(identifier);
    }
    // Assume phone
    const cleaned = identifier.replace(/\D/g, '');
    return cleaned.length >= 8 && cleaned.length <= 15;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      let finalIdentifier = formData.identifier;

      if (!validateInput(finalIdentifier)) {
        setError('Invalid email or phone number format.');
        setLoading(false);
        return;
      }

      // If phone, ensure E.164
      if (!finalIdentifier.includes('@') && isPhoneNumber(finalIdentifier)) {
        finalIdentifier = formatPhoneNumber(finalIdentifier);
      }

      const response = await authAPI.login(finalIdentifier, formData.password);
      const token = response.data.token || response.data.access_token;
      const userData = response.data.user;

      if (!token) {
        setError('No authentication token received');
        setLoading(false);
        return;
      }

      onLogin(userData, token);
      onToast?.('Login successful!', 'success');

    } catch (err) {

      console.error('Login error:', err);

      if (err.response?.status === 403 || err.response?.status === 401) {
        setError('Access denied. Admin privileges required or invalid credentials.');
      } else if (err.response?.status === 400) {
        setError('Invalid email/phone or password format.');
      } else {
        setError(err.response?.data?.error || 'Login failed. Please try again.');
      }
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-indigo-50 to-blue-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div className="text-center">
          <h1 className="text-4xl font-bold text-indigo-600 mb-2">🏏</h1>
          <h2 className="text-3xl font-extrabold text-gray-900">
            Admin Login
          </h2>
          <p className="mt-2 text-sm text-gray-600">
            Cricket League Management System
          </p>
        </div>

        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          <div className="rounded-md shadow-sm space-y-4">
            <div>
              <label htmlFor="identifier" className="block text-sm font-medium text-gray-700 mb-1">
                Email or Phone Number
              </label>
              <input
                id="identifier"
                name="identifier"
                type="text"
                required
                className="appearance-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="admin@example.com or +1234567890"
                value={formData.identifier}
                onChange={handleChange}
              />
              <p className="mt-1 text-xs text-gray-500">Enter your registered email or phone number</p>
            </div>
            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-1">
                Password
              </label>
              <div className="relative">
                <input
                  id="password"
                  name="password"
                  type={showPassword ? 'text' : 'password'}
                  required
                  className="appearance-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                  placeholder="Password"
                  value={formData.password}
                  onChange={handleChange}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-2.5 text-gray-500 hover:text-gray-700"
                >
                  {showPassword ? '🙈' : '👁️'}
                </button>
              </div>
            </div>
          </div>

          {error && (
            <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-md text-sm">
              {error}
            </div>
          )}

          <div>
            <button
              type="submit"
              disabled={loading}
              className="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              {loading ? (
                <>
                  <span className="animate-spin inline-block mr-2">⏳</span>
                  Signing in...
                </>
              ) : (
                'Sign in'
              )}
            </button>
          </div>

          <p className="text-center text-xs text-gray-600">
            Only admin users can access this panel
          </p>
        </form>
      </div>
    </div>
  );
};

export default Login;