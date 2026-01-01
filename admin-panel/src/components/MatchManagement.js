import React, { useState, useEffect } from 'react';
import { adminAPI } from '../services/api';
import LiveMatchView from './LiveMatchView';

const MatchManagement = ({ onToast, onScoreMatch }) => {
  const [matches, setMatches] = useState([]);
  const [filteredMatches, setFilteredMatches] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  // Dropdown Data
  const [teams, setTeams] = useState([]);
  const [tournaments, setTournaments] = useState([]);

  // Modal States
  const [selectedMatch, setSelectedMatch] = useState(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [showCreateModal, setShowCreateModal] = useState(false);

  const [actionLoading, setActionLoading] = useState(false);

  // Progress Bar State (For Rate Limiting)
  const [progress, setProgress] = useState({ current: 0, total: 0 });

  // Bulk actions state
  const [selectedMatches, setSelectedMatches] = useState([]);
  const [selectAll, setSelectAll] = useState(false);

  // Filters
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');

  // Edit Form
  const [editForm, setEditForm] = useState({
    status: '',
    overs: 20,
    winner_team_id: ''
  });

  // Create Form
  const [createForm, setCreateForm] = useState({
    tournament_id: '',
    team1_id: '',
    team2_id: '',
    venue: '',
    match_date: '',
    overs: 20
  });

  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);

  // Live View Mode
  const [viewMode, setViewMode] = useState('list'); // 'list' or 'live'
  const [liveMatchId, setLiveMatchId] = useState(null);

  useEffect(() => {
    fetchMatches();
    fetchDropdownData();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    setCurrentPage(1);
    applyFilters();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [matches, searchTerm, filterStatus]);

  const fetchMatches = async () => {
    try {
      setLoading(true);
      setError('');
      const response = await adminAPI.getAllMatches();

      console.log('Matches API Response:', response.data);

      // Handle different API response structures
      let matchData = [];
      if (Array.isArray(response.data)) {
        matchData = response.data;
      } else if (response.data && Array.isArray(response.data.data)) {
        matchData = response.data.data;
      } else if (response.data && Array.isArray(response.data.matches)) {
        matchData = response.data.matches;
      }

      setMatches(matchData);
    } catch (err) {
      console.error('Fetch Matches Error:', err);
      const errorMsg = err.userMessage || 'Failed to load matches';
      setError(errorMsg);
      if (onToast) onToast(errorMsg, 'error');
    } finally {
      setLoading(false);
    }
  };

  const fetchDropdownData = async () => {
    try {
      const [teamsRes, tournamentsRes] = await Promise.all([
        adminAPI.getAllTeams(),
        adminAPI.getAllTournaments()
      ]);

      // Smart unwrap for Teams
      let teamsData = [];
      if (Array.isArray(teamsRes.data)) teamsData = teamsRes.data;
      else if (teamsRes.data.teams) teamsData = teamsRes.data.teams;
      else if (teamsRes.data.data) teamsData = teamsRes.data.data;
      setTeams(teamsData);

      // Smart unwrap for Tournaments
      let tourneyData = [];
      if (Array.isArray(tournamentsRes.data)) tourneyData = tournamentsRes.data;
      else if (tournamentsRes.data.tournaments) tourneyData = tournamentsRes.data.tournaments;
      else if (tournamentsRes.data.data) tourneyData = tournamentsRes.data.data;
      setTournaments(tourneyData);

    } catch (err) {
      console.error("Failed to load dropdown data", err);
      if (onToast) onToast('Failed to load teams or tournaments', 'error');
    }
  };

  const applyFilters = () => {
    if (!matches) return;

    let filtered = [...matches];

    if (searchTerm) {
      const lowerTerm = searchTerm.toLowerCase();
      filtered = filtered.filter(m =>
        (m.team1_name && m.team1_name.toLowerCase().includes(lowerTerm)) ||
        (m.team2_name && m.team2_name.toLowerCase().includes(lowerTerm)) ||
        (m.tournament_name && m.tournament_name.toLowerCase().includes(lowerTerm)) ||
        (m.venue && m.venue.toLowerCase().includes(lowerTerm))
      );
    }

    if (filterStatus !== 'all') {
      filtered = filtered.filter(m => m.status === filterStatus);
    }

    setFilteredMatches(filtered);
  };

  const formatDate = (dateString) => {
    if (!dateString) return 'Date not set';
    return new Date(dateString).toLocaleString('en-US', {
      month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'
    });
  };

  // --- SAFETY HELPER: Slow down requests ---
  const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

  // --- Handlers ---

  const handleCreateMatch = async () => {
    if (!createForm.team1_id || !createForm.team2_id || !createForm.match_date) {
      if (onToast) onToast('Please fill in Teams and Date', 'error');
      return;
    }

    if (createForm.team1_id === createForm.team2_id) {
      if (onToast) onToast('Teams must be different', 'error');
      return;
    }

    try {
      setActionLoading(true);
      await adminAPI.createMatch(createForm);
      await fetchMatches();
      setShowCreateModal(false);
      setCreateForm({
        tournament_id: '',
        team1_id: '',
        team2_id: '',
        venue: '',
        match_date: '',
        overs: 20
      });
      if (onToast) onToast('Match created successfully', 'success');
    } catch (err) {
      if (onToast) onToast(err.userMessage || 'Failed to create match', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  const handleDeleteMatch = async () => {
    if (!selectedMatch) return;
    try {
      setActionLoading(true);
      await adminAPI.deleteMatch(selectedMatch.id);
      setMatches(matches.filter(m => m.id !== selectedMatch.id));
      setShowDeleteModal(false);
      if (onToast) onToast('Match deleted', 'success');
    } catch (err) {
      if (onToast) onToast(err.userMessage || 'Delete failed', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  const handleUpdateMatch = async () => {
    if (!selectedMatch) return;
    try {
      setActionLoading(true);
      await adminAPI.updateMatch(selectedMatch.id, editForm);
      // Update locally
      const updatedMatches = matches.map(m =>
        m.id === selectedMatch.id ? { ...m, ...editForm } : m
      );
      setMatches(updatedMatches);
      setShowEditModal(false);
      if (onToast) onToast('Match updated', 'success');
    } catch (err) {
      if (onToast) onToast(err.userMessage || 'Update failed', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  // --- Bulk Actions (Fixed for Rate Limiting) ---

  const handleSelectMatch = (matchId) => {
    setSelectedMatches(prev =>
      prev.includes(matchId)
        ? prev.filter(id => id !== matchId)
        : [...prev, matchId]
    );
  };

  const handleSelectAll = () => {
    if (selectAll) {
      setSelectedMatches([]);
    } else {
      setSelectedMatches(paginatedMatches.map(m => m.id));
    }
    setSelectAll(!selectAll);
  };

  const handleBulkDelete = async () => {
    if (selectedMatches.length === 0) return;

    if (!window.confirm(`Are you sure you want to delete ${selectedMatches.length} matches? This cannot be undone.`)) {
      return;
    }

    setActionLoading(true);
    // Initialize Progress
    setProgress({ current: 0, total: selectedMatches.length });

    let successCount = 0;
    let failCount = 0;

    // Execute sequentially with DELAY to avoid server rate limits
    for (let i = 0; i < selectedMatches.length; i++) {
      const matchId = selectedMatches[i];
      try {
        await adminAPI.deleteMatch(matchId);
        successCount++;
      } catch (e) {
        console.error(`Failed to delete match ${matchId}:`, e);
        failCount++;
      }

      // Update progress bar
      setProgress({ current: i + 1, total: selectedMatches.length });

      // WAIT 800ms before the next request
      await delay(800);
    }

    setMatches(prev => prev.filter(m => !selectedMatches.includes(m.id)));
    setSelectedMatches([]);
    setSelectAll(false);
    setActionLoading(false);
    setProgress({ current: 0, total: 0 });

    if (failCount > 0) {
      if (onToast) onToast(`Deleted ${successCount} matches. Failed: ${failCount}`, 'warning');
    } else {
      if (onToast) onToast(`${successCount} matches deleted successfully`, 'success');
    }
  };

  // --- Pagination Logic ---
  const totalItems = filteredMatches.length;
  const totalPages = Math.ceil(totalItems / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const paginatedMatches = filteredMatches.slice(startIndex, endIndex);

  const getStatusColor = (status) => {
    const colors = {
      upcoming: 'bg-blue-100 text-blue-800',
      scheduled: 'bg-indigo-100 text-indigo-800',
      live: 'bg-red-100 text-red-800 animate-pulse',
      completed: 'bg-green-100 text-green-800',
      abandoned: 'bg-gray-100 text-gray-800'
    };
    return colors[status?.toLowerCase()] || 'bg-gray-100 text-gray-800';
  };

  if (viewMode === 'live' && liveMatchId) {
    return <LiveMatchView matchId={liveMatchId} onBack={() => { setViewMode('list'); setLiveMatchId(null); }} onToast={onToast} />;
  }

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  return (
    <div>
      {/* Header */}
      <div className="mb-6 flex flex-col sm:flex-row justify-between items-start sm:items-center space-y-4 sm:space-y-0">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Match Management</h1>
          <p className="mt-1 text-sm text-gray-600">
            Total Matches: {matches.length}
          </p>
        </div>
        <button
          onClick={() => setShowCreateModal(true)}
          className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none"
        >
          <svg className="-ml-1 mr-2 h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 4v16m8-8H4" />
          </svg>
          Create Match
        </button>
      </div>

      {error && (
        <div className="mb-4 bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg flex justify-between items-center">
          <span>{error}</span>
          <button onClick={fetchMatches} className="bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded text-sm">
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

      {/* Filters */}
      <div className="bg-white p-4 rounded-lg shadow-sm border border-gray-200 mb-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">Search Matches</label>
            <div className="relative rounded-md shadow-sm">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <svg className="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
              </div>
              <input
                type="text"
                className="focus:ring-indigo-500 focus:border-indigo-500 block w-full pl-10 sm:text-sm border-gray-300 rounded-md py-2 border"
                placeholder="Team name, venue..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">Filter by Status</label>
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              className="block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md border"
            >
              <option value="all">All Matches</option>
              <option value="scheduled">Scheduled</option>
              <option value="live">Live</option>
              <option value="completed">Completed</option>
            </select>
          </div>
        </div>
      </div>

      {/* Bulk Actions Bar */}
      {selectedMatches.length > 0 && !actionLoading && (
        <div className="mb-4 bg-indigo-50 border border-indigo-200 rounded-lg p-4 transition-all duration-300">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <span className="text-sm font-medium text-indigo-800">
                {selectedMatches.length} selected
              </span>
              <button
                onClick={() => setSelectedMatches([])}
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

      {/* Table */}
      <div className="bg-white shadow overflow-hidden sm:rounded-lg border border-gray-200">
        {filteredMatches.length === 0 ? (
          <div className="p-10 text-center flex flex-col items-center">
            <svg className="h-12 w-12 text-gray-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
            </svg>
            <p className="text-gray-500 text-lg">No matches found</p>
            <p className="text-gray-400 text-sm">Try adjusting your search or create a new match.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th scope="col" className="px-4 py-3 w-10">
                    <input
                      type="checkbox"
                      checked={selectAll}
                      onChange={handleSelectAll}
                      disabled={actionLoading}
                      className="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                    />
                  </th>
                  <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Match Details</th>
                  <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Tournament</th>
                  <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                  <th scope="col" className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {paginatedMatches.map((match) => (
                  <tr key={match.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-4 py-4">
                      <input
                        type="checkbox"
                        checked={selectedMatches.includes(match.id)}
                        onChange={() => handleSelectMatch(match.id)}
                        disabled={actionLoading}
                        className="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                      />
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center">
                        <div className="ml-0">
                          <div className="text-sm font-bold text-gray-900">
                            {match.team1_name} <span className="text-gray-400 font-normal">vs</span> {match.team2_name}
                          </div>
                          <div className="text-xs text-gray-500 mt-1 flex items-center">
                            <svg className="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>
                            {formatDate(match.match_date)}
                          </div>
                          <div className="text-xs text-gray-400 mt-0.5">
                            {match.venue || 'No Venue Specified'}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900">{match.tournament_name || 'Friendly Match'}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${getStatusColor(match.status)}`}>
                        {match.status ? match.status.toUpperCase() : 'UNKNOWN'}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <button onClick={() => { setSelectedMatch(match); setShowDetailsModal(true); }} className="text-indigo-600 hover:text-indigo-900 mx-2">
                        Details
                      </button>
                      <button
                        onClick={() => { setLiveMatchId(match.id); setViewMode('live'); }}
                        className={`mx-2 ${match.status === 'live' ? 'text-orange-600 hover:text-orange-800 font-bold flex items-center inline-flex' : 'text-gray-400 hover:text-indigo-600'}`}
                      >
                        {match.status === 'live' && <span className="mr-1 w-2 h-2 bg-orange-600 rounded-full animate-pulse inline-block"></span>}
                        Monitor
                      </button>

                      {match.status === 'not_started' && (
                        <button
                          onClick={() => onScoreMatch(match.id)}
                          className="text-green-600 hover:text-green-900 mx-2 font-medium"
                        >
                          Score
                        </button>
                      )}

                      {match.status === 'live' && (
                        <button
                          onClick={() => onScoreMatch(match.id)}
                          className="text-indigo-600 hover:text-indigo-900 mx-2 font-medium"
                        >
                          Resume
                        </button>
                      )}
                      <button onClick={() => {
                        setSelectedMatch(match);
                        setEditForm({ status: match.status, overs: match.overs, winner_team_id: match.winner_team_id || '' });
                        setShowEditModal(true);
                      }} className="text-blue-600 hover:text-blue-900 mx-2">
                        Edit
                      </button>
                      <button onClick={() => { setSelectedMatch(match); setShowDeleteModal(true); }} className="text-red-600 hover:text-red-900 mx-2">
                        Delete
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Internal Pagination */}
        {filteredMatches.length > 0 && (
          <div className="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6">
            <div className="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
              <div>
                <p className="text-sm text-gray-700">
                  Showing <span className="font-medium">{startIndex + 1}</span> to <span className="font-medium">{Math.min(endIndex, totalItems)}</span> of <span className="font-medium">{totalItems}</span> results
                </p>
              </div>
              <div>
                <nav className="relative z-0 inline-flex rounded-md shadow-sm -space-x-px" aria-label="Pagination">
                  <button
                    onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
                    disabled={currentPage === 1}
                    className={`relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium ${currentPage === 1 ? 'text-gray-300 cursor-not-allowed' : 'text-gray-500 hover:bg-gray-50'}`}
                  >
                    Previous
                  </button>
                  <button
                    onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))}
                    disabled={currentPage === totalPages}
                    className={`relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium ${currentPage === totalPages ? 'text-gray-300 cursor-not-allowed' : 'text-gray-500 hover:bg-gray-50'}`}
                  >
                    Next
                  </button>
                </nav>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* --- MODALS --- */}

      {/* Create Modal */}
      {showCreateModal && (
        <div className="fixed inset-0 z-50 overflow-y-auto" aria-labelledby="modal-title" role="dialog" aria-modal="true">
          <div className="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
            <div className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" onClick={() => setShowCreateModal(false)}></div>
            <span className="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>
            <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
              <div className="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                <h3 className="text-lg leading-6 font-medium text-gray-900 mb-4" id="modal-title">Create New Match</h3>
                <div className="space-y-4">
                  {/* Tournament */}
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Tournament</label>
                    <select className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                      value={createForm.tournament_id}
                      onChange={(e) => setCreateForm({ ...createForm, tournament_id: e.target.value })}
                    >
                      <option value="">Friendly Match (No Tournament)</option>
                      {tournaments.map(t => <option key={t.id} value={t.id}>{t.tournament_name}</option>)}
                    </select>
                  </div>
                  {/* Teams */}
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Home Team</label>
                      <select className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                        value={createForm.team1_id}
                        onChange={(e) => setCreateForm({ ...createForm, team1_id: e.target.value })}
                      >
                        <option value="">Select Team</option>
                        {teams.map(t => <option key={t.id} value={t.id}>{t.team_name}</option>)}
                      </select>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Away Team</label>
                      <select className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                        value={createForm.team2_id}
                        onChange={(e) => setCreateForm({ ...createForm, team2_id: e.target.value })}
                      >
                        <option value="">Select Team</option>
                        {teams.filter(t => t.id !== createForm.team1_id).map(t => <option key={t.id} value={t.id}>{t.team_name}</option>)}
                      </select>
                    </div>
                  </div>
                  {/* Date & Venue */}
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Date & Time</label>
                    <input type="datetime-local" className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                      value={createForm.match_date}
                      onChange={(e) => setCreateForm({ ...createForm, match_date: e.target.value })}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Venue</label>
                    <input type="text" className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                      placeholder="Stadium Name"
                      value={createForm.venue}
                      onChange={(e) => setCreateForm({ ...createForm, venue: e.target.value })}
                    />
                  </div>
                </div>
              </div>
              <div className="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                <button type="button"
                  disabled={actionLoading}
                  className="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-indigo-600 text-base font-medium text-white hover:bg-indigo-700 focus:outline-none sm:ml-3 sm:w-auto sm:text-sm"
                  onClick={handleCreateMatch}
                >
                  {actionLoading ? 'Creating...' : 'Create Match'}
                </button>
                <button type="button" className="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
                  onClick={() => setShowCreateModal(false)}
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Delete Modal */}
      {showDeleteModal && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
            <div className="fixed inset-0 bg-gray-500 bg-opacity-75" onClick={() => setShowDeleteModal(false)}></div>
            <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
              <div className="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                <div className="sm:flex sm:items-start">
                  <div className="mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-red-100 sm:mx-0 sm:h-10 sm:w-10">
                    <svg className="h-6 w-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z"></path></svg>
                  </div>
                  <div className="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
                    <h3 className="text-lg leading-6 font-medium text-gray-900">Delete Match</h3>
                    <div className="mt-2">
                      <p className="text-sm text-gray-500">Are you sure you want to delete this match? This action cannot be undone and will remove all scores and stats.</p>
                    </div>
                  </div>
                </div>
              </div>
              <div className="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                <button type="button" onClick={handleDeleteMatch} className="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-red-600 text-base font-medium text-white hover:bg-red-700 sm:ml-3 sm:w-auto sm:text-sm">
                  {actionLoading ? 'Deleting...' : 'Delete'}
                </button>
                <button type="button" onClick={() => setShowDeleteModal(false)} className="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm">
                  Cancel
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Edit Modal */}
      {showEditModal && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
            <div className="fixed inset-0 bg-gray-500 bg-opacity-75" onClick={() => setShowEditModal(false)}></div>
            <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
              <div className="bg-white px-4 pt-5 pb-4 sm:p-6">
                <h3 className="text-lg font-medium text-gray-900 mb-4">Update Match Status</h3>
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Status</label>
                    <select className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3"
                      value={editForm.status}
                      onChange={(e) => setEditForm({ ...editForm, status: e.target.value })}
                    >
                      <option value="scheduled">Scheduled</option>
                      <option value="live">Live</option>
                      <option value="completed">Completed</option>
                      <option value="abandoned">Abandoned</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Overs</label>
                    <input type="number" className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3"
                      value={editForm.overs}
                      onChange={(e) => setEditForm({ ...editForm, overs: parseInt(e.target.value) })}
                    />
                  </div>
                </div>
              </div>
              <div className="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                <button type="button" onClick={handleUpdateMatch} className="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-blue-600 text-base font-medium text-white hover:bg-blue-700 sm:ml-3 sm:w-auto sm:text-sm">
                  {actionLoading ? 'Saving...' : 'Save Changes'}
                </button>
                <button type="button" onClick={() => setShowEditModal(false)} className="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm">
                  Cancel
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Details Modal */}
      {showDetailsModal && selectedMatch && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
            <div className="fixed inset-0 bg-gray-500 bg-opacity-75" onClick={() => setShowDetailsModal(false)}></div>
            <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
              <div className="bg-white px-4 pt-5 pb-4 sm:p-6">
                <h3 className="text-lg font-bold text-gray-900 mb-4">Match Details #{selectedMatch.id}</h3>
                <div className="grid grid-cols-2 gap-4 text-center mb-4">
                  <div className="bg-gray-50 p-3 rounded">
                    <p className="text-xs text-gray-500">HOME TEAM</p>
                    <p className="font-bold text-lg">{selectedMatch.team1_name}</p>
                  </div>
                  <div className="bg-gray-50 p-3 rounded">
                    <p className="text-xs text-gray-500">AWAY TEAM</p>
                    <p className="font-bold text-lg">{selectedMatch.team2_name}</p>
                  </div>
                </div>
                <div className="text-sm text-gray-600 space-y-2">
                  <p><strong>Tournament:</strong> {selectedMatch.tournament_name || 'Friendly'}</p>
                  <p><strong>Venue:</strong> {selectedMatch.venue || 'N/A'}</p>
                  <p><strong>Date:</strong> {formatDate(selectedMatch.match_date)}</p>
                </div>
              </div>
              <div className="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                <button type="button" onClick={() => setShowDetailsModal(false)} className="w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 sm:ml-3 sm:w-auto sm:text-sm">
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