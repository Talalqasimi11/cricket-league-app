import React, { useState } from 'react';

const Header = ({ currentView, user, onLogout, notifications = 3 }) => {
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

  const handleSearchSubmit = (e) => {
    e.preventDefault();
    console.log('Searching for:', searchQuery);
    // You can add a prop here like onSearch(searchQuery) later
  };

  return (
    <header className="bg-white border-b border-gray-200 shadow-sm sticky top-0 z-30 h-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-full">
        <div className="flex items-center justify-between h-full">
          
          {/* Left: Page Title */}
          <div className="flex items-center">
            <h1 className="text-xl font-bold text-gray-800 tracking-tight">
              {viewTitles[currentView] || 'Admin Panel'}
            </h1>
          </div>

          {/* Right: Actions */}
          <div className="flex items-center space-x-2 sm:space-x-4">
            
            {/* Search Bar */}
            <div className="relative">
              <div className={`flex items-center transition-all duration-300 ${showSearch ? 'w-64' : 'w-auto'}`}>
                {showSearch ? (
                  <form onSubmit={handleSearchSubmit} className="relative w-full">
                    <input
                      type="text"
                      placeholder="Search data..."
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      className="w-full pl-10 pr-4 py-1.5 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all"
                      autoFocus
                      onBlur={() => {
                        if (!searchQuery) setShowSearch(false);
                      }}
                    />
                    <svg className="w-4 h-4 text-gray-400 absolute left-3 top-2.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                    </svg>
                    <button 
                        type="button"
                        onMouseDown={() => { setShowSearch(false); setSearchQuery(''); }}
                        className="absolute right-2 top-2 text-gray-400 hover:text-gray-600"
                    >
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                    </button>
                  </form>
                ) : (
                  <button
                    onClick={() => setShowSearch(true)}
                    className="p-2 text-gray-500 hover:text-indigo-600 hover:bg-gray-100 rounded-full transition-colors"
                  >
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                    </svg>
                  </button>
                )}
              </div>
            </div>

            {/* Notifications */}
            <button className="relative p-2 text-gray-500 hover:text-indigo-600 hover:bg-gray-100 rounded-full transition-colors">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
              </svg>
              {notifications > 0 && (
                <span className="absolute top-1.5 right-1.5 block h-2 w-2 rounded-full bg-red-500 ring-2 ring-white"></span>
              )}
            </button>

            {/* User Profile & Logout */}
            <div className="flex items-center border-l border-gray-200 pl-4 space-x-3">
              <div className="flex flex-col items-end hidden md:flex">
                <span className="text-sm font-semibold text-gray-700">
                  {user?.username || 'Administrator'}
                </span>
                <span className="text-xs text-gray-500">
                  {user?.phone_number || 'Admin Access'}
                </span>
              </div>
              
              <div className="h-9 w-9 rounded-full bg-indigo-100 flex items-center justify-center border border-indigo-200 text-indigo-700 font-bold">
                {user?.username ? user.username.charAt(0).toUpperCase() : 'A'}
              </div>

              <button
                onClick={onLogout}
                className="p-2 text-gray-400 hover:text-red-600 transition-colors"
                title="Sign out"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                </svg>
              </button>
            </div>

          </div>
        </div>
      </div>
    </header>
  );
};

export default Header;