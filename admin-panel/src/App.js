import React from 'react';

import React, { useState, useEffect } from 'react';
import Login from './components/Login';
import Dashboard from './components/Dashboard';
import UserManagement from './components/UserManagement';
import TeamManagement from './components/TeamManagement';
import Toast from './components/Toast';
import ErrorBoundary from './components/ErrorBoundary';

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [currentView, setCurrentView] = useState('dashboard');
  const [user, setUser] = useState(null);
  const [toast, setToast] = useState(null);
  const [appLoading, setAppLoading] = useState(true);

  useEffect(() => {
    // Check if user is already logged in
    const token = localStorage.getItem('admin_token');
    const userData = localStorage.getItem('admin_user');
    
    if (token && userData) {
      try {
        setIsAuthenticated(true);
        setUser(JSON.parse(userData));
      } catch (err) {
        console.error('Failed to parse stored user data:', err);
        localStorage.removeItem('admin_token');
        localStorage.removeItem('admin_user');
      }
    }
    setAppLoading(false);
  }, []);

  const showToast = (message, type = 'info') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  const handleLogin = (userData, token) => {
    localStorage.setItem('admin_token', token);
    localStorage.setItem('admin_user', JSON.stringify(userData));
    setIsAuthenticated(true);
    setUser(userData);
    showToast('Login successful!', 'success');
  };

  const handleLogout = () => {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user');
    setIsAuthenticated(false);
    setUser(null);
    setCurrentView('dashboard');
    showToast('Logged out successfully', 'success');
  };

  const renderCurrentView = () => {
    switch (currentView) {
      case 'dashboard':
        return <Dashboard onToast={showToast} />;
      case 'users':
        return <UserManagement onToast={showToast} />;
      case 'teams':
        return <TeamManagement onToast={showToast} />;
      default:
        return <Dashboard onToast={showToast} />;
    }
  };

  if (appLoading) {
    return (
      <div className="flex justify-center items-center h-screen bg-gray-100">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-indigo-600 mx-auto mb-4"></div>
          <p className="text-gray-700">Loading...</p>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return (
      <>
        <Login onLogin={handleLogin} onToast={showToast} />
        {toast && <Toast message={toast.message} type={toast.type} />}
      </>
    );
  }

  return (
    <ErrorBoundary onToast={showToast}>
      <div className="min-h-screen bg-gray-100">
        {/* Navigation */}
        <nav className="bg-white shadow-lg">
          <div className="max-w-7xl mx-auto px-4">
            <div className="flex justify-between h-16">
              <div className="flex">
                <div className="flex-shrink-0 flex items-center">
                  <h1 className="text-xl font-bold text-gray-900">🏏 Cricket League Admin</h1>
                </div>
                <div className="hidden sm:ml-6 sm:flex sm:space-x-8">
                  <button
                    onClick={() => setCurrentView('dashboard')}
                    className={`${
                      currentView === 'dashboard'
                        ? 'border-indigo-500 text-gray-900'
                        : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                    } inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium transition-colors`}
                  >
                    Dashboard
                  </button>
                  <button
                    onClick={() => setCurrentView('users')}
                    className={`${
                      currentView === 'users'
                        ? 'border-indigo-500 text-gray-900'
                        : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                    } inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium transition-colors`}
                  >
                    Users
                  </button>
                  <button
                    onClick={() => setCurrentView('teams')}
                    className={`${
                      currentView === 'teams'
                        ? 'border-indigo-500 text-gray-900'
                        : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                    } inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium transition-colors`}
                  >
                    Teams
                  </button>
                </div>
              </div>
              <div className="flex items-center space-x-4">
                <span className="text-sm text-gray-700">
                  {user?.phone_number}
                </span>
                <button
                  onClick={handleLogout}
                  className="bg-red-600 hover:bg-red-700 text-white px-3 py-2 rounded-md text-sm font-medium transition-colors"
                >
                  Logout
                </button>
              </div>
            </div>
          </div>
        </nav>

        {/* Main Content */}
        <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
          {renderCurrentView()}
        </main>

        {/* Toast Notifications */}
        {toast && <Toast message={toast.message} type={toast.type} />}
      </div>
    </ErrorBoundary>
  );
}

export default App;