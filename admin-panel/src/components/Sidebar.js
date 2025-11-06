import React, { useState } from 'react';
import Icon from './Icon';

const Sidebar = ({ currentView, onViewChange, user, onLogout }) => {
  const [isExpanded, setIsExpanded] = useState(true);

  const menuItems = [
    { id: 'dashboard', label: 'Dashboard', icon: 'barChart3', section: 'main' },
    { id: 'users', label: 'Users', icon: 'users', section: 'main' },
    { id: 'teams', label: 'Teams', icon: 'users', section: 'main' },
    { id: 'tournaments', label: 'Tournaments', icon: 'trophy', section: 'management' },
    { id: 'matches', label: 'Matches', icon: 'zap', section: 'management' },
    { id: 'system-health', label: 'System Health', icon: 'activity', section: 'monitoring' },
    { id: 'reports', label: 'Reports', icon: 'trendingUp', section: 'analytics' },
  ];

  const sections = {
    main: 'Main',
    management: 'Management',
    monitoring: 'Monitoring',
    analytics: 'Analytics'
  };

  const groupedItems = {};
  menuItems.forEach(item => {
    if (!groupedItems[item.section]) {
      groupedItems[item.section] = [];
    }
    groupedItems[item.section].push(item);
  });

  return (
    <div className={`${isExpanded ? 'w-64' : 'w-20'} bg-gray-900 text-white transition-all duration-300 h-screen overflow-y-auto sticky top-0`}>
      {/* Header */}
      <div className="p-4 border-b border-gray-700">
        <div className="flex items-center justify-between">
          {isExpanded && (
            <h1 className="text-lg font-bold">🏏 Admin</h1>
          )}
          <button
            onClick={() => setIsExpanded(!isExpanded)}
            className="p-1 hover:bg-gray-800 rounded transition-colors"
            title={isExpanded ? 'Collapse' : 'Expand'}
          >
            {isExpanded ? '◀' : '▶'}
          </button>
        </div>
      </div>

      {/* Navigation */}
      <nav className="p-4 space-y-8">
        {Object.entries(groupedItems).map(([section, items]) => (
          <div key={section}>
            {isExpanded && (
              <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3">
                {sections[section]}
              </p>
            )}
            <div className="space-y-2">
              {items.map(item => (
                <button
                  key={item.id}
                  onClick={() => onViewChange(item.id)}
                  className={`w-full flex items-center space-x-3 px-3 py-2 rounded transition-colors ${
                    currentView === item.id
                      ? 'bg-indigo-600 text-white'
                      : 'text-gray-300 hover:bg-gray-800'
                  }`}
                  title={isExpanded ? '' : item.label}
                >
                  <Icon name={item.icon} size={20} className="flex-shrink-0" />
                  {isExpanded && <span className="text-sm font-medium">{item.label}</span>}
                </button>
              ))}
            </div>
          </div>
        ))}
      </nav>

      {/* User Profile Section */}
      <div className="absolute bottom-0 left-0 right-0 p-4 border-t border-gray-700 bg-gray-800">
        <div className="flex items-center space-x-3">
          <div className="w-10 h-10 rounded-full bg-indigo-500 flex items-center justify-center flex-shrink-0 font-bold">
            {user?.phone_number?.charAt(user.phone_number.length - 1) || 'A'}
          </div>
          {isExpanded && (
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-white truncate">Admin</p>
              <p className="text-xs text-gray-400 truncate">{user?.phone_number || 'user@example.com'}</p>
            </div>
          )}
        </div>
        {isExpanded && (
          <button
            onClick={onLogout}
            className="w-full mt-3 bg-red-600 hover:bg-red-700 text-white text-sm font-medium py-2 px-3 rounded transition-colors"
          >
            Logout
          </button>
        )}
      </div>
    </div>
  );
};

export default Sidebar;
