import React, { useState, useEffect } from 'react';
import api from '../services/api';

const ReportingDashboard = ({ onToast }) => {
  const [reportData, setReportData] = useState({
    topPlayers: [],
    topTeams: [],
    tournamentStats: [],
    userEngagement: {}
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedReport, setSelectedReport] = useState('overview');
  const [dateRange, setDateRange] = useState('30days');

  useEffect(() => {
    fetchReportData();
  }, [dateRange]);

  const fetchReportData = async () => {
    try {
      setLoading(true);
      setError('');

      // Fetch player stats
      const playersRes = await api.get('/player-stats');
      
      // Fetch teams
      const teamsRes = await api.get('/teams');
      
      // Fetch tournaments
      const tournamentsRes = await api.get('/tournaments');

      setReportData({
        topPlayers: (playersRes.data || []).slice(0, 10),
        topTeams: (teamsRes.data || [])
          .sort((a, b) => b.matches_won - a.matches_won)
          .slice(0, 5),
        tournamentStats: tournamentsRes.data || [],
        userEngagement: {
          totalUsers: (await api.get('/admin/users')).data.length,
          activeTeams: (teamsRes.data || []).length,
          activeTournaments: (tournamentsRes.data || [])
            .filter(t => t.status === 'live' || t.status === 'upcoming').length
        }
      });

      onToast?.('Report data loaded', 'success');
    } catch (err) {
      const errorMsg = err.response?.data?.error || 'Failed to load report data';
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
          <p className="text-gray-700">Loading reports...</p>
        </div>
      </div>
    );
  }

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Reporting & Analytics</h1>
        <p className="mt-1 text-sm text-gray-600">
          Analyze system performance and user engagement metrics
        </p>
      </div>

      {error && (
        <div className="mb-4 bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg flex justify-between items-center">
          <span>{error}</span>
          <button
            onClick={fetchReportData}
            className="bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded text-sm"
          >
            Retry
          </button>
        </div>
      )}

      {/* Report Navigation */}
      <div className="mb-6 bg-white shadow rounded-lg p-4">
        <div className="flex flex-wrap items-center space-x-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Report Type
            </label>
            <select
              value={selectedReport}
              onChange={(e) => setSelectedReport(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
            >
              <option value="overview">Overview</option>
              <option value="players">Top Players</option>
              <option value="teams">Top Teams</option>
              <option value="tournaments">Tournaments</option>
              <option value="engagement">User Engagement</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Date Range
            </label>
            <select
              value={dateRange}
              onChange={(e) => setDateRange(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
            >
              <option value="7days">Last 7 Days</option>
              <option value="30days">Last 30 Days</option>
              <option value="90days">Last 90 Days</option>
              <option value="alltime">All Time</option>
            </select>
          </div>
          <button
            onClick={fetchReportData}
            className="mt-6 bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium transition-colors"
          >
            🔄 Refresh
          </button>
        </div>
      </div>

      {/* Overview Report */}
      {selectedReport === 'overview' && (
        <div className="space-y-8">
          {/* Key Metrics */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <div className="bg-white shadow rounded-lg p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">Total Users</p>
                  <p className="text-3xl font-bold text-gray-900 mt-1">
                    {reportData.userEngagement.totalUsers || 0}
                  </p>
                </div>
                <span className="text-4xl">👥</span>
              </div>
            </div>

            <div className="bg-white shadow rounded-lg p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">Active Teams</p>
                  <p className="text-3xl font-bold text-gray-900 mt-1">
                    {reportData.userEngagement.activeTeams || 0}
                  </p>
                </div>
                <span className="text-4xl">🏏</span>
              </div>
            </div>

            <div className="bg-white shadow rounded-lg p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">Active Tournaments</p>
                  <p className="text-3xl font-bold text-gray-900 mt-1">
                    {reportData.userEngagement.activeTournaments || 0}
                  </p>
                </div>
                <span className="text-4xl">🏆</span>
              </div>
            </div>

            <div className="bg-white shadow rounded-lg p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">Engagement Rate</p>
                  <p className="text-3xl font-bold text-green-600 mt-1">
                    {reportData.userEngagement.activeTeams && reportData.userEngagement.totalUsers
                      ? Math.round((reportData.userEngagement.activeTeams / reportData.userEngagement.totalUsers) * 100)
                      : 0}%
                  </p>
                </div>
                <span className="text-4xl">📈</span>
              </div>
            </div>
          </div>

          {/* Tournament Distribution */}
          <div className="bg-white shadow rounded-lg p-6">
            <h3 className="text-lg font-bold text-gray-900 mb-4">Tournament Status Distribution</h3>
            <div className="space-y-3">
              {['upcoming', 'live', 'completed', 'abandoned'].map((status) => {
                const count = reportData.tournamentStats.filter(t => t.status === status).length;
                const percentage = reportData.tournamentStats.length > 0 
                  ? Math.round((count / reportData.tournamentStats.length) * 100)
                  : 0;
                
                return (
                  <div key={status} className="flex items-center">
                    <div className="flex-1">
                      <div className="flex items-center justify-between mb-1">
                        <span className="text-sm font-medium text-gray-700 capitalize">{status}</span>
                        <span className="text-sm font-bold text-gray-900">{count}</span>
                      </div>
                      <div className="w-full bg-gray-200 rounded-full h-2">
                        <div
                          className={`h-2 rounded-full transition-all ${
                            status === 'upcoming' ? 'bg-blue-500' :
                            status === 'live' ? 'bg-green-500' :
                            status === 'completed' ? 'bg-gray-500' :
                            'bg-red-500'
                          }`}
                          style={{ width: `${percentage}%` }}
                        ></div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {/* Top Players Report */}
      {selectedReport === 'players' && (
        <div className="bg-white shadow rounded-lg p-6">
          <h3 className="text-lg font-bold text-gray-900 mb-6">Top Performing Players</h3>
          {reportData.topPlayers && reportData.topPlayers.length > 0 ? (
            <div className="space-y-3">
              {reportData.topPlayers.map((player, index) => (
                <div key={index} className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
                  <div className="flex items-center space-x-4 flex-1">
                    <div className="w-10 h-10 rounded-full bg-indigo-100 flex items-center justify-center font-bold text-indigo-600">
                      #{index + 1}
                    </div>
                    <div>
                      <p className="font-medium text-gray-900">Player #{player.id}</p>
                      <p className="text-sm text-gray-600">{player.player_role || 'All-rounder'}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-lg font-bold text-gray-900">{player.runs || 0} runs</p>
                    <p className="text-sm text-gray-600">{player.wickets || 0} wickets</p>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-gray-500">No player data available</p>
          )}
        </div>
      )}

      {/* Top Teams Report */}
      {selectedReport === 'teams' && (
        <div className="bg-white shadow rounded-lg p-6">
          <h3 className="text-lg font-bold text-gray-900 mb-6">Top Performing Teams</h3>
          {reportData.topTeams && reportData.topTeams.length > 0 ? (
            <div className="space-y-3">
              {reportData.topTeams.map((team, index) => (
                <div key={team.id} className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
                  <div className="flex items-center space-x-4 flex-1">
                    <div className="w-10 h-10 rounded-full bg-gradient-to-br from-indigo-500 to-blue-500 flex items-center justify-center font-bold text-white">
                      #{index + 1}
                    </div>
                    <div>
                      <p className="font-medium text-gray-900">{team.team_name}</p>
                      <p className="text-sm text-gray-600">{team.team_location}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="grid grid-cols-3 gap-4">
                      <div>
                        <p className="text-lg font-bold text-gray-900">{team.matches_played}</p>
                        <p className="text-xs text-gray-600">Matches</p>
                      </div>
                      <div>
                        <p className="text-lg font-bold text-green-600">{team.matches_won}</p>
                        <p className="text-xs text-gray-600">Wins</p>
                      </div>
                      <div>
                        <p className="text-lg font-bold text-yellow-600">{team.trophies}</p>
                        <p className="text-xs text-gray-600">Trophies</p>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-gray-500">No team data available</p>
          )}
        </div>
      )}

      {/* Tournaments Report */}
      {selectedReport === 'tournaments' && (
        <div className="bg-white shadow rounded-lg p-6">
          <h3 className="text-lg font-bold text-gray-900 mb-6">Tournament Overview</h3>
          {reportData.tournamentStats && reportData.tournamentStats.length > 0 ? (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-200">
                    <th className="px-4 py-3 text-left text-sm font-semibold text-gray-900">Tournament Name</th>
                    <th className="px-4 py-3 text-left text-sm font-semibold text-gray-900">Location</th>
                    <th className="px-4 py-3 text-left text-sm font-semibold text-gray-900">Status</th>
                    <th className="px-4 py-3 text-left text-sm font-semibold text-gray-900">Start Date</th>
                  </tr>
                </thead>
                <tbody>
                  {reportData.tournamentStats.map((tournament) => (
                    <tr key={tournament.id} className="border-b border-gray-100 hover:bg-gray-50 transition-colors">
                      <td className="px-4 py-3 text-sm font-medium text-gray-900">{tournament.tournament_name}</td>
                      <td className="px-4 py-3 text-sm text-gray-600">{tournament.location}</td>
                      <td className="px-4 py-3 text-sm">
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                          tournament.status === 'upcoming' ? 'bg-blue-100 text-blue-800' :
                          tournament.status === 'live' ? 'bg-green-100 text-green-800' :
                          tournament.status === 'completed' ? 'bg-gray-100 text-gray-800' :
                          'bg-red-100 text-red-800'
                        }`}>
                          {tournament.status}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-sm text-gray-600">
                        {new Date(tournament.start_date).toLocaleDateString()}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <p className="text-gray-500">No tournament data available</p>
          )}
        </div>
      )}

      {/* User Engagement Report */}
      {selectedReport === 'engagement' && (
        <div className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="bg-white shadow rounded-lg p-6">
              <p className="text-sm text-gray-600 mb-2">Total Users</p>
              <p className="text-4xl font-bold text-gray-900">{reportData.userEngagement.totalUsers || 0}</p>
              <p className="text-xs text-gray-600 mt-4">All registered users in the system</p>
            </div>

            <div className="bg-white shadow rounded-lg p-6">
              <p className="text-sm text-gray-600 mb-2">Users with Teams</p>
              <p className="text-4xl font-bold text-green-600">{reportData.userEngagement.activeTeams || 0}</p>
              <p className="text-xs text-gray-600 mt-4">Users who have created teams</p>
            </div>

            <div className="bg-white shadow rounded-lg p-6">
              <p className="text-sm text-gray-600 mb-2">Active in Tournaments</p>
              <p className="text-4xl font-bold text-blue-600">{reportData.userEngagement.activeTournaments || 0}</p>
              <p className="text-xs text-gray-600 mt-4">Tournaments currently active</p>
            </div>
          </div>

          <div className="bg-white shadow rounded-lg p-6">
            <h4 className="text-lg font-bold text-gray-900 mb-4">User Activity</h4>
            <div className="space-y-3">
              <div>
                <div className="flex justify-between mb-1">
                  <span className="text-sm text-gray-700">Team Creation</span>
                  <span className="text-sm font-bold text-gray-900">
                    {reportData.userEngagement.activeTeams}
                  </span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div
                    className="bg-green-500 h-2 rounded-full"
                    style={{
                      width: `${reportData.userEngagement.totalUsers > 0
                        ? (reportData.userEngagement.activeTeams / reportData.userEngagement.totalUsers) * 100
                        : 0}%`
                    }}
                  ></div>
                </div>
              </div>

              <div>
                <div className="flex justify-between mb-1">
                  <span className="text-sm text-gray-700">Tournament Participation</span>
                  <span className="text-sm font-bold text-gray-900">
                    {reportData.userEngagement.activeTournaments}
                  </span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div
                    className="bg-blue-500 h-2 rounded-full"
                    style={{
                      width: reportData.userEngagement.activeTournaments ? '75%' : '0%'
                    }}
                  ></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ReportingDashboard;
