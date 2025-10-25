import React, { useState, useEffect } from 'react';
import { adminAPI } from '../services/api';

const Dashboard = () => {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      setLoading(true);
      const response = await adminAPI.getDashboardStats();
      setStats(response.data);
    } catch (err) {
      setError(err.response?.data?.error || 'Failed to load dashboard data');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded">
        {error}
      </div>
    );
  }

  const statCards = [
    {
      title: 'Total Users',
      value: stats?.totalUsers || 0,
      color: 'bg-blue-500',
      icon: '👥'
    },
    {
      title: 'Admin Users',
      value: stats?.totalAdmins || 0,
      color: 'bg-purple-500',
      icon: '👑'
    },
    {
      title: 'Total Teams',
      value: stats?.totalTeams || 0,
      color: 'bg-green-500',
      icon: '🏏'
    },
    {
      title: 'Tournaments',
      value: stats?.totalTournaments || 0,
      color: 'bg-yellow-500',
      icon: '🏆'
    },
    {
      title: 'Matches',
      value: stats?.totalMatches || 0,
      color: 'bg-red-500',
      icon: '⚡'
    }
  ];

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <p className="mt-1 text-sm text-gray-600">
          Overview of your Cricket League system
        </p>
      </div>

      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5">
        {statCards.map((card, index) => (
          <div key={index} className="bg-white overflow-hidden shadow rounded-lg">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <span className="text-2xl">{card.icon}</span>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">
                      {card.title}
                    </dt>
                    <dd className="text-lg font-medium text-gray-900">
                      {card.value}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
            <div className={`${card.color} px-5 py-3`}>
              <div className="text-sm">
                <span className="text-white font-medium">
                  {card.title}
                </span>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="mt-8">
        <div className="bg-white shadow rounded-lg p-6">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Quick Actions</h3>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <div className="bg-gray-50 p-4 rounded-lg">
              <h4 className="font-medium text-gray-900">User Management</h4>
              <p className="text-sm text-gray-600 mt-1">
                Manage users and admin privileges
              </p>
            </div>
            <div className="bg-gray-50 p-4 rounded-lg">
              <h4 className="font-medium text-gray-900">Team Management</h4>
              <p className="text-sm text-gray-600 mt-1">
                View and manage all teams
              </p>
            </div>
            <div className="bg-gray-50 p-4 rounded-lg">
              <h4 className="font-medium text-gray-900">System Health</h4>
              <p className="text-sm text-gray-600 mt-1">
                Monitor system performance
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
