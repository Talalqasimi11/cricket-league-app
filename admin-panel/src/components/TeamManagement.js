import React, { useState, useEffect } from 'react';
import { adminAPI } from '../services/api';

const TeamManagement = () => {
  const [teams, setTeams] = useState([]);
  const [selectedTeam, setSelectedTeam] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [editForm, setEditForm] = useState({
    team_name: '',
    team_location: '',
    team_logo_url: ''
  });

  useEffect(() => {
    fetchTeams();
  }, []);

  const fetchTeams = async () => {
    try {
      setLoading(true);
      const response = await adminAPI.getAllTeams();
      setTeams(response.data);
    } catch (err) {
      setError(err.response?.data?.error || 'Failed to load teams');
    } finally {
      setLoading(false);
    }
  };

  const handleViewDetails = async (teamId) => {
    try {
      const response = await adminAPI.getTeamDetails(teamId);
      setSelectedTeam(response.data);
    } catch (err) {
      setError(err.response?.data?.error || 'Failed to load team details');
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
    if (!selectedTeam) return;
    
    try {
      await adminAPI.updateTeam(selectedTeam.id, editForm);
      setTeams(teams.map(team => 
        team.id === selectedTeam.id 
          ? { ...team, ...editForm }
          : team
      ));
      setShowEditModal(false);
      setSelectedTeam(null);
    } catch (err) {
      setError(err.response?.data?.error || 'Failed to update team');
    }
  };

  const handleDeleteTeam = async () => {
    if (!selectedTeam) return;
    
    try {
      await adminAPI.deleteTeam(selectedTeam.id);
      setTeams(teams.filter(team => team.id !== selectedTeam.id));
      setShowDeleteModal(false);
      setSelectedTeam(null);
    } catch (err) {
      setError(err.response?.data?.error || 'Failed to delete team');
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">Team Management</h1>
        <p className="mt-1 text-sm text-gray-600">
          View and manage all teams in the system
        </p>
      </div>

      {error && (
        <div className="mb-4 bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <div className="bg-white shadow overflow-hidden sm:rounded-md">
        <ul className="divide-y divide-gray-200">
          {teams.map((team) => (
            <li key={team.id}>
              <div className="px-4 py-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center">
                    <div className="flex-shrink-0">
                      {team.team_logo_url ? (
                        <img 
                          className="h-10 w-10 rounded-full" 
                          src={team.team_logo_url} 
                          alt={team.team_name}
                        />
                      ) : (
                        <div className="h-10 w-10 rounded-full bg-gray-300 flex items-center justify-center">
                          <span className="text-sm font-medium text-gray-700">
                            {team.team_name.charAt(0)}
                          </span>
                        </div>
                      )}
                    </div>
                    <div className="ml-4">
                      <div className="text-sm font-medium text-gray-900">
                        {team.team_name}
                      </div>
                      <div className="text-sm text-gray-500">
                        {team.team_location} • {team.player_count} players
                      </div>
                      <div className="text-sm text-gray-500">
                        Owner: {team.owner_phone} {team.owner_is_admin && '(Admin)'}
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <div className="text-sm text-gray-500">
                      {team.matches_played} matches • {team.matches_won} wins • {team.trophies} trophies
                    </div>
                    <div className="flex space-x-2">
                      <button
                        onClick={() => handleViewDetails(team.id)}
                        className="bg-blue-100 text-blue-700 hover:bg-blue-200 px-3 py-1 rounded-md text-sm font-medium"
                      >
                        View
                      </button>
                      <button
                        onClick={() => handleEditTeam(team)}
                        className="bg-green-100 text-green-700 hover:bg-green-200 px-3 py-1 rounded-md text-sm font-medium"
                      >
                        Edit
                      </button>
                      <button
                        onClick={() => {
                          setSelectedTeam(team);
                          setShowDeleteModal(true);
                        }}
                        className="bg-red-100 text-red-700 hover:bg-red-200 px-3 py-1 rounded-md text-sm font-medium"
                      >
                        Delete
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </li>
          ))}
        </ul>
      </div>

      {/* Team Details Modal */}
      {selectedTeam && !showEditModal && !showDeleteModal && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
          <div className="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
            <div className="mt-3">
              <h3 className="text-lg font-medium text-gray-900 mb-4">
                Team Details
              </h3>
              <div className="space-y-2">
                <p><strong>Name:</strong> {selectedTeam.team?.team_name}</p>
                <p><strong>Location:</strong> {selectedTeam.team?.team_location}</p>
                <p><strong>Owner:</strong> {selectedTeam.team?.owner_phone}</p>
                <p><strong>Matches Played:</strong> {selectedTeam.team?.matches_played}</p>
                <p><strong>Matches Won:</strong> {selectedTeam.team?.matches_won}</p>
                <p><strong>Trophies:</strong> {selectedTeam.team?.trophies}</p>
              </div>
              {selectedTeam.players && selectedTeam.players.length > 0 && (
                <div className="mt-4">
                  <h4 className="font-medium text-gray-900">Players:</h4>
                  <ul className="mt-2 space-y-1">
                    {selectedTeam.players.map((player) => (
                      <li key={player.id} className="text-sm text-gray-600">
                        {player.player_name} ({player.player_role})
                      </li>
                    ))}
                  </ul>
                </div>
              )}
              <div className="flex justify-end mt-6">
                <button
                  onClick={() => setSelectedTeam(null)}
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
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
          <div className="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
            <div className="mt-3">
              <h3 className="text-lg font-medium text-gray-900 mb-4">
                Edit Team
              </h3>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Team Name
                  </label>
                  <input
                    type="text"
                    value={editForm.team_name}
                    onChange={(e) => setEditForm({...editForm, team_name: e.target.value})}
                    className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Team Location
                  </label>
                  <input
                    type="text"
                    value={editForm.team_location}
                    onChange={(e) => setEditForm({...editForm, team_location: e.target.value})}
                    className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Team Logo URL
                  </label>
                  <input
                    type="url"
                    value={editForm.team_logo_url}
                    onChange={(e) => setEditForm({...editForm, team_logo_url: e.target.value})}
                    className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  />
                </div>
              </div>
              <div className="flex justify-end space-x-3 mt-6">
                <button
                  onClick={() => {
                    setShowEditModal(false);
                    setSelectedTeam(null);
                  }}
                  className="bg-gray-300 text-gray-700 px-4 py-2 rounded-md text-sm font-medium hover:bg-gray-400"
                >
                  Cancel
                </button>
                <button
                  onClick={handleUpdateTeam}
                  className="bg-indigo-600 text-white px-4 py-2 rounded-md text-sm font-medium hover:bg-indigo-700"
                >
                  Update
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Delete Confirmation Modal */}
      {showDeleteModal && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
          <div className="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
            <div className="mt-3">
              <h3 className="text-lg font-medium text-gray-900 mb-4">
                Delete Team
              </h3>
              <p className="text-sm text-gray-500 mb-4">
                Are you sure you want to delete team {selectedTeam?.team_name}? 
                This action cannot be undone and will delete all associated players and data.
              </p>
              <div className="flex justify-end space-x-3">
                <button
                  onClick={() => {
                    setShowDeleteModal(false);
                    setSelectedTeam(null);
                  }}
                  className="bg-gray-300 text-gray-700 px-4 py-2 rounded-md text-sm font-medium hover:bg-gray-400"
                >
                  Cancel
                </button>
                <button
                  onClick={handleDeleteTeam}
                  className="bg-red-600 text-white px-4 py-2 rounded-md text-sm font-medium hover:bg-red-700"
                >
                  Delete
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
