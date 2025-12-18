import React, { useState, useEffect } from 'react';
import { adminAPI } from '../services/api';

const Dashboard = ({ onToast, onViewChange }) => {
  // Initialize with defaults so the UI doesn't crash while loading
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalAdmins: 0,
    totalTeams: 0,
    totalTournaments: 0,
    totalMatches: 0
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [lastUpdated, setLastUpdated] = useState(null);

  useEffect(() => {
    fetchStats();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const fetchStats = async () => {
    try {
      setLoading(true);
      setError('');

      const response = await adminAPI.getDashboardStats();

      // DEBUG LOG: Open your browser console (F12) to see exactly what structure is returned
      console.log('Dashboard API Raw Data:', response.data);

      // Smart Data Extraction:
      // Handle cases where data is wrapped in { data: ... } or { stats: ... }
      const rawData = response.data;
      let finalStats = rawData;

      if (rawData && rawData.data) {
        finalStats = rawData.data;
      } else if (rawData && rawData.stats) {
        finalStats = rawData.stats;
      }

      // Ensure we don't set null
      setStats(finalStats || {});
      setLastUpdated(new Date());

      // Only show toast if it's a manual refresh (optional, keeps UI clean on load)
      if (lastUpdated && onToast) onToast('Dashboard stats updated', 'success');

    } catch (err) {
      console.error('Dashboard Fetch Error:', err);
      const errorMsg = err.userMessage || 'Failed to connect to dashboard service';
      setError(errorMsg);
      if (onToast) onToast(errorMsg, 'error');
    } finally {
      setLoading(false);
    }
  };

  // Loading View
  if (loading && !lastUpdated) {
    return (
      <div className="flex flex-col justify-center items-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mb-4"></div>
        <p className="text-gray-500 font-medium">Loading System Overview...</p>
      </div>
    );
  }

  // Error View
  if (error && !lastUpdated) {
    return (
      <div className="bg-red-50 border border-red-200 text-red-700 px-6 py-4 rounded-lg shadow-sm text-center my-8">
        <p className="font-bold text-lg mb-2">Error Loading Dashboard</p>
        <p className="mb-4">{error}</p>
        <button
          onClick={fetchStats}
          className="bg-red-600 hover:bg-red-700 text-white px-6 py-2 rounded-md font-medium transition-colors"
        >
          Try Again
        </button>
      </div>
    );
  }

  const statCards = [
    {
      title: 'Total Users',
      value: stats.totalUsers || 0,
      view: 'users',
      icon: (
        <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
        </svg>
      ),
      color: 'bg-gradient-to-r from-blue-500 to-blue-600',
      bgColor: 'bg-blue-50'
    },
    {
      title: 'Admin Users',
      value: stats.totalAdmins || 0,
      view: 'users',
      icon: (
        <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
        </svg>
      ),
      color: 'bg-gradient-to-r from-purple-500 to-purple-600',
      bgColor: 'bg-purple-50'
    },
    {
      title: 'Total Teams',
      value: stats.totalTeams || 0,
      view: 'teams',
      icon: (
        <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
        </svg>
      ),
      color: 'bg-gradient-to-r from-green-500 to-green-600',
      bgColor: 'bg-green-50'
    },
    {
      title: 'Tournaments',
      value: stats.totalTournaments || 0,
      view: 'tournaments',
      icon: (
        <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.384-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z" />
        </svg>
      ),
      color: 'bg-gradient-to-r from-yellow-500 to-yellow-600',
      bgColor: 'bg-yellow-50'
    },
    {
      title: 'Total Matches',
      value: stats.totalMatches || 0,
      view: 'matches',
      icon: (
        <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
        </svg>
      ),
      color: 'bg-gradient-to-r from-red-500 to-red-600',
      bgColor: 'bg-red-50'
    }
  ];

  return (
    <div className="space-y-6">
      {/* Header Section */}
      <div className="sm:flex sm:items-center sm:justify-between bg-white p-6 rounded-lg shadow-sm border border-gray-100">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Dashboard Overview</h1>
          <p className="mt-1 text-sm text-gray-500">
            Welcome back! Here's what's happening in your cricket league today.
          </p>
        </div>
        <div className="mt-4 sm:mt-0 flex items-center space-x-3">
          {lastUpdated && (
            <span className="text-xs text-gray-400">
              Last updated: {lastUpdated.toLocaleTimeString()}
            </span>
          )}
          <button
            onClick={fetchStats}
            disabled={loading}
            className={`inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 ${loading ? 'opacity-75 cursor-not-allowed' : ''
              }`}
          >
            {loading ? (
              <>
                <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                Updating...
              </>
            ) : (
              <>
                <svg className="-ml-1 mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
                Refresh Data
              </>
            )}
          </button>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5">
        {statCards.map((card, index) => (
          <div key={index} className="relative bg-white pt-5 px-4 pb-12 sm:pt-6 sm:px-6 shadow rounded-lg overflow-hidden transition-all duration-200 hover:shadow-md border border-gray-100">
            <dt>
              <div className={`absolute rounded-md p-3 ${card.color}`}>
                {card.icon}
              </div>
              <p className="ml-16 text-sm font-medium text-gray-500 truncate">{card.title}</p>
            </dt>
            <dd className="ml-16 pb-1 flex items-baseline sm:pb-2">
              <p className="text-2xl font-semibold text-gray-900">
                {typeof card.value === 'number' ? card.value.toLocaleString() : card.value}
              </p>
            </dd>
            <div className={`absolute bottom-0 inset-x-0 bg-gray-50 px-4 py-2 sm:px-6 border-t border-gray-100`}>
              <div className="text-sm">
                <button
                  onClick={() => onViewChange && onViewChange(card.view)}
                  className="font-medium text-indigo-600 hover:text-indigo-500 hover:underline focus:outline-none"
                >
                  View details <span aria-hidden="true">&rarr;</span>
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Quick Actions / System Health Preview */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white shadow rounded-lg p-6 border border-gray-100">
          <h3 className="text-lg leading-6 font-medium text-gray-900 mb-4">Quick Actions</h3>
          <div className="grid grid-cols-2 gap-4">
            <div
              onClick={() => onViewChange && onViewChange('users')}
              className="bg-blue-50 p-4 rounded-lg text-center cursor-pointer hover:bg-blue-100 transition-colors"
            >
              <span className="block text-2xl mb-1">👥</span>
              <span className="text-sm font-medium text-blue-900">Manage Users</span>
            </div>
            <div
              onClick={() => onViewChange && onViewChange('teams')}
              className="bg-green-50 p-4 rounded-lg text-center cursor-pointer hover:bg-green-100 transition-colors"
            >
              <span className="block text-2xl mb-1">🏏</span>
              <span className="text-sm font-medium text-green-900">Manage Teams</span>
            </div>
          </div>
        </div>

        <div className="bg-white shadow rounded-lg p-6 border border-gray-100">
          <h3 className="text-lg leading-6 font-medium text-gray-900 mb-4">System Status</h3>
          <div className="space-y-4">
            <div>
              <div className="flex justify-between text-sm font-medium text-gray-600 mb-1">
                <span>Server API</span>
                <span className="text-green-600">Online</span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2">
                <div className="bg-green-500 h-2 rounded-full" style={{ width: '100%' }}></div>
              </div>
            </div>
            <div>
              <div className="flex justify-between text-sm font-medium text-gray-600 mb-1">
                <span>Database Connection</span>
                <span className={stats.totalUsers > 0 ? "text-green-600" : "text-yellow-600"}>
                  {stats.totalUsers > 0 ? "Healthy" : "Waiting for Data"}
                </span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2">
                <div className={`${stats.totalUsers > 0 ? 'bg-green-500' : 'bg-yellow-500'} h-2 rounded-full`} style={{ width: '100%' }}></div>
              </div>
            </div>
          </div>
          <div className="mt-6 text-sm text-gray-500">
            <p>If data is not appearing, please check your network connection and ensure the backend server is running on port 5001.</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;