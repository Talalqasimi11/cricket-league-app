import React, { useState, useEffect } from 'react';
import api from '../services/api';

const MatchManagement = ({ onToast }) => {
  const [matches, setMatches] = useState([]);
  const [filteredMatches, setFilteredMatches] = useState([]);
  const [tournaments, setTournaments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedMatch, setSelectedMatch] = useState(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');
  const [filterTournament, setFilterTournament] = useState('all');

  useEffect(() => {
    fetchData();
  }, []);

  useEffect(() => {
    applyFilters();
  }, [matches, searchTerm, filterStatus, filterTournament]);

  const fetchData = async () => {
    try {
      setLoading(true);
      setError('');
      
      // Fetch matches from tournament-matches endpoint
      const matchesRes = await api.get('/tournament-matches');
      setMatches(matchesRes.data || []);
      
      // Fetch tournaments for filter
      const tournamentsRes = await api.get('/tournaments');
      setTournaments(tournamentsRes.data || []);
      
      onToast?.('Matches loaded successfully', 'success');
    } catch (err) {
      const errorMsg = err.response?.data?.error || 'Failed to load matches';
      setError(errorMsg);
      onToast?.(errorMsg, 'error');
    } finally {
      setLoading(false);
    }
  };

  const applyFilters = () => {
    let filtered = matches;

    // Search filter
    if (searchTerm) {
      filtered = filtered.filter(m =>
        (m.round && m.round.toLowerCase().includes(searchTerm.toLowerCase())) ||
        (m.location && m.location.toLowerCase().includes(searchTerm.toLowerCase()))
      );
    }

    // Status filter
    if (filterStatus !== 'all') {
      filtered = filtered.filter(m => m.status === filterStatus);
    }

    // Tournament filter
    if (filterTournament !== 'all') {
      filtered = filtered.filter(m => m.tournament_id === parseInt(filterTournament));
    }

    setFilteredMatches(filtered);
  };

  const handleViewDetails = (match) => {
    setSelectedMatch(match);
    setShowDetailsModal(true);
  };

  const getStatusColor = (status) => {
    const colors = {
      upcoming: 'bg-blue-100 text-blue-800',
      live: 'bg-green-100 text-green-800',
      finished: 'bg-gray-100 text-gray-800'
    };
    return colors[status] || 'bg-gray-100 text-gray-800';
  };

  const getStatusIcon = (status) => {
    const icons = {
      upcoming: '📅',
      live: '🔴',
      finished: '✅'
    };
    return icons[status] || '📋';
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-indigo-600 mx-auto mb-4"></div>
          <p className="text-gray-700">Loading matches...</p>
        </div>
      </div>
    );
  }

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Match Management</h1>
        <p className="mt-1 text-sm text-gray-600">
          View and manage all matches (Total: {matches.length})
        </p>
      </div>

      {error && (
        <div className="mb-4 bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg flex justify-between items-center">
          <span>{error}</span>
          <button
            onClick={fetchData}
            className="bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded text-sm"
          >
            Retry
          </button>
        </div>
      )}

      {/* Search and Filter */}
      <div className="mb-6 bg-white p-4 rounded-lg shadow space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Search matches
            </label>
            <input
              type="text"
              placeholder="Search by round or location..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Filter by status
            </label>
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
            >
              <option value="all">All Matches</option>
              <option value="upcoming">Upcoming</option>
              <option value="live">Live</option>
              <option value="finished">Finished</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Filter by tournament
            </label>
            <select
              value={filterTournament}
              onChange={(e) => setFilterTournament(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
            >
              <option value="all">All Tournaments</option>
              {tournaments.map(t => (
                <option key={t.id} value={t.id}>
                  {t.tournament_name}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Matches Table */}
      <div className="bg-white shadow overflow-hidden sm:rounded-md">
        {filteredMatches.length === 0 ? (
          <div className="p-8 text-center">
            <p className="text-gray-500">No matches found matching your criteria</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">
                    Round
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">
                    Date/Time
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">
                    Location
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {filteredMatches.map((match) => (
                  <tr key={match.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="text-sm font-medium text-gray-900">{match.round}</span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="text-sm text-gray-600">
                        {match.match_date ? new Date(match.match_date).toLocaleDateString() : 'TBD'}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="text-sm text-gray-600">{match.location || '-'}</span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold ${getStatusColor(match.status)}`}>
                        {getStatusIcon(match.status)} {match.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <button
                        onClick={() => handleViewDetails(match)}
                        className="text-blue-600 hover:text-blue-900 font-medium text-sm"
                      >
                        View
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Match Details Modal */}
      {showDetailsModal && selectedMatch && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50 flex items-center justify-center p-4">
          <div className="relative w-full max-w-2xl shadow-lg rounded-md bg-white">
            <div className="p-6">
              <h3 className="text-2xl font-bold text-gray-900 mb-6">
                Match Details - {selectedMatch.round}
              </h3>

              <div className="grid grid-cols-2 gap-4 mb-6">
                <div className="bg-gray-50 p-4 rounded-lg">
                  <p className="text-sm text-gray-600">Status</p>
                  <p className={`text-lg font-bold ${getStatusColor(selectedMatch.status).split(' ')[1]}`}>
                    {selectedMatch.status}
                  </p>
                </div>
                <div className="bg-gray-50 p-4 rounded-lg">
                  <p className="text-sm text-gray-600">Round</p>
                  <p className="text-lg font-bold text-gray-900">{selectedMatch.round}</p>
                </div>
                <div className="bg-gray-50 p-4 rounded-lg col-span-2">
                  <p className="text-sm text-gray-600">Location</p>
                  <p className="text-lg font-bold text-gray-900">{selectedMatch.location || 'Not specified'}</p>
                </div>
                <div className="bg-gray-50 p-4 rounded-lg col-span-2">
                  <p className="text-sm text-gray-600">Date & Time</p>
                  <p className="text-lg font-bold text-gray-900">
                    {selectedMatch.match_date 
                      ? new Date(selectedMatch.match_date).toLocaleString()
                      : 'Not scheduled'
                    }
                  </p>
                </div>
              </div>

              <div className="border-t pt-4 mb-6">
                <h4 className="font-bold text-gray-900 mb-3">Match Information</h4>
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <p className="text-gray-600">Match ID</p>
                    <p className="font-medium text-gray-900">{selectedMatch.id}</p>
                  </div>
                  <div>
                    <p className="text-gray-600">Tournament ID</p>
                    <p className="font-medium text-gray-900">{selectedMatch.tournament_id}</p>
                  </div>
                  <div>
                    <p className="text-gray-600">Team 1 ID</p>
                    <p className="font-medium text-gray-900">{selectedMatch.team1_id || selectedMatch.team1_tt_id || '-'}</p>
                  </div>
                  <div>
                    <p className="text-gray-600">Team 2 ID</p>
                    <p className="font-medium text-gray-900">{selectedMatch.team2_id || selectedMatch.team2_tt_id || '-'}</p>
                  </div>
                </div>
              </div>

              <div className="flex justify-end">
                <button
                  onClick={() => {
                    setShowDetailsModal(false);
                    setSelectedMatch(null);
                  }}
                  className="bg-gray-300 text-gray-700 px-4 py-2 rounded-md text-sm font-medium hover:bg-gray-400"
                >
                  Close
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default MatchManagement;
