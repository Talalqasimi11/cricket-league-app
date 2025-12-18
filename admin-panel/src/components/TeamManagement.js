import React, { useState, useEffect } from 'react';
import { adminAPI } from '../services/api';

const TeamManagement = ({ onToast }) => {
  const [teams, setTeams] = useState([]);
  const [filteredTeams, setFilteredTeams] = useState([]);
  const [selectedTeam, setSelectedTeam] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  
  // Modals
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  
  const [actionLoading, setActionLoading] = useState(false);
  
  // Progress Bar State (For Rate Limiting)
  const [progress, setProgress] = useState({ current: 0, total: 0 });

  const [searchTerm, setSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState('name');
  const [editForm, setEditForm] = useState({
    team_name: '',
    team_location: '',
    team_logo_url: ''
  });

  // Pagination state
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);

  // Bulk actions state
  const [selectedTeams, setSelectedTeams] = useState([]);
  const [selectAll, setSelectAll] = useState(false);

  useEffect(() => {
    fetchTeams();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Reset pagination when search/sort changes
  useEffect(() => {
    setCurrentPage(1); 
    applyFiltersAndSort();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchTerm, sortBy, teams]);

  const fetchTeams = async () => {
    try {
      setLoading(true);
      setError('');
      const response = await adminAPI.getAllTeams();
      console.log('Teams API Response:', response.data);

      // Smart Unwrap Logic
      let teamsData = [];
      if (Array.isArray(response.data)) {
        teamsData = response.data;
      } else if (response.data && Array.isArray(response.data.teams)) {
        teamsData = response.data.teams;
      } else if (response.data && Array.isArray(response.data.data)) {
        teamsData = response.data.data;
      }

      setTeams(teamsData);
    } catch (err) {
      console.error('Fetch Teams Error:', err);
      const errorMsg = err.userMessage || 'Failed to load teams';
      setError(errorMsg);
      if (onToast) onToast(errorMsg, 'error');
    } finally {
      setLoading(false);
    }
  };

  const applyFiltersAndSort = () => {
    if (!teams) return;
    let filtered = [...teams];

    // Apply search
    if (searchTerm) {
      const lowerTerm = searchTerm.toLowerCase();
      filtered = filtered.filter(team =>
        (team.team_name && team.team_name.toLowerCase().includes(lowerTerm)) ||
        (team.team_location && team.team_location.toLowerCase().includes(lowerTerm)) ||
        (team.owner_phone && team.owner_phone.includes(lowerTerm))
      );
    }

    // Apply sorting
    switch (sortBy) {
      case 'wins':
        filtered.sort((a, b) => (b.matches_won || 0) - (a.matches_won || 0));
        break;
      case 'trophies':
        filtered.sort((a, b) => (b.trophies || 0) - (a.trophies || 0));
        break;
      case 'players':
        filtered.sort((a, b) => (b.player_count || 0) - (a.player_count || 0));
        break;
      default: // 'name'
        filtered.sort((a, b) => (a.team_name || '').localeCompare(b.team_name || ''));
    }

    setFilteredTeams(filtered);
  };

  // --- SAFETY HELPER: Slow down requests ---
  const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

  // --- Actions ---

  const handleViewDetails = async (team) => {
    try {
      setActionLoading(true);
      // Try to fetch detailed data, fallback to list data if fail
      let detailedTeam = team;
      try {
          const response = await adminAPI.getTeamDetails(team.id);
          // Unwrap detail response if necessary
          detailedTeam = response.data.team || response.data.data || response.data || team;
      } catch (e) {
          console.warn('Could not fetch extra details, showing basic info', e);
      }
      
      setSelectedTeam(detailedTeam);
      setShowDetailsModal(true);
    } finally {
      setActionLoading(false);
    }
  };

  const handleEditTeam = (team) => {
    setEditForm({
      team_name: team.team_name || '',
      team_location: team.team_location || '',
      team_logo_url: team.team_logo_url || ''
    });
    setSelectedTeam(team);
    setShowEditModal(true);
  };

  const handleUpdateTeam = async () => {
    if (!selectedTeam || !editForm.team_name || !editForm.team_location) {
      if (onToast) onToast('Please fill in Name and Location', 'error');
      return;
    }

    try {
      setActionLoading(true);
      await adminAPI.updateTeam(selectedTeam.id, editForm);
      
      // Update local state
      setTeams(teams.map(team =>
        team.id === selectedTeam.id
          ? { ...team, ...editForm }
          : team
      ));
      setShowEditModal(false);
      setSelectedTeam(null);
      if (onToast) onToast('Team updated successfully', 'success');
    } catch (err) {
      if (onToast) onToast(err.userMessage || 'Failed to update team', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  const handleDeleteTeam = async () => {
    if (!selectedTeam) return;

    try {
      setActionLoading(true);
      await adminAPI.deleteTeam(selectedTeam.id);
      
      setTeams(prev => prev.filter(team => team.id !== selectedTeam.id));
      setShowDeleteModal(false);
      setSelectedTeam(null);
      if (onToast) onToast('Team deleted successfully', 'success');
    } catch (err) {
      if (onToast) onToast(err.userMessage || 'Failed to delete team', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  // --- Bulk Actions (FIXED FOR RATE LIMITS) ---

  const handleSelectTeam = (teamId) => {
    setSelectedTeams(prev =>
      prev.includes(teamId)
        ? prev.filter(id => id !== teamId)
        : [...prev, teamId]
    );
  };

  const handleSelectAll = () => {
    if (selectAll) {
      setSelectedTeams([]);
    } else {
      setSelectedTeams(paginatedTeams.map(team => team.id));
    }
    setSelectAll(!selectAll);
  };

  const handleBulkDelete = async () => {
    if (selectedTeams.length === 0) return;

    if (!window.confirm(`Are you sure you want to delete ${selectedTeams.length} teams? This cannot be undone.`)) {
      return;
    }

    setActionLoading(true);
    // Initialize Progress
    setProgress({ current: 0, total: selectedTeams.length });

    let successCount = 0;
    let failCount = 0;

    // Execute sequentially with DELAY to avoid server rate limits
    for (let i = 0; i < selectedTeams.length; i++) {
        const teamId = selectedTeams[i];
        try {
          await adminAPI.deleteTeam(teamId);
          successCount++;
        } catch (e) {
          console.error(`Failed to delete team ${teamId}:`, e);
          failCount++;
        }

        // Update progress bar
        setProgress({ current: i + 1, total: selectedTeams.length });

        // WAIT 800ms before the next request (prevents Rate Limit Exceeded)
        await delay(800); 
    }

    setTeams(prev => prev.filter(team => !selectedTeams.includes(team.id)));
    setSelectedTeams([]);
    setSelectAll(false);
    setActionLoading(false);
    setProgress({ current: 0, total: 0 });
    
    if (failCount > 0) {
      if (onToast) onToast(`Deleted ${successCount} teams. Failed: ${failCount}`, 'warning');
    } else {
      if (onToast) onToast(`${successCount} teams deleted successfully`, 'success');
    }
  };

  // Pagination logic
  const totalItems = filteredTeams.length;
  const totalPages = Math.ceil(totalItems / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const paginatedTeams = filteredTeams.slice(startIndex, endIndex);

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  return (
    <div>
      <div className="mb-6 flex flex-col sm:flex-row justify-between items-start sm:items-center space-y-4 sm:space-y-0">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Team Management</h1>
          <p className="mt-1 text-sm text-gray-600">
            Total Teams: {teams.length}
          </p>
        </div>
      </div>

      {error && (
        <div className="mb-4 bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg flex justify-between items-center">
          <span>{error}</span>
          <button onClick={fetchTeams} className="bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded text-sm">
            Retry
          </button>
        </div>
      )}

      {/* Progress Bar for Bulk Actions */}
      {actionLoading && progress.total > 0 && (
        <div className="mb-4 bg-blue-50 border border-blue-100 rounded-lg p-4">
            <div className="flex justify-between mb-1">
                <span className="text-sm font-medium text-blue-700">Processing deletion...</span>
                <span className="text-sm font-medium text-blue-700">{progress.current}/{progress.total}</span>
            </div>
            <div className="w-full bg-blue-200 rounded-full h-2.5">
                <div className="bg-blue-600 h-2.5 rounded-full transition-all duration-300" style={{ width: `${(progress.current / progress.total) * 100}%` }}></div>
            </div>
        </div>
      )}

      {/* Search and Sort */}
      <div className="mb-6 bg-white p-4 rounded-lg shadow-sm border border-gray-200">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">
              Search teams
            </label>
            <div className="relative rounded-md shadow-sm">
                 <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <svg className="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>
                 </div>
                 <input
                  type="text"
                  placeholder="Name, location, owner..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="focus:ring-indigo-500 focus:border-indigo-500 block w-full pl-10 sm:text-sm border-gray-300 rounded-md py-2 border"
                 />
            </div>
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">
              Sort by
            </label>
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
              className="block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md border"
            >
              <option value="name">Team Name</option>
              <option value="wins">Matches Won</option>
              <option value="trophies">Trophies</option>
              <option value="players">Player Count</option>
            </select>
          </div>
        </div>
      </div>

      {/* Bulk Actions Bar */}
      {selectedTeams.length > 0 && !actionLoading && (
        <div className="mb-4 bg-indigo-50 border border-indigo-200 rounded-lg p-4 transition-all duration-300">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <span className="text-sm font-medium text-indigo-800">
                {selectedTeams.length} selected
              </span>
              <button
                onClick={() => setSelectedTeams([])}
                className="text-sm text-indigo-600 hover:text-indigo-800 underline"
              >
                Clear
              </button>
            </div>
            <button
              onClick={handleBulkDelete}
              disabled={actionLoading}
              className="bg-red-600 text-white px-4 py-2 rounded-md text-sm font-medium hover:bg-red-700 disabled:opacity-50 flex items-center space-x-2 shadow-sm"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
              <span>Delete Selected</span>
            </button>
          </div>
        </div>
      )}

      {/* Teams List */}
      <div className="bg-white shadow overflow-hidden sm:rounded-md border border-gray-200">
        {filteredTeams.length === 0 ? (
          <div className="p-10 text-center">
            <svg className="mx-auto h-12 w-12 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path></svg>
            <p className="mt-2 text-sm text-gray-500">No teams found matching your search.</p>
          </div>
        ) : (
          <>
            <div className="bg-gray-50 px-4 py-3 border-b border-gray-200 flex items-center">
                <input
                  type="checkbox"
                  checked={selectAll}
                  onChange={handleSelectAll}
                  disabled={actionLoading}
                  className="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                />
                <span className="ml-3 text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Select All
                </span>
            </div>

            <ul className="divide-y divide-gray-200">
              {paginatedTeams.map((team) => (
                <li key={team.id} className="hover:bg-gray-50 transition-colors duration-150">
                  <div className="px-4 py-4 flex items-center justify-between">
                    <div className="flex items-center flex-1 min-w-0">
                      {/* Checkbox */}
                      <div className="flex-shrink-0 mr-4">
                        <input
                          type="checkbox"
                          checked={selectedTeams.includes(team.id)}
                          onChange={() => handleSelectTeam(team.id)}
                          disabled={actionLoading}
                          className="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                        />
                      </div>

                      {/* Team Logo */}
                      <div className="flex-shrink-0 mr-4">
                        {team.team_logo_url ? (
                          <img
                            className="h-12 w-12 rounded-full object-cover border border-gray-200"
                            src={team.team_logo_url}
                            alt={team.team_name}
                            onError={(e) => { e.target.onerror = null; e.target.src = "https://via.placeholder.com/150?text=" + team.team_name.charAt(0); }}
                          />
                        ) : (
                          <div className="h-12 w-12 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-700 font-bold border border-indigo-200">
                            {team.team_name ? team.team_name.charAt(0).toUpperCase() : 'T'}
                          </div>
                        )}
                      </div>

                      {/* Team Info */}
                      <div className="flex-1 min-w-0">
                        <div className="text-sm font-bold text-gray-900 truncate">
                          {team.team_name}
                        </div>
                        <div className="text-sm text-gray-500 flex items-center">
                           <svg className="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                           {team.team_location || 'No Location'} • {team.player_count || 0} players
                        </div>
                      </div>
                    </div>

                    {/* Actions */}
                    <div className="flex items-center space-x-2 ml-4 flex-shrink-0">
                      <div className="text-right hidden sm:block mr-4">
                        <div className="text-sm font-semibold text-gray-900">{team.matches_played || 0} matches</div>
                        <div className="text-xs text-gray-500">{team.matches_won || 0} wins</div>
                      </div>
                      
                      <button onClick={() => handleViewDetails(team)} disabled={actionLoading} className="text-indigo-600 hover:text-indigo-900 p-2">
                         <span className="sr-only">View</span>
                         <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path></svg>
                      </button>
                      <button onClick={() => handleEditTeam(team)} disabled={actionLoading} className="text-green-600 hover:text-green-900 p-2">
                         <span className="sr-only">Edit</span>
                         <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path></svg>
                      </button>
                      <button onClick={() => { setSelectedTeam(team); setShowDeleteModal(true); }} disabled={actionLoading} className="text-red-600 hover:text-red-900 p-2">
                         <span className="sr-only">Delete</span>
                         <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
                      </button>
                    </div>
                  </div>
                </li>
              ))}
            </ul>

            {/* Pagination Controls */}
            {filteredTeams.length > 0 && (
              <div className="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6">
                <div className="flex-1 flex justify-between sm:hidden">
                  <button
                    onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
                    disabled={currentPage === 1}
                    className="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
                  >
                    Previous
                  </button>
                  <button
                    onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))}
                    disabled={currentPage === totalPages}
                    className="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
                  >
                    Next
                  </button>
                </div>
                <div className="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
                  <div>
                    <p className="text-sm text-gray-700">
                      Showing <span className="font-medium">{startIndex + 1}</span> to <span className="font-medium">{Math.min(endIndex, totalItems)}</span> of <span className="font-medium">{totalItems}</span> results
                    </p>
                  </div>
                  <div>
                    <nav className="relative z-0 inline-flex rounded-md shadow-sm -space-x-px">
                      <button
                        onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
                        disabled={currentPage === 1}
                        className={`relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium ${currentPage === 1 ? 'text-gray-300' : 'text-gray-500 hover:bg-gray-50'}`}
                      >
                        Previous
                      </button>
                      <button
                        onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))}
                        disabled={currentPage === totalPages}
                        className={`relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium ${currentPage === totalPages ? 'text-gray-300' : 'text-gray-500 hover:bg-gray-50'}`}
                      >
                        Next
                      </button>
                    </nav>
                  </div>
                </div>
              </div>
            )}
          </>
        )}
      </div>

      {/* Details Modal */}
      {showDetailsModal && selectedTeam && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-75 overflow-y-auto h-full w-full z-50 flex items-center justify-center p-4">
          <div className="relative w-full max-w-lg shadow-xl rounded-lg bg-white overflow-hidden">
            <div className="bg-gray-50 px-6 py-4 border-b flex justify-between items-center">
                 <h3 className="text-lg font-bold text-gray-900">Team Details</h3>
                 <button onClick={() => setShowDetailsModal(false)} className="text-gray-400 hover:text-gray-600">
                     <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                 </button>
            </div>
            <div className="p-6">
              <div className="flex items-center mb-6">
                   {selectedTeam.team_logo_url ? (
                      <img src={selectedTeam.team_logo_url} alt="" className="h-16 w-16 rounded-full border border-gray-200 mr-4 object-cover" />
                   ) : (
                      <div className="h-16 w-16 rounded-full bg-indigo-100 flex items-center justify-center text-2xl text-indigo-700 font-bold mr-4 border border-indigo-200">
                          {selectedTeam.team_name ? selectedTeam.team_name.charAt(0) : 'T'}
                      </div>
                   )}
                   <div>
                       <h2 className="text-xl font-bold text-gray-900">{selectedTeam.team_name}</h2>
                       <p className="text-gray-500">{selectedTeam.team_location}</p>
                   </div>
              </div>

              <div className="grid grid-cols-3 gap-4 mb-6 text-center">
                 <div className="bg-blue-50 p-3 rounded-lg">
                     <div className="text-2xl font-bold text-blue-700">{selectedTeam.matches_played || 0}</div>
                     <div className="text-xs text-blue-600 uppercase font-semibold">Matches</div>
                 </div>
                 <div className="bg-green-50 p-3 rounded-lg">
                     <div className="text-2xl font-bold text-green-700">{selectedTeam.matches_won || 0}</div>
                     <div className="text-xs text-green-600 uppercase font-semibold">Wins</div>
                 </div>
                 <div className="bg-yellow-50 p-3 rounded-lg">
                     <div className="text-2xl font-bold text-yellow-700">{selectedTeam.trophies || 0}</div>
                     <div className="text-xs text-yellow-600 uppercase font-semibold">Trophies</div>
                 </div>
              </div>

              <div className="border-t pt-4">
                 <h4 className="font-semibold text-gray-800 mb-2">Owner Info</h4>
                 <p className="text-sm text-gray-600">
                     Phone: {selectedTeam.owner_phone || 'N/A'} 
                     {selectedTeam.owner_is_admin && <span className="ml-2 bg-purple-100 text-purple-800 text-xs px-2 py-0.5 rounded-full">Admin</span>}
                 </p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Edit Modal */}
      {showEditModal && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-75 overflow-y-auto h-full w-full z-50 flex items-center justify-center p-4">
          <div className="relative w-full max-w-md shadow-xl rounded-lg bg-white">
            <div className="p-6">
              <h3 className="text-lg font-bold text-gray-900 mb-4">Edit Team</h3>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Team Name</label>
                  <input type="text" value={editForm.team_name} onChange={(e) => setEditForm({...editForm, team_name: e.target.value})} className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Location</label>
                  <input type="text" value={editForm.team_location} onChange={(e) => setEditForm({...editForm, team_location: e.target.value})} className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Logo URL (Optional)</label>
                  <input type="url" value={editForm.team_logo_url} onChange={(e) => setEditForm({...editForm, team_logo_url: e.target.value})} className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500" />
                </div>
              </div>
              <div className="flex justify-end space-x-3 mt-6">
                <button onClick={() => setShowEditModal(false)} className="bg-gray-100 text-gray-700 px-4 py-2 rounded-md text-sm font-medium hover:bg-gray-200">Cancel</button>
                <button onClick={handleUpdateTeam} disabled={actionLoading} className="bg-indigo-600 text-white px-4 py-2 rounded-md text-sm font-medium hover:bg-indigo-700">
                    {actionLoading ? 'Saving...' : 'Save Changes'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Delete Modal */}
      {showDeleteModal && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-75 overflow-y-auto h-full w-full z-50 flex items-center justify-center p-4">
          <div className="relative w-full max-w-md shadow-xl rounded-lg bg-white p-6">
             <div className="flex items-center justify-center w-12 h-12 mx-auto bg-red-100 rounded-full mb-4">
                <svg className="w-6 h-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z"></path></svg>
             </div>
             <h3 className="text-lg font-bold text-gray-900 text-center mb-2">Delete Team?</h3>
             <p className="text-sm text-gray-500 text-center mb-6">
                Are you sure you want to delete <strong>{selectedTeam?.team_name}</strong>? This will also delete all associated players. This action cannot be undone.
             </p>
             <div className="flex justify-end space-x-3">
                <button onClick={() => setShowDeleteModal(false)} className="bg-gray-100 text-gray-700 px-4 py-2 rounded-md text-sm font-medium hover:bg-gray-200">Cancel</button>
                <button onClick={handleDeleteTeam} disabled={actionLoading} className="bg-red-600 text-white px-4 py-2 rounded-md text-sm font-medium hover:bg-red-700">
                    {actionLoading ? 'Deleting...' : 'Delete Team'}
                </button>
             </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default TeamManagement;