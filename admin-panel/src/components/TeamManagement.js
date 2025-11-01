import React, { useState, useEffect } from 'react';
import { adminAPI } from '../services/api';

const TeamManagement = ({ onToast }) => {
  const [teams, setTeams] = useState([]);
  const [filteredTeams, setFilteredTeams] = useState([]);
  const [selectedTeam, setSelectedTeam] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState('name');
  const [editForm, setEditForm] = useState({
    team_name: '',
    team_location: '',
    team_logo_url: ''
  });

  useEffect(() => {
    fetchTeams();
  }, []);

  useEffect(() => {
    applyFiltersAndSort();
  }, [teams, searchTerm, sortBy]);

  const fetchTeams = async () => {
    try {
      setLoading(true);
      setError('');
      const response = await adminAPI.getAllTeams();
      setTeams(response.data);
      onToast?.('Teams loaded successfully', 'success');
    } catch (err) {
      const errorMsg = err.response?.data?.error || 'Failed to load teams';
      setError(errorMsg);
      onToast?.(errorMsg, 'error');
    } finally {
      setLoading(false);
    }
  };

  const applyFiltersAndSort = () => {
    let filtered = [...teams];

    // Apply search
    if (searchTerm) {
      filtered = filtered.filter(team =>
        team.team_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        team.team_location.toLowerCase().includes(searchTerm.toLowerCase()) ||
        team.owner_phone.includes(searchTerm)
      );
    }

    // Apply sorting
    switch (sortBy) {
      case 'wins':
        filtered.sort((a, b) => b.matches_won - a.matches_won);
        break;
      case 'trophies':
        filtered.sort((a, b) => b.trophies - a.trophies);
        break;
      case 'players':
        filtered.sort((a, b) => b.player_count - a.player_count);
        break;
      default: // 'name'
        filtered.sort((a, b) => a.team_name.localeCompare(b.team_name));
    }

    setFilteredTeams(filtered);
  };

  const handleViewDetails = async (team) => {
    try {
      setActionLoading(true);
      const response = await adminAPI.getTeamDetails(team.id);
      setSelectedTeam(response.data);
      setShowDetailsModal(true);
    } catch (err) {
      const errorMsg = err.response?.data?.error || 'Failed to load team details';
      onToast?.(errorMsg, 'error');
    } finally {
      setActionLoading(false);
    }
  };

  const handleEditTeam = (team) => {
    setEditForm({
      team_name: team.team_name,
      team_location: team.team_location,
      team_logo_url: team.team_logo_url || ''
    });
    setSelectedTeam(team);
    setShowEditModal(true);
  };

  const handleUpdateTeam = async () => {
    if (!selectedTeam || !editForm.team_name || !editForm.team_location) {
      onToast?.('Please fill in all required fields', 'error');
      return;
    }

    try {
      setActionLoading(true);
      await adminAPI.updateTeam(selectedTeam.id, editForm);
      setTeams(teams.map(team =>
        team.id === selectedTeam.id
          ? { ...team, ...editForm }
          : team
      ));
      setShowEditModal(false);
      setSelectedTeam(null);
      onToast?.('Team updated successfully', 'success');
    } catch (err) {
      const errorMsg = err.response?.data?.error || 'Failed to update team';
      onToast?.(errorMsg, 'error');
    } finally {
      setActionLoading(false);
    }
  };

  const handleDeleteTeam = async () => {
    if (!selectedTeam) return;

    try {
      setActionLoading(true);
      await adminAPI.deleteTeam(selectedTeam.id);
      setTeams(teams.filter(team => team.id !== selectedTeam.id));
      setShowDeleteModal(false);
      setSelectedTeam(null);
      onToast?.('Team deleted successfully', 'success');
    } catch (err) {
      const errorMsg = err.response?.data?.error || 'Failed to delete team';
      onToast?.(errorMsg, 'error');
    } finally {
      setActionLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-indigo-600 mx-auto mb-4"></div>
          <p className="text-gray-700">Loading teams...</p>
        </div>
      </div>
    );
  }

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Team Management</h1>
        <p className="mt-1 text-sm text-gray-600">
          View and manage all teams in the system (Total: {teams.length})
        </p>
      </div>

      {error && (
        <div className="mb-4 bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg flex justify-between items-center">
          <span>{error}</span>
          <button
            onClick={fetchTeams}
            className="bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded text-sm"
          >
            Retry
          </button>
        </div>
      )}

      {/* Search and Sort */}
      <div className="mb-6 bg-white p-4 rounded-lg shadow space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Search teams
            </label>
            <input
              type="text"
              placeholder="Search by name, location, or owner..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Sort by
            </label>
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
            >
              <option value="name">Team Name</option>
              <option value="wins">Matches Won</option>
              <option value="trophies">Trophies</option>
              <option value="players">Player Count</option>
            </select>
          </div>
        </div>
      </div>

      {/* Teams List */}
      <div className="bg-white shadow overflow-hidden sm:rounded-md">
        {filteredTeams.length === 0 ? (
          <div className="p-8 text-center">
            <p className="text-gray-500">No teams found matching your criteria</p>
          </div>
        ) : (
          <ul className="divide-y divide-gray-200">
            {filteredTeams.map((team) => (
              <li key={team.id}>
                <div className="px-4 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors">
                  <div className="flex items-center flex-1 min-w-0">
                    <div className="flex-shrink-0">
                      {team.team_logo_url ? (
                        <img
                          className="h-12 w-12 rounded-full object-cover"
                          src={team.team_logo_url}
                          alt={team.team_name}
                          onError={(e) => e.target.style.display = 'none'}
                        />
                      ) : (
                        <div className="h-12 w-12 rounded-full bg-gradient-to-br from-indigo-500 to-blue-500 flex items-center justify-center text-white font-bold">
                          {team.team_name.charAt(0)}
                        </div>
                      )}
                    </div>
                    <div className="ml-4 flex-1 min-w-0">
                      <div className="text-sm font-bold text-gray-900 truncate">
                        {team.team_name}
                      </div>
                      <div className="text-sm text-gray-500">
                        {team.team_location} • {team.player_count} players
                      </div>
                      <div className="text-xs text-gray-400">
                        Owner: {team.owner_phone} {team.owner_is_admin && '(Admin)'}
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2 ml-4 flex-shrink-0">
                    <div className="text-right hidden sm:block">
                      <div className="text-sm font-semibold text-gray-900">
                        {team.matches_played} matches
                      </div>
                      <div className="text-xs text-gray-500">
                        {team.matches_won}W • {team.trophies} trophies
                      </div>
                    </div>
                    <div className="flex space-x-2">
                      <button
                        onClick={() => handleViewDetails(team)}
                        disabled={actionLoading}
                        className="bg-blue-100 text-blue-700 hover:bg-blue-200 px-3 py-1 rounded-md text-sm font-medium transition-colors disabled:opacity-50"
                      >
                        View
                      </button>
                      <button
                        onClick={() => handleEditTeam(team)}
                        className="bg-green-100 text-green-700 hover:bg-green-200 px-3 py-1 rounded-md text-sm font-medium transition-colors"
                      >
                        Edit
                      </button>
                      <button
                        onClick={() => {
                          setSelectedTeam(team);
                          setShowDeleteModal(true);
                        }}
                        className="bg-red-100 text-red-700 hover:bg-red-200 px-3 py-1 rounded-md text-sm font-medium transition-colors"
                      >
                        Delete
                      </button>
                    </div>
                  </div>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>

      {/* Team Details Modal */}
      {showDetailsModal && selectedTeam && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50 flex items-center justify-center p-4">
          <div className="relative w-full max-w-md shadow-lg rounded-md bg-white">
            <div className="p-6">
              <h3 className="text-lg font-bold text-gray-900 mb-4">
                Team Details
              </h3>
              <div className="space-y-3">
                <div className="border-b pb-2">
                  <p className="text-sm text-gray-600"><strong>Name:</strong></p>
                  <p className="text-gray-900">{selectedTeam.team_name}</p>
                </div>
                <div className="border-b pb-2">
                  <p className="text-sm text-gray-600"><strong>Location:</strong></p>
                  <p className="text-gray-900">{selectedTeam.team_location}</p>
                </div>
                <div className="border-b pb-2">
                  <p className="text-sm text-gray-600"><strong>Owner:</strong></p>
                  <p className="text-gray-900">{selectedTeam.owner_phone}</p>
                </div>
                <div className="grid grid-cols-3 gap-2">
                  <div className="text-center p-2 bg-blue-50 rounded">
                    <div className="text-lg font-bold text-blue-600">{selectedTeam.matches_played || 0}</div>
                    <div className="text-xs text-gray-600">Matches</div>
                  </div>
                  <div className="text-center p-2 bg-green-50 rounded">
                    <div className="text-lg font-bold text-green-600">{selectedTeam.matches_won || 0}</div>
                    <div className="text-xs text-gray-600">Wins</div>
                  </div>
                  <div className="text-center p-2 bg-yellow-50 rounded">
                    <div className="text-lg font-bold text-yellow-600">{selectedTeam.trophies || 0}</div>
                    <div className="text-xs text-gray-600">Trophies</div>
                  </div>
                </div>
              </div>
              {selectedTeam.players && selectedTeam.players.length > 0 && (
                <div className="mt-4">
                  <h4 className="font-bold text-gray-900 mb-2">Players ({selectedTeam.players.length}):</h4>
                  <div className="bg-gray-50 rounded p-2 max-h-40 overflow-y-auto">
                    <ul className="space-y-1">
                      {selectedTeam.players.map((player) => (
                        <li key={player.id} className="text-sm text-gray-700">
                          <span className="font-medium">{player.player_name}</span> <span className="text-gray-500">({player.player_role})</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                </div>
              )}
              <div className="flex justify-end mt-6">
                <button
                  onClick={() => {
                    setShowDetailsModal(false);
                    setSelectedTeam(null);
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

      {/* Edit Team Modal */}
      {showEditModal && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50 flex items-center justify-center p-4">
          <div className="relative w-full max-w-md shadow-lg rounded-md bg-white">
            <div className="p-6">
              <h3 className="text-lg font-bold text-gray-900 mb-4">
                Edit Team
              </h3>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Team Name *
                  </label>
                  <input
                    type="text"
                    value={editForm.team_name}
                    onChange={(e) => setEditForm({...editForm, team_name: e.target.value})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Team Location *
                  </label>
                  <input
                    type="text"
                    value={editForm.team_location}
                    onChange={(e) => setEditForm({...editForm, team_location: e.target.value})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Team Logo URL
                  </label>
                  <input
                    type="url"
                    value={editForm.team_logo_url}
                    onChange={(e) => setEditForm({...editForm, team_logo_url: e.target.value})}
                    placeholder="https://example.com/logo.png"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
                  />
                </div>
              </div>
              <div className="flex justify-end space-x-3 mt-6">
                <button
                  onClick={() => {
                    setShowEditModal(false);
                    setSelectedTeam(null);
                  }}
                  disabled={actionLoading}
                  className="bg-gray-300 text-gray-700 px-4 py-2 rounded-md text-sm font-medium hover:bg-gray-400 disabled:opacity-50"
                >
                  Cancel
                </button>
                <button
                  onClick={handleUpdateTeam}
                  disabled={actionLoading}
                  className="bg-indigo-600 text-white px-4 py-2 rounded-md text-sm font-medium hover:bg-indigo-700 disabled:opacity-50"
                >
                  {actionLoading ? 'Updating...' : 'Update'}
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
                Delete Team
              </h3>
              <p className="text-sm text-gray-600 mb-4">
                Are you sure you want to delete team <strong>{selectedTeam?.team_name}</strong>?
              </p>
              <p className="text-sm text-red-600 mb-4 bg-red-50 p-3 rounded">
                ⚠️ This action cannot be undone and will delete all associated players and data.
              </p>
              <div className="flex justify-end space-x-3">
                <button
                  onClick={() => {
                    setShowDeleteModal(false);
                    setSelectedTeam(null);
                  }}
                  disabled={actionLoading}
                  className="bg-gray-300 text-gray-700 px-4 py-2 rounded-md text-sm font-medium hover:bg-gray-400 disabled:opacity-50"
                >
                  Cancel
                </button>
                <button
                  onClick={handleDeleteTeam}
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

export default TeamManagement;
