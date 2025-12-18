import React, { useState, useEffect } from 'react';
import { adminAPI } from '../services/api';

const UserManagement = ({ onToast }) => {
  const [users, setUsers] = useState([]);
  const [filteredUsers, setFilteredUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  
  // Selection & Modals
  const [selectedUser, setSelectedUser] = useState(null);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);
  
  // Progress Bar State (For Rate Limiting)
  const [progress, setProgress] = useState({ current: 0, total: 0 });

  // Filters
  const [searchTerm, setSearchTerm] = useState('');
  const [filterAdmin, setFilterAdmin] = useState('all');

  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);

  // Bulk actions state
  const [selectedUsers, setSelectedUsers] = useState([]);
  const [selectAll, setSelectAll] = useState(false);

  useEffect(() => {
    fetchUsers();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Re-run filters when dependencies change
  useEffect(() => {
    setCurrentPage(1); // Reset to page 1 on filter change
    applyFilters();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [users, searchTerm, filterAdmin]);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      setError('');
      const response = await adminAPI.getAllUsers();
      console.log('Users API Response:', response.data);

      // Smart Unwrap: Handle different API structures
      let userData = [];
      if (Array.isArray(response.data)) {
        userData = response.data;
      } else if (response.data && Array.isArray(response.data.users)) {
        userData = response.data.users;
      } else if (response.data && Array.isArray(response.data.data)) {
        userData = response.data.data;
      }

      setUsers(userData);
    } catch (err) {
      console.error('Fetch Users Error:', err);
      const errorMsg = err.userMessage || 'Failed to load users';
      setError(errorMsg);
      if (onToast) onToast(errorMsg, 'error');
    } finally {
      setLoading(false);
    }
  };

  const applyFilters = () => {
    if (!users) return;
    let filtered = [...users];

    // Filter by search term
    if (searchTerm) {
      const lowerTerm = searchTerm.toLowerCase();
      filtered = filtered.filter(user =>
        (user.phone_number && user.phone_number.toLowerCase().includes(lowerTerm)) ||
        (user.username && user.username.toLowerCase().includes(lowerTerm)) ||
        (user.team_name && user.team_name.toLowerCase().includes(lowerTerm))
      );
    }

    // Filter by admin status
    if (filterAdmin !== 'all') {
      filtered = filtered.filter(user => user.is_admin === (filterAdmin === 'admin'));
    }

    setFilteredUsers(filtered);
  };

  // --- SAFETY HELPER: Slow down requests ---
  const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

  // --- Actions ---

  const handleToggleAdmin = async (userId, currentStatus) => {
    try {
      setActionLoading(true);
      await adminAPI.updateUserAdminStatus(userId, !currentStatus);
      
      // Optimistic Update
      setUsers(users.map(user =>
        user.id === userId
          ? { ...user, is_admin: !currentStatus }
          : user
      ));
      
      if (onToast) onToast(
        !currentStatus ? 'User promoted to Admin' : 'Admin privileges revoked',
        'success'
      );
    } catch (err) {
      if (onToast) onToast(err.userMessage || 'Status update failed', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  const handleDeleteUser = async () => {
    if (!selectedUser) return;

    try {
      setActionLoading(true);
      await adminAPI.deleteUser(selectedUser.id);
      
      setUsers(users.filter(user => user.id !== selectedUser.id));
      setShowDeleteModal(false);
      setSelectedUser(null);
      
      if (onToast) onToast('User deleted successfully', 'success');
    } catch (err) {
      if (onToast) onToast(err.userMessage || 'Delete failed', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  // --- Bulk Actions ---

  const handleSelectUser = (userId) => {
    setSelectedUsers(prev =>
      prev.includes(userId)
        ? prev.filter(id => id !== userId)
        : [...prev, userId]
    );
  };

  const handleSelectAll = () => {
    if (selectAll) {
      setSelectedUsers([]);
    } else {
      // Select only visible users on current page
      setSelectedUsers(paginatedUsers.map(user => user.id));
    }
    setSelectAll(!selectAll);
  };

  const processBulkAction = async (actionType) => {
    if (selectedUsers.length === 0) return;
    
    // Safety check for delete
    if (actionType === 'delete' && !window.confirm(`Delete ${selectedUsers.length} users? This cannot be undone.`)) {
        return;
    }

    setActionLoading(true);
    // Initialize Progress
    setProgress({ current: 0, total: selectedUsers.length });

    let successCount = 0;
    let failCount = 0;

    // Execute sequentially with DELAY to avoid server rate limits
    for (let i = 0; i < selectedUsers.length; i++) {
        const userId = selectedUsers[i];
        try {
            if (actionType === 'promote') await adminAPI.updateUserAdminStatus(userId, true);
            else if (actionType === 'demote') await adminAPI.updateUserAdminStatus(userId, false);
            else if (actionType === 'delete') await adminAPI.deleteUser(userId);
            successCount++;
        } catch (e) {
            console.error(`Failed to process user ${userId}`, e);
            failCount++;
        }

        // Update progress bar
        setProgress({ current: i + 1, total: selectedUsers.length });

        // WAIT 800ms before the next request (prevents Rate Limit Exceeded)
        await delay(800); 
    }

    // Refresh Data
    await fetchUsers();
    setSelectedUsers([]);
    setSelectAll(false);
    setActionLoading(false);
    setProgress({ current: 0, total: 0 });

    if (onToast) {
        if (failCount > 0) onToast(`Processed ${successCount}, Failed ${failCount}`, 'warning');
        else onToast('Bulk action completed successfully', 'success');
    }
  };

  // --- Pagination Logic ---
  const totalItems = filteredUsers.length;
  const totalPages = Math.ceil(totalItems / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const paginatedUsers = filteredUsers.slice(startIndex, startIndex + itemsPerPage);

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">User Management</h1>
        <p className="mt-1 text-sm text-gray-600">
          Total Users: {users.length} | Admins: {users.filter(u => u.is_admin).length}
        </p>
      </div>

      {error && (
        <div className="mb-4 bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg flex justify-between items-center">
          <span>{error}</span>
          <button onClick={fetchUsers} className="bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded text-sm">Retry</button>
        </div>
      )}

      {/* Progress Bar for Bulk Actions */}
      {actionLoading && progress.total > 0 && (
        <div className="mb-4 bg-blue-50 border border-blue-100 rounded-lg p-4">
            <div className="flex justify-between mb-1">
                <span className="text-sm font-medium text-blue-700">Processing... (Slowed to prevent server error)</span>
                <span className="text-sm font-medium text-blue-700">{progress.current}/{progress.total}</span>
            </div>
            <div className="w-full bg-blue-200 rounded-full h-2.5">
                <div className="bg-blue-600 h-2.5 rounded-full transition-all duration-300" style={{ width: `${(progress.current / progress.total) * 100}%` }}></div>
            </div>
        </div>
      )}

      {/* Filters */}
      <div className="mb-6 bg-white p-4 rounded-lg shadow-sm border border-gray-200">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">Search</label>
            <div className="relative rounded-md shadow-sm">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <svg className="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>
                </div>
                <input
                  type="text"
                  placeholder="Phone, username, or team..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="focus:ring-indigo-500 focus:border-indigo-500 block w-full pl-10 sm:text-sm border-gray-300 rounded-md py-2 border"
                />
            </div>
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">Filter Type</label>
            <select
              value={filterAdmin}
              onChange={(e) => setFilterAdmin(e.target.value)}
              className="block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md border"
            >
              <option value="all">All Users</option>
              <option value="admin">Admins Only</option>
              <option value="regular">Regular Users</option>
            </select>
          </div>
        </div>
      </div>

      {/* Bulk Actions Toolbar */}
      {selectedUsers.length > 0 && !actionLoading && (
        <div className="mb-4 bg-indigo-50 border border-indigo-200 rounded-lg p-4 flex flex-col sm:flex-row items-center justify-between space-y-3 sm:space-y-0">
          <div className="flex items-center space-x-4">
            <span className="text-sm font-medium text-indigo-900">
              {selectedUsers.length} selected
            </span>
            <button onClick={() => setSelectedUsers([])} className="text-sm text-indigo-600 hover:text-indigo-800 underline">
              Clear
            </button>
          </div>
          <div className="flex space-x-2">
            <button onClick={() => processBulkAction('promote')} disabled={actionLoading} className="bg-white border border-gray-300 text-gray-700 px-3 py-1.5 rounded-md text-sm font-medium hover:bg-gray-50">
               Make Admin
            </button>
            <button onClick={() => processBulkAction('demote')} disabled={actionLoading} className="bg-white border border-gray-300 text-gray-700 px-3 py-1.5 rounded-md text-sm font-medium hover:bg-gray-50">
               Remove Admin
            </button>
            <button onClick={() => processBulkAction('delete')} disabled={actionLoading} className="bg-red-600 text-white px-3 py-1.5 rounded-md text-sm font-medium hover:bg-red-700">
               Delete
            </button>
          </div>
        </div>
      )}

      {/* Users List */}
      <div className="bg-white shadow overflow-hidden sm:rounded-md border border-gray-200">
        {filteredUsers.length === 0 ? (
          <div className="p-10 text-center">
            <svg className="mx-auto h-12 w-12 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"></path></svg>
            <p className="mt-2 text-gray-500">No users found.</p>
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
                <span className="ml-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Select Page</span>
            </div>

            <ul className="divide-y divide-gray-200">
              {paginatedUsers.map((user) => (
                <li key={user.id} className="hover:bg-gray-50 transition-colors">
                  <div className="px-4 py-4 flex items-center justify-between">
                    <div className="flex items-center flex-1 min-w-0">
                      
                      {/* Checkbox */}
                      <div className="flex-shrink-0 mr-4">
                        <input
                          type="checkbox"
                          checked={selectedUsers.includes(user.id)}
                          onChange={() => handleSelectUser(user.id)}
                          disabled={actionLoading}
                          className="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                        />
                      </div>
                      
                      {/* Avatar */}
                      <div className="flex-shrink-0">
                        <div className="h-10 w-10 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-700 font-bold border border-indigo-200">
                          {user.username ? user.username.charAt(0).toUpperCase() : (user.phone_number ? user.phone_number.slice(-1) : '#')}
                        </div>
                      </div>

                      {/* Info */}
                      <div className="ml-4 flex-1 min-w-0">
                        <div className="text-sm font-medium text-gray-900 truncate">
                          {user.phone_number}
                          {user.username && <span className="ml-2 text-gray-500 font-normal">({user.username})</span>}
                        </div>
                        <div className="text-sm text-gray-500 truncate">
                          {user.team_name ? (
                            <span className="flex items-center">
                                <svg className="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path></svg>
                                {user.team_name}
                            </span>
                          ) : 'No team assigned'}
                        </div>
                      </div>
                    </div>

                    {/* Actions */}
                    <div className="flex items-center space-x-4 ml-4">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        user.is_admin ? 'bg-purple-100 text-purple-800' : 'bg-gray-100 text-gray-800'
                      }`}>
                        {user.is_admin ? 'Admin' : 'User'}
                      </span>
                      
                      <button
                        onClick={() => handleToggleAdmin(user.id, user.is_admin)}
                        disabled={actionLoading}
                        className={`text-xs font-medium px-2 py-1 rounded border ${
                            user.is_admin 
                            ? 'border-gray-300 text-gray-700 hover:bg-gray-50' 
                            : 'border-purple-300 text-purple-700 hover:bg-purple-50'
                        }`}
                      >
                        {user.is_admin ? 'Revoke' : 'Promote'}
                      </button>

                      {!user.is_admin && (
                        <button
                          onClick={() => { setSelectedUser(user); setShowDeleteModal(true); }}
                          disabled={actionLoading}
                          className="text-gray-400 hover:text-red-600 transition-colors"
                          title="Delete User"
                        >
                          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
                        </button>
                      )}
                    </div>
                  </div>
                </li>
              ))}
            </ul>

            {/* Pagination Controls */}
            {filteredUsers.length > 0 && (
              <div className="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6">
                 <div className="flex-1 flex justify-between sm:hidden">
                    <button onClick={() => setCurrentPage(Math.max(1, currentPage - 1))} disabled={currentPage === 1} className="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">Previous</button>
                    <button onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))} disabled={currentPage === totalPages} className="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">Next</button>
                 </div>
                 <div className="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
                    <div>
                       <p className="text-sm text-gray-700">
                          Showing <span className="font-medium">{startIndex + 1}</span> to <span className="font-medium">{Math.min(startIndex + itemsPerPage, totalItems)}</span> of <span className="font-medium">{totalItems}</span> users
                       </p>
                    </div>
                    <div>
                       <nav className="relative z-0 inline-flex rounded-md shadow-sm -space-x-px">
                          <button onClick={() => setCurrentPage(Math.max(1, currentPage - 1))} disabled={currentPage === 1} className={`relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium ${currentPage === 1 ? 'text-gray-300' : 'text-gray-500 hover:bg-gray-50'}`}>Previous</button>
                          <button onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))} disabled={currentPage === totalPages} className={`relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium ${currentPage === totalPages ? 'text-gray-300' : 'text-gray-500 hover:bg-gray-50'}`}>Next</button>
                       </nav>
                    </div>
                 </div>
              </div>
            )}
          </>
        )}
      </div>

      {/* Delete Modal */}
      {showDeleteModal && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-75 overflow-y-auto h-full w-full z-50 flex items-center justify-center p-4">
          <div className="relative w-full max-w-md shadow-lg rounded-lg bg-white p-6">
             <div className="flex items-center justify-center w-12 h-12 mx-auto bg-red-100 rounded-full mb-4">
                <svg className="w-6 h-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z"></path></svg>
             </div>
             <h3 className="text-lg font-bold text-gray-900 text-center mb-2">Delete User?</h3>
             <p className="text-sm text-gray-500 text-center mb-6">
                Are you sure you want to delete <strong>{selectedUser?.phone_number}</strong>? This will remove all their data.
             </p>
             <div className="flex justify-end space-x-3">
                <button onClick={() => setShowDeleteModal(false)} className="bg-gray-100 text-gray-700 px-4 py-2 rounded-md text-sm font-medium hover:bg-gray-200">Cancel</button>
                <button onClick={handleDeleteUser} disabled={actionLoading} className="bg-red-600 text-white px-4 py-2 rounded-md text-sm font-medium hover:bg-red-700">
                    {actionLoading ? 'Deleting...' : 'Delete User'}
                </button>
             </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default UserManagement;