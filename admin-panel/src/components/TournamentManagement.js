import React, { useState, useEffect } from 'react';
import { adminAPI } from '../services/api';

const TournamentManagement = ({ onToast }) => {
  const [tournaments, setTournaments] = useState([]);
  const [filteredTournaments, setFilteredTournaments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  // Modals
  const [selectedTournament, setSelectedTournament] = useState(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);

  const [actionLoading, setActionLoading] = useState(false);
  
  // Progress Bar (Rate Limiting)
  const [progress, setProgress] = useState({ current: 0, total: 0 });

  // Bulk Selection
  const [selectedTournaments, setSelectedTournaments] = useState([]);
  const [selectAll, setSelectAll] = useState(false);
  
  // Filters
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');

  // Forms
  const initialFormState = {
    tournament_name: '',
    location: '',
    start_date: '',
    end_date: '',
    status: 'upcoming'
  };

  const [formData, setFormData] = useState(initialFormState);

  useEffect(() => {
    fetchTournaments();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    applyFilters();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tournaments, searchTerm, filterStatus]);

  const fetchTournaments = async () => {
    try {
      setLoading(true);
      setError('');
      const response = await adminAPI.getAllTournaments();
      
      // Smart Unwrap
      let data = [];
      if (Array.isArray(response.data)) {
        data = response.data;
      } else if (response.data && Array.isArray(response.data.tournaments)) {
        data = response.data.tournaments;
      } else if (response.data && Array.isArray(response.data.data)) {
        data = response.data.data;
      }

      setTournaments(data);
    } catch (err) {
      console.error('Fetch Tournaments Error:', err);
      const errorMsg = err.userMessage || 'Failed to load tournaments';
      setError(errorMsg);
      if (onToast) onToast(errorMsg, 'error');
    } finally {
      setLoading(false);
    }
  };

  const applyFilters = () => {
    if (!tournaments) return;
    let filtered = [...tournaments];

    // Search filter
    if (searchTerm) {
      const lowerTerm = searchTerm.toLowerCase();
      filtered = filtered.filter(t =>
        (t.tournament_name && t.tournament_name.toLowerCase().includes(lowerTerm)) ||
        (t.location && t.location.toLowerCase().includes(lowerTerm))
      );
    }

    // Status filter
    if (filterStatus !== 'all') {
      filtered = filtered.filter(t => t.status === filterStatus);
    }

    setFilteredTournaments(filtered);
  };

  // --- SAFETY HELPER: Slow down requests ---
  const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

  // --- Bulk Actions ---

  const handleSelectTournament = (id) => {
    setSelectedTournaments(prev => 
      prev.includes(id) ? prev.filter(tId => tId !== id) : [...prev, id]
    );
  };

  const handleSelectAll = () => {
    if (selectAll) {
      setSelectedTournaments([]);
    } else {
      setSelectedTournaments(filteredTournaments.map(t => t.id));
    }
    setSelectAll(!selectAll);
  };

  const handleBulkDelete = async () => {
    if (selectedTournaments.length === 0) return;

    if (!window.confirm(`Are you sure you want to delete ${selectedTournaments.length} tournaments? This cannot be undone.`)) {
      return;
    }

    setActionLoading(true);
    setProgress({ current: 0, total: selectedTournaments.length });

    let successCount = 0;
    let failCount = 0;

    // Sequential Delete with Delay
    for (let i = 0; i < selectedTournaments.length; i++) {
        const id = selectedTournaments[i];
        try {
            await adminAPI.deleteTournament(id);
            successCount++;
        } catch (e) {
            console.error(`Failed to delete tournament ${id}`, e);
            failCount++;
        }

        setProgress({ current: i + 1, total: selectedTournaments.length });
        await delay(800); // 800ms delay prevents rate limit error
    }

    // Cleanup
    setTournaments(prev => prev.filter(t => !selectedTournaments.includes(t.id)));
    setSelectedTournaments([]);
    setSelectAll(false);
    setActionLoading(false);
    setProgress({ current: 0, total: 0 });

    if (onToast) {
        if (failCount > 0) onToast(`Deleted ${successCount}, Failed ${failCount}`, 'warning');
        else onToast('Bulk delete successful', 'success');
    }
  };

  // --- Single Actions ---

  const handleCreateTournament = async () => {
    if (!formData.tournament_name || !formData.start_date) {
        if(onToast) onToast('Name and Start Date are required', 'error');
        return;
    }

    try {
        setActionLoading(true);
        await adminAPI.createTournament(formData);
        await fetchTournaments(); 
        setShowCreateModal(false);
        setFormData(initialFormState);
        if(onToast) onToast('Tournament created successfully', 'success');
    } catch (err) {
        if(onToast) onToast(err.userMessage || 'Failed to create tournament', 'error');
    } finally {
        setActionLoading(false);
    }
  };

  const handleUpdateTournament = async () => {
      if (!selectedTournament) return;
      
      try {
          setActionLoading(true);
          await adminAPI.updateTournament(selectedTournament.id, formData);
          
          setTournaments(prev => prev.map(t => 
            t.id === selectedTournament.id ? { ...t, ...formData } : t
          ));

          setShowEditModal(false);
          if(onToast) onToast('Tournament updated successfully', 'success');
      } catch (err) {
          if(onToast) onToast(err.userMessage || 'Failed to update tournament', 'error');
      } finally {
          setActionLoading(false);
      }
  };

  const handleDeleteTournament = async () => {
    if (!selectedTournament) return;

    try {
      setActionLoading(true);
      await adminAPI.deleteTournament(selectedTournament.id);
      setTournaments(tournaments.filter(t => t.id !== selectedTournament.id));
      setShowDeleteModal(false);
      setSelectedTournament(null);
      if (onToast) onToast('Tournament deleted successfully', 'success');
    } catch (err) {
      if (onToast) onToast(err.userMessage || 'Failed to delete tournament', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  const openEditModal = (tournament) => {
      setSelectedTournament(tournament);
      setFormData({
          tournament_name: tournament.tournament_name,
          location: tournament.location || '',
          start_date: tournament.start_date ? new Date(tournament.start_date).toISOString().slice(0, 16) : '',
          end_date: tournament.end_date ? new Date(tournament.end_date).toISOString().slice(0, 16) : '',
          status: tournament.status || 'upcoming'
      });
      setShowEditModal(true);
  };

  // --- Helpers ---

  const getStatusColor = (status) => {
    const colors = {
      upcoming: 'bg-blue-100 text-blue-800',
      live: 'bg-green-100 text-green-800 animate-pulse',
      completed: 'bg-gray-100 text-gray-800',
      abandoned: 'bg-red-100 text-red-800'
    };
    return colors[status?.toLowerCase()] || 'bg-gray-100 text-gray-800';
  };

  const formatDate = (dateString) => {
      if(!dateString) return 'TBD';
      return new Date(dateString).toLocaleDateString('en-US', {
          year: 'numeric', month: 'short', day: 'numeric'
      });
  };

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
          <h1 className="text-2xl font-bold text-gray-900">Tournament Management</h1>
          <p className="mt-1 text-sm text-gray-600">
            Active and past tournaments (Total: {tournaments.length})
          </p>
        </div>
        <button
          onClick={() => { setFormData(initialFormState); setShowCreateModal(true); }}
          className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none"
        >
          <svg className="-ml-1 mr-2 h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 4v16m8-8H4" /></svg>
          Create Tournament
        </button>
      </div>

      {error && (
        <div className="mb-4 bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg flex justify-between items-center">
          <span>{error}</span>
          <button onClick={fetchTournaments} className="bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded text-sm">
            Retry
          </button>
        </div>
      )}

      {/* Progress Bar for Bulk Actions */}
      {actionLoading && progress.total > 0 && (
        <div className="mb-4 bg-blue-50 border border-blue-100 rounded-lg p-4">
            <div className="flex justify-between mb-1">
                <span className="text-sm font-medium text-blue-700">Deleting Tournaments...</span>
                <span className="text-sm font-medium text-blue-700">{progress.current}/{progress.total}</span>
            </div>
            <div className="w-full bg-blue-200 rounded-full h-2.5">
                <div className="bg-blue-600 h-2.5 rounded-full transition-all duration-300" style={{ width: `${(progress.current / progress.total) * 100}%` }}></div>
            </div>
        </div>
      )}

      {/* Search and Filter */}
      <div className="mb-6 bg-white p-4 rounded-lg shadow-sm border border-gray-200">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">
              Search
            </label>
            <div className="relative rounded-md shadow-sm">
                 <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <svg className="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" /></svg>
                 </div>
                 <input
                  type="text"
                  placeholder="Name or location..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="focus:ring-indigo-500 focus:border-indigo-500 block w-full pl-10 sm:text-sm border-gray-300 rounded-md py-2 border"
                 />
            </div>
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">
              Status Filter
            </label>
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              className="block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md border"
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

      {/* Bulk Actions Bar */}
      <div className="mb-4 bg-gray-50 border border-gray-200 rounded-lg p-3 flex items-center justify-between">
         <div className="flex items-center space-x-3">
            <input 
                type="checkbox" 
                checked={selectAll}
                onChange={handleSelectAll}
                disabled={actionLoading}
                className="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
            />
            <span className="text-sm font-medium text-gray-700">Select All</span>
            {selectedTournaments.length > 0 && (
                <span className="text-sm text-indigo-600 font-semibold bg-indigo-50 px-2 py-0.5 rounded">
                    {selectedTournaments.length} Selected
                </span>
            )}
         </div>
         {selectedTournaments.length > 0 && (
             <button 
                onClick={handleBulkDelete}
                disabled={actionLoading}
                className="text-sm bg-red-600 text-white px-3 py-1.5 rounded hover:bg-red-700 disabled:opacity-50 flex items-center"
             >
                <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" /></svg>
                Delete Selected
             </button>
         )}
      </div>

      {/* Tournaments Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredTournaments.length === 0 ? (
          <div className="col-span-full p-10 text-center bg-white rounded-lg shadow border border-gray-200">
             <svg className="mx-auto h-12 w-12 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" /></svg>
            <p className="mt-2 text-gray-500">No tournaments found.</p>
          </div>
        ) : (
          filteredTournaments.map((tournament) => (
            <div key={tournament.id} className={`bg-white shadow rounded-lg overflow-hidden border transition-all duration-200 flex flex-col ${selectedTournaments.includes(tournament.id) ? 'border-indigo-500 ring-2 ring-indigo-200' : 'border-gray-200 hover:shadow-md'}`}>
              <div className="p-6 flex-1 relative">
                {/* Card Checkbox */}
                <div className="absolute top-4 right-4">
                    <input 
                        type="checkbox"
                        checked={selectedTournaments.includes(tournament.id)}
                        onChange={() => handleSelectTournament(tournament.id)}
                        className="h-5 w-5 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded cursor-pointer"
                    />
                </div>

                <div className="flex items-start justify-between mb-4 pr-8">
                  <div className="flex-1">
                    <h3 className="text-lg font-bold text-gray-900 leading-tight">
                      {tournament.tournament_name}
                    </h3>
                    <p className="text-sm text-gray-500 mt-1 flex items-center">
                        <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" /></svg>
                        {tournament.location || 'No Location'}
                    </p>
                  </div>
                </div>
                
                <div className="mb-4">
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium uppercase ${getStatusColor(tournament.status)}`}>
                        {tournament.status}
                    </span>
                </div>

                <div className="space-y-3 mt-4">
                  <div className="flex items-center text-sm text-gray-600">
                     <svg className="w-4 h-4 mr-2 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg>
                     <span>Start: <span className="font-semibold text-gray-900">{formatDate(tournament.start_date)}</span></span>
                  </div>
                  <div className="flex items-center text-sm text-gray-600">
                     <svg className="w-4 h-4 mr-2 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" /></svg>
                     <span>Organizer: User #{tournament.created_by}</span>
                  </div>
                </div>
              </div>

              <div className="bg-gray-50 px-6 py-3 border-t border-gray-200 flex space-x-2">
                <button
                  onClick={() => openEditModal(tournament)}
                  className="flex-1 bg-white border border-gray-300 text-gray-700 hover:bg-gray-50 px-3 py-2 rounded-md text-sm font-medium transition-colors shadow-sm"
                >
                  Edit
                </button>
                <button
                  onClick={() => {
                    setSelectedTournament(tournament);
                    setShowDeleteModal(true);
                  }}
                  className="bg-white border border-red-300 text-red-700 hover:bg-red-50 px-3 py-2 rounded-md text-sm font-medium transition-colors shadow-sm"
                >
                  Delete
                </button>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Create/Edit Modal */}
      {(showCreateModal || showEditModal) && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
            <div className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" onClick={() => { setShowCreateModal(false); setShowEditModal(false); }}></div>
            <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
              <div className="bg-white px-4 pt-5 pb-4 sm:p-6">
                <h3 className="text-lg leading-6 font-medium text-gray-900 mb-4">
                    {showEditModal ? 'Edit Tournament' : 'Create New Tournament'}
                </h3>
                <div className="space-y-4">
                    <div>
                        <label className="block text-sm font-medium text-gray-700">Tournament Name *</label>
                        <input 
                            type="text" 
                            className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                            value={formData.tournament_name}
                            onChange={(e) => setFormData({...formData, tournament_name: e.target.value})}
                        />
                    </div>
                    <div>
                        <label className="block text-sm font-medium text-gray-700">Location</label>
                        <input 
                            type="text" 
                            className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                            value={formData.location}
                            onChange={(e) => setFormData({...formData, location: e.target.value})}
                        />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700">Start Date *</label>
                            <input 
                                type="datetime-local" 
                                className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                                value={formData.start_date}
                                onChange={(e) => setFormData({...formData, start_date: e.target.value})}
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700">End Date</label>
                            <input 
                                type="datetime-local" 
                                className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                                value={formData.end_date}
                                onChange={(e) => setFormData({...formData, end_date: e.target.value})}
                            />
                        </div>
                    </div>
                    <div>
                        <label className="block text-sm font-medium text-gray-700">Status</label>
                        <select 
                            className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                            value={formData.status}
                            onChange={(e) => setFormData({...formData, status: e.target.value})}
                        >
                            <option value="upcoming">Upcoming</option>
                            <option value="live">Live</option>
                            <option value="completed">Completed</option>
                            <option value="abandoned">Abandoned</option>
                        </select>
                    </div>
                </div>
              </div>
              <div className="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                <button 
                    type="button"
                    disabled={actionLoading}
                    onClick={showEditModal ? handleUpdateTournament : handleCreateTournament}
                    className="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-indigo-600 text-base font-medium text-white hover:bg-indigo-700 focus:outline-none sm:ml-3 sm:w-auto sm:text-sm"
                >
                  {actionLoading ? 'Saving...' : (showEditModal ? 'Update' : 'Create')}
                </button>
                <button 
                    type="button" 
                    onClick={() => { setShowCreateModal(false); setShowEditModal(false); }}
                    className="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Delete Confirmation Modal */}
      {showDeleteModal && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
            <div className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" onClick={() => setShowDeleteModal(false)}></div>
            <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
              <div className="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                <div className="sm:flex sm:items-start">
                  <div className="mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-red-100 sm:mx-0 sm:h-10 sm:w-10">
                    <svg className="h-6 w-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z" /></svg>
                  </div>
                  <div className="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
                    <h3 className="text-lg leading-6 font-medium text-gray-900">Delete Tournament</h3>
                    <div className="mt-2">
                      <p className="text-sm text-gray-500">
                        Are you sure you want to delete <strong>{selectedTournament?.tournament_name}</strong>? This will also delete all associated matches and data. This action cannot be undone.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
              <div className="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                <button 
                  type="button" 
                  disabled={actionLoading}
                  onClick={handleDeleteTournament}
                  className="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-red-600 text-base font-medium text-white hover:bg-red-700 focus:outline-none sm:ml-3 sm:w-auto sm:text-sm"
                >
                  {actionLoading ? 'Deleting...' : 'Delete'}
                </button>
                <button 
                  type="button" 
                  onClick={() => setShowDeleteModal(false)}
                  className="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
                >
                  Cancel
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