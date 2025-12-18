import React, { useState, useEffect } from 'react';
import Login from './components/Login';
import Dashboard from './components/Dashboard';
import UserManagement from './components/UserManagement';
import TeamManagement from './components/TeamManagement';
import TournamentManagement from './components/TournamentManagement';
import MatchManagement from './components/MatchManagement';
import SystemHealth from './components/SystemHealth';
import ReportingDashboard from './components/ReportingDashboard';
import Sidebar from './components/Sidebar';
import Header from './components/Header';
import Toast from './components/Toast';
import ErrorBoundary from './components/ErrorBoundary';

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [currentView, setCurrentView] = useState('dashboard');
  const [user, setUser] = useState(null);
  const [toast, setToast] = useState(null);
  const [appLoading, setAppLoading] = useState(true);

  useEffect(() => {
    const initializeAuth = () => {
      const token = localStorage.getItem('admin_token');
      const userData = localStorage.getItem('admin_user');

      if (token && userData) {
        try {
          const parsedUser = JSON.parse(userData);
          // Verify basic structure exists
          if (parsedUser) {
            setIsAuthenticated(true);
            setUser(parsedUser);
          } else {
            throw new Error('Invalid user data structure');
          }
        } catch (err) {
          console.error('Session restoration failed:', err);
          // Clear corrupt data
          localStorage.removeItem('admin_token');
          localStorage.removeItem('admin_user');
          setIsAuthenticated(false);
        }
      }
      setAppLoading(false);
    };

    initializeAuth();
  }, []);

  const showToast = (message, type = 'info') => {
    setToast({ message, type });
    // Clear toast after 3 seconds
    setTimeout(() => setToast(null), 3000);
  };

  const handleLogin = (userData, token) => {
    try {
      localStorage.setItem('admin_token', token);
      localStorage.setItem('admin_user', JSON.stringify(userData));
      setIsAuthenticated(true);
      setUser(userData);
      showToast('Welcome back!', 'success');
    } catch (error) {
      console.error('Login storage error:', error);
      showToast('Login failed to save session', 'error');
    }
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
    const commonProps = {
      onToast: showToast,
      currentUser: user // Passing user down in case components need role/id
    };

    switch (currentView) {
      case 'dashboard':
        return <Dashboard {...commonProps} onViewChange={setCurrentView} />;
      case 'users':
        return <UserManagement {...commonProps} />;
      case 'teams':
        return <TeamManagement {...commonProps} />;
      case 'tournaments':
        return <TournamentManagement {...commonProps} />;
      case 'matches':
        return <MatchManagement {...commonProps} />;
      case 'system-health':
        return <SystemHealth {...commonProps} />;
      case 'reports':
        return <ReportingDashboard {...commonProps} />;
      default:
        return <Dashboard {...commonProps} />;
    }
  };

  // Loading State
  if (appLoading) {
    return (
      <div className="flex justify-center items-center h-screen bg-gray-50">
        <div className="flex flex-col items-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mb-4"></div>
          <h2 className="text-xl font-semibold text-gray-700">Loading Admin Panel...</h2>
        </div>
      </div>
    );
  }

  // Login State
  if (!isAuthenticated) {
    return (
      <div className="min-h-screen bg-gray-100">
        <Login onLogin={handleLogin} onToast={showToast} />
        {toast && (
          <div className="fixed top-4 right-4 z-50">
            <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />
          </div>
        )}
      </div>
    );
  }

  // Authenticated Dashboard Layout
  return (
    <ErrorBoundary onToast={showToast}>
      <div className="flex h-screen overflow-hidden bg-gray-50">

        {/* Sidebar - Fixed Left */}
        <Sidebar
          currentView={currentView}
          onViewChange={setCurrentView}
          user={user}
          onLogout={handleLogout}
        />

        {/* Main Content Wrapper */}
        <div className="flex-1 flex flex-col min-w-0 overflow-hidden relative">

          {/* Header - Fixed Top */}
          <Header
            currentView={currentView}
            user={user}
            onLogout={handleLogout}
          />

          {/* Main Scrollable Area */}
          <main className="flex-1 overflow-y-auto focus:outline-none p-0">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
              {renderCurrentView()}
            </div>
          </main>

          {/* Footer - Fixed Bottom of Scroll Area (or Sticky) */}

        </div>

        {/* Toast Notifications Overlay */}
        {toast && (
          <div className="fixed bottom-4 right-4 z-50 transition-opacity duration-300">
            <Toast
              message={toast.message}
              type={toast.type}
              onClose={() => setToast(null)}
            />
          </div>
        )}
      </div>
    </ErrorBoundary>
  );
}

export default App;