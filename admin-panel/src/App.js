import React, { useState, useEffect } from 'react';
import Login from './components/Login';
import Dashboard from './components/Dashboard';
import UserManagement from './components/UserManagement';
import TeamManagement from './components/TeamManagement';

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [currentView, setCurrentView] = useState('dashboard');
  const [user, setUser] = useState(null);

  useEffect(() => {
    // Check if user is already logged in
    const token = localStorage.getItem('admin_token');
    const userData = localStorage.getItem('admin_user');
    
    if (token && userData) {
      setIsAuthenticated(true);
      setUser(JSON.parse(userData));
    }
  }, []);

  const handleLogin = (userData, token) => {
    localStorage.setItem('admin_token', token);
    localStorage.setItem('admin_user', JSON.stringify(userData));
    setIsAuthenticated(true);
    setUser(userData);
  };

  const handleLogout = () => {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user');
    setIsAuthenticated(false);
    setUser(null);
    setCurrentView('dashboard');
  };

  const renderCurrentView = () => {
    switch (currentView) {
      case 'dashboard':
        return <Dashboard />;
      case 'users':
        return <UserManagement />;
      case 'teams':
        return <TeamManagement />;
      default:
        return <Dashboard />;
    }
  };

  if (!isAuthenticated) {
    return <Login onLogin={handleLogin} />;
  }

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Navigation */}
      <nav className="bg-white shadow-lg">
        <div className="max-w-7xl mx-auto px-4">
          <div className="flex justify-between h-16">
            <div className="flex">
              <div className="flex-shrink-0 flex items-center">
                <h1 className="text-xl font-bold text-gray-900">Cricket League Admin</h1>
              </div>
              <div className="hidden sm:ml-6 sm:flex sm:space-x-8">
                <button
                  onClick={() => setCurrentView('dashboard')}
                  className={`${
                    currentView === 'dashboard'
                      ? 'border-indigo-500 text-gray-900'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                  } inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium`}
                >
                  Dashboard
                </button>
                <button
                  onClick={() => setCurrentView('users')}
                  className={`${
                    currentView === 'users'
                      ? 'border-indigo-500 text-gray-900'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                  } inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium`}
                >
                  Users
                </button>
                <button
                  onClick={() => setCurrentView('teams')}
                  className={`${
                    currentView === 'teams'
                      ? 'border-indigo-500 text-gray-900'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                  } inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium`}
                >
                  Teams
                </button>
              </div>
            </div>
            <div className="flex items-center">
              <span className="text-sm text-gray-700 mr-4">
                Welcome, {user?.phone_number}
              </span>
              <button
                onClick={handleLogout}
                className="bg-red-600 hover:bg-red-700 text-white px-3 py-2 rounded-md text-sm font-medium"
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
    </div>
  );
}

export default App;
