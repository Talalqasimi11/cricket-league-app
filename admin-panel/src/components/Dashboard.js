import React, { useState, useEffect } from 'react';
import { adminAPI } from '../services/api';

const Dashboard = ({ onToast }) => {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      setLoading(true);
      setError('');
      const response = await adminAPI.getDashboardStats();
      setStats(response.data);
      onToast?.('Dashboard stats loaded', 'success');
    } catch (err) {
      const errorMsg = err.response?.data?.error || 'Failed to load dashboard data';
      setError(errorMsg);
      onToast?.(errorMsg, 'error');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-indigo-600 mx-auto mb-4"></div>
          <p className="text-gray-700">Loading dashboard...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg">
        <p className="font-medium">{error}</p>
        <button
          onClick={fetchStats}
          className="mt-3 bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-md text-sm font-medium"
        >
          Try Again
        </button>
      </div>
    );
  }

  const statCards = [
    {
      title: 'Total Users',
      value: stats?.totalUsers || 0,
      icon: '👥',
      color: 'bg-blue-500'
    },
    {
      title: 'Admin Users',
      value: stats?.totalAdmins || 0,
      icon: '👑',
      color: 'bg-purple-500'
    },
    {
      title: 'Total Teams',
      value: stats?.totalTeams || 0,
      icon: '🏏',
      color: 'bg-green-500'
    },
    {
      title: 'Tournaments',
      value: stats?.totalTournaments || 0,
      icon: '🏆',
      color: 'bg-yellow-500'
    },
    {
      title: 'Matches',
      value: stats?.totalMatches || 0,
      icon: '⚡',
      color: 'bg-red-500'
    }
  ];

  return (
    <div>
      <div className="mb-8 flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
          <p className="mt-1 text-sm text-gray-600">
            Overview of your Cricket League system
          </p>
        </div>
        <button
          onClick={fetchStats}
          className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium transition-colors"
        >
          🔄 Refresh
        </button>
      </div>

      {/* Statistics Cards */}
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5">
        {statCards.map((card, index) => (
          <div key={index} className="bg-white overflow-hidden shadow rounded-lg hover:shadow-lg transition-shadow">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <span className="text-4xl">{card.icon}</span>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">
                      {card.title}
                    </dt>
                    <dd className="text-lg font-bold text-gray-900">
                      {typeof card.value === 'number' ? card.value.toLocaleString() : card.value}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
            <div className={`${card.color} px-5 py-3`}>
              <div className="text-sm font-semibold text-white">
                {card.title}
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Quick Actions Section */}
      <div className="mt-8">
        <div className="bg-white shadow rounded-lg p-6">
          <h3 className="text-lg font-bold text-gray-900 mb-6">System Overview</h3>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <div className="bg-gradient-to-br from-blue-50 to-blue-100 p-4 rounded-lg border border-blue-200">
              <h4 className="font-semibold text-blue-900">User Management</h4>
              <p className="text-sm text-blue-700 mt-1">
                Manage users and grant admin privileges
              </p>
              <div className="mt-3 text-3xl font-bold text-blue-600">
                {stats?.totalUsers || 0}
              </div>
            </div>
            <div className="bg-gradient-to-br from-green-50 to-green-100 p-4 rounded-lg border border-green-200">
              <h4 className="font-semibold text-green-900">Team Management</h4>
              <p className="text-sm text-green-700 mt-1">
                View and manage all teams
              </p>
              <div className="mt-3 text-3xl font-bold text-green-600">
                {stats?.totalTeams || 0}
              </div>
            </div>
            <div className="bg-gradient-to-br from-purple-50 to-purple-100 p-4 rounded-lg border border-purple-200">
              <h4 className="font-semibold text-purple-900">Admin Users</h4>
              <p className="text-sm text-purple-700 mt-1">
                Currently assigned admin users
              </p>
              <div className="mt-3 text-3xl font-bold text-purple-600">
                {stats?.totalAdmins || 0}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Additional Info */}
      <div className="mt-8 bg-blue-50 border border-blue-200 rounded-lg p-4">
        <p className="text-sm text-blue-800">
          <strong>💡 Tip:</strong> Use the navigation menu above to access User Management and Team Management sections for detailed control over system resources.
        </p>
      </div>
    </div>
  );
};

export default Dashboard;