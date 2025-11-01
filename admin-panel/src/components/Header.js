import React, { useState } from 'react';

const Header = ({ currentView, user, onLogout, notifications = 0 }) => {
  const [showSearch, setShowSearch] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  const viewTitles = {
    dashboard: 'Dashboard',
    users: 'User Management',
    teams: 'Team Management',
    tournaments: 'Tournament Management',
    matches: 'Match Management',
    'system-health': 'System Health',
    reports: 'Reports & Analytics'
  };

  return (
    <header className="bg-white shadow sticky top-0 z-40">
      <div className="px-4 py-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between">
          {/* Title and Breadcrumb */}
          <div className="flex items-center space-x-4">
            <h2 className="text-2xl font-bold text-gray-900">
              {viewTitles[currentView] || 'Dashboard'}
            </h2>
            <span className="text-gray-400">•</span>
            <p className="text-sm text-gray-600">
              Last updated: {new Date().toLocaleTimeString()}
            </p>
          </div>

          {/* Right Side Actions */}
          <div className="flex items-center space-x-4">
            {/* Search Bar */}
            <div className="relative">
              {showSearch ? (
                <input
                  type="text"
                  placeholder="Search..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  onBlur={() => setShowSearch(false)}
                  autoFocus
                  className="px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                />
              ) : (
                <button
                  onClick={() => setShowSearch(true)}
                  className="p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded transition-colors"
                  title="Search"
                >
                  🔍
                </button>
              )}
            </div>

            {/* Notifications */}
            <button
              className="relative p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded transition-colors"
              title="Notifications"
            >
              🔔
              {notifications > 0 && (
                <span className="absolute top-0 right-0 inline-flex items-center justify-center px-2 py-1 text-xs font-bold leading-none text-white transform translate-x-1/2 -translate-y-1/2 bg-red-600 rounded-full">
                  {notifications}
                </span>
              )}
            </button>

            {/* Settings */}
            <button
              className="p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded transition-colors"
              title="Settings"
            >
              ⚙️
            </button>

            {/* User Menu */}
            <div className="flex items-center space-x-3 pl-4 border-l border-gray-300">
              <div className="text-right hidden sm:block">
                <p className="text-sm font-medium text-gray-900">Admin</p>
                <p className="text-xs text-gray-600">{user?.phone_number || 'admin@example.com'}</p>
              </div>
              <div className="w-10 h-10 rounded-full bg-gradient-to-br from-indigo-500 to-blue-500 flex items-center justify-center text-white font-bold">
                {user?.phone_number?.charAt(user.phone_number.length - 1) || 'A'}
              </div>
              <button
                onClick={onLogout}
                className="text-sm text-gray-600 hover:text-gray-900 transition-colors"
                title="Logout"
              >
                🚪
              </button>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header;
