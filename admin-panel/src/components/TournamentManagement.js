import React, { useState, useEffect } from 'react';
import { adminAPI } from '../services/api';

const TournamentManagement = ({ onToast }) => {
  const [tournaments, setTournaments] = useState([]);
  const [filteredTournaments, setFilteredTournaments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedTournament, setSelectedTournament] = useState(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');

  useEffect(() => {
    fetchTournaments();
  }, []);

  useEffect(() => {
    applyFilters();
  }, [tournaments, searchTerm, filterStatus]);

  const fetchTournaments = async () => {
    try {
      setLoading(true);
      setError('');
      const response = await adminAPI.getAllTournaments();
      setTournaments(response.data);
      onToast?.('Tournaments loaded successfully', 'success');
    } catch (err) {
      const errorMsg = err.response?.data?.error || 'Failed to load tournaments';
      setError(errorMsg);
      onToast?.(errorMsg, 'error');
    } finally {
      setLoading(false);
    }
  };

  const applyFilters = () => {
    let filtered = tournaments;

    // Search filter
    if (searchTerm) {
      filtered = filtered.filter(t =>
        t.tournament_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        t.location.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    // Status filter
    if (filterStatus !== 'all') {
      filtered = filtered.filter(t => t.status === filterStatus);
    }

    setFilteredTournaments(filtered);
  };

  const handleViewDetails = (tournament) => {
    setSelectedTournament(tournament);
    setShowDetailsModal(true);
  };

  const handleDeleteTournament = async () => {
    if (!selectedTournament) return;

    try {
      setActionLoading(true);
      await adminAPI.deleteTournament(selectedTournament.id);
      setTournaments(tournaments.filter(t => t.id !== selectedTournament.id));
      setShowDeleteModal(false);
      setSelectedTournament(null);
      onToast?.('Tournament deleted successfully', 'success');
    } catch (err) {
      const errorMsg = err.response?.data?.error || 'Failed to delete tournament';
      onToast?.(errorMsg, 'error');
    } finally {
      setActionLoading(false);
    }
  };

  const getStatusColor = (status) => {
    const colors = {
      upcoming: 'bg-blue-100 text-blue-800',
      live: 'bg-green-100 text-green-800',
      completed: 'bg-gray-100 text-gray-800',
      abandoned: 'bg-red-100 text-red-800'
    };
    return colors[status] || 'bg-gray-100 text-gray-800';
  };

  const getStatusIcon = (status) => {
    const icons = {
      upcoming: '📅',
      live: '🔴',
      completed: '✅',
      abandoned: '❌'
    };
    return icons[status] || '📋';
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-indigo-600 mx-auto mb-4"></div>
          <p className="text-gray-700">Loading tournaments...</p>
        </div>
      </div>
    );
  }

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Tournament Management</h1>
        <p className="mt-1 text-sm text-gray-600">
          Manage tournaments and view details (Total: {tournaments.length})
        </p>
      </div>

      {error && (
        <div className="mb-4 bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg flex justify-between items-center">
          <span>{error}</span>
          <button
            onClick={fetchTournaments}
            className="bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded text-sm"
          >
            Retry
          </button>
        </div>
      )}

      {/* Search and Filter */}
      <div className="mb-6 bg-white p-4 rounded-lg shadow space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Search tournaments
            </label>
            <input
              type="text"
              placeholder="Search by name or location..."
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
              <option value="all">All Tournaments</option>
              <option value="upcoming">Upcoming</option>
              <option value="live">Live</option>
              <option value="completed">Completed</option>
              <option value="abandoned">Abandoned</option>
            </select>
          </div>
        </div>
      </div>

      {/* Tournaments Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredTournaments.length === 0 ? (
          <div className="col-span-full p-8 text-center">
            <p className="text-gray-500">No tournaments found matching your criteria</p>
          </div>
        ) : (
          filteredTournaments.map((tournament) => (
            <div key={tournament.id} className="bg-white shadow rounded-lg overflow-hidden hover:shadow-lg transition-shadow">
              <div className="p-6">
                <div className="flex items-start justify-between mb-4">
                  <div className="flex-1">
                    <h3 className="text-lg font-bold text-gray-900">
                      {tournament.tournament_name}
                    </h3>
                    <p className="text-sm text-gray-500">📍 {tournament.location}</p>
                  </div>
                  <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold ${getStatusColor(tournament.status)}`}>
                    {getStatusIcon(tournament.status)} {tournament.status}
                  </span>
                </div>

                <div className="space-y-2 mb-4">
                  <div className="text-sm">
                    <span className="text-gray-600">Start Date:</span>
                    <span className="ml-2 font-medium text-gray-900">
                      {new Date(tournament.start_date).toLocaleDateString()}
                    </span>
                  </div>
                  <div className="text-sm">
                    <span className="text-gray-600">Created by:</span>
                    <span className="ml-2 font-medium text-gray-900">User #{tournament.created_by}</span>
                  </div>
                </div>

                <div className="border-t pt-4">
                  <div className="flex space-x-2">
                    <button
                      onClick={() => handleViewDetails(tournament)}
                      className="flex-1 bg-blue-100 text-blue-700 hover:bg-blue-200 px-3 py-2 rounded-md text-sm font-medium transition-colors"
                    >
                      View Details
                    </button>
                    <button
                      onClick={() => {
                        setSelectedTournament(tournament);
                        setShowDeleteModal(true);
                      }}
                      className="bg-red-100 text-red-700 hover:bg-red-200 px-3 py-2 rounded-md text-sm font-medium transition-colors"
                    >
                      Delete
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Tournament Details Modal */}
      {showDetailsModal && selectedTournament && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50 flex items-center justify-center p-4">
          <div className="relative w-full max-w-2xl shadow-lg rounded-md bg-white">
            <div className="p-6">
              <h3 className="text-2xl font-bold text-gray-900 mb-6">
                {selectedTournament.tournament_name}
              </h3>

              <div className="grid grid-cols-2 gap-4 mb-6">
                <div className="bg-gray-50 p-4 rounded-lg">
                  <p className="text-sm text-gray-600">Location</p>
                  <p className="text-lg font-bold text-gray-900">{selectedTournament.location}</p>
                </div>
                <div className="bg-gray-50 p-4 rounded-lg">
                  <p className="text-sm text-gray-600">Start Date</p>
                  <p className="text-lg font-bold text-gray-900">
                    {new Date(selectedTournament.start_date).toLocaleDateString()}
                  </p>
                </div>
                <div className="bg-gray-50 p-4 rounded-lg">
                  <p className="text-sm text-gray-600">Status</p>
                  <p className={`text-lg font-bold ${getStatusColor(selectedTournament.status).split(' ')[1]}`}>
                    {selectedTournament.status}
                  </p>
                </div>
                <div className="bg-gray-50 p-4 rounded-lg">
                  <p className="text-sm text-gray-600">Created By</p>
                  <p className="text-lg font-bold text-gray-900">User #{selectedTournament.created_by}</p>
                </div>
              </div>

              <div className="border-t pt-4 mb-6">
                <h4 className="font-bold text-gray-900 mb-2">Tournament Summary</h4>
                <p className="text-sm text-gray-600">
                  ID: <strong>{selectedTournament.id}</strong>
                </p>
              </div>

              <div className="flex justify-end">
                <button
                  onClick={() => {
                    setShowDetailsModal(false);
                    setSelectedTournament(null);
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

      {/* Delete Confirmation Modal */}
      {showDeleteModal && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50 flex items-center justify-center p-4">
          <div className="relative w-full max-w-md shadow-lg rounded-md bg-white">
            <div className="p-6">
              <h3 className="text-lg font-bold text-gray-900 mb-4">
                Delete Tournament
              </h3>
              <p className="text-sm text-gray-600 mb-4">
                Are you sure you want to delete tournament <strong>{selectedTournament?.tournament_name}</strong>?
              </p>
              <p className="text-sm text-red-600 mb-4 bg-red-50 p-3 rounded">
                ⚠️ This action cannot be undone and will delete all associated matches and data.
              </p>
              <div className="flex justify-end space-x-3">
                <button
                  onClick={() => {
                    setShowDeleteModal(false);
                    setSelectedTournament(null);
                  }}
                  disabled={actionLoading}
                  className="bg-gray-300 text-gray-700 px-4 py-2 rounded-md text-sm font-medium hover:bg-gray-400 disabled:opacity-50"
                >
                  Cancel
                </button>
                <button
                  onClick={handleDeleteTournament}
                  disabled={actionLoading}
                  className="bg-red-600 text-white px-4 py-2 rounded-md text-sm font-medium hover:bg-red-700 disabled:opacity-50"
                >
                  {actionLoading ? 'Deleting...' : 'Delete'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default TournamentManagement;
