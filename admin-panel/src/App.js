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
import Footer from './components/Footer';
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
      case 'tournaments':
        return <TournamentManagement onToast={showToast} />;
      case 'matches':
        return <MatchManagement onToast={showToast} />;
      case 'system-health':
        return <SystemHealth onToast={showToast} />;
      case 'reports':
        return <ReportingDashboard onToast={showToast} />;
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
      <div className="flex h-screen bg-gray-100">
        {/* Sidebar */}
        <Sidebar 
          currentView={currentView}
          onViewChange={setCurrentView}
          user={user}
          onLogout={handleLogout}
        />

        {/* Main Content Area */}
        <div className="flex-1 flex flex-col overflow-hidden">
          {/* Header */}
          <Header 
            currentView={currentView}
            user={user}
            onLogout={handleLogout}
          />

          {/* Scrollable Content */}
          <main className="flex-1 overflow-y-auto bg-gray-100">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
              {renderCurrentView()}
            </div>
          </main>

          {/* Footer */}
          <Footer />
        </div>

        {/* Toast Notifications */}
        {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
      </div>
    </ErrorBoundary>
  );
}

export default App;
