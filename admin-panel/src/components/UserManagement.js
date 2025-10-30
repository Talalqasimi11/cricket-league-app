import React, { useState, useEffect } from 'react';
import { adminAPI } from '../services/api';

const UserManagement = ({ onToast }) => {
  const [users, setUsers] = useState([]);
  const [filteredUsers, setFilteredUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedUser, setSelectedUser] = useState(null);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterAdmin, setFilterAdmin] = useState('all');
  const [actionLoading, setActionLoading] = useState(false);

  useEffect(() => {
    fetchUsers();
  }, []);

  useEffect(() => {
    applyFilters();
  }, [users, searchTerm, filterAdmin]);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      setError('');
      const response = await adminAPI.getAllUsers();
      setUsers(response.data);
      onToast?.('Users loaded successfully', 'success');
    } catch (err) {
      const errorMsg = err.response?.data?.error || 'Failed to load users';
      setError(errorMsg);
      onToast?.(errorMsg, 'error');
    } finally {
      setLoading(false);
    }
  };

  const applyFilters = () => {
    let filtered = users;

    // Filter by search term
    if (searchTerm) {
      filtered = filtered.filter(user =>
        user.phone_number.toLowerCase().includes(searchTerm.toLowerCase()) ||
        (user.team_name && user.team_name.toLowerCase().includes(searchTerm.toLowerCase()))
      );
    }

    // Filter by admin status
    if (filterAdmin !== 'all') {
      filtered = filtered.filter(user => user.is_admin === (filterAdmin === 'admin'));
    }

    setFilteredUsers(filtered);
  };

  const handleToggleAdmin = async (userId, currentStatus) => {
    try {
      setActionLoading(true);
      await adminAPI.updateUserAdminStatus(userId, !currentStatus);
      setUsers(users.map(user =>
        user.id === userId
          ? { ...user, is_admin: !currentStatus }
          : user
      ));
      onToast?.(
        !currentStatus ? 'User promoted to admin' : 'Admin privileges removed',
        'success'
      );
    } catch (err) {
      const errorMsg = err.response?.data?.error || 'Failed to update user status';
      onToast?.(errorMsg, 'error');
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
      onToast?.('User deleted successfully', 'success');
    } catch (err) {
      const errorMsg = err.response?.data?.error || 'Failed to delete user';
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
          <p className="text-gray-700">Loading users...</p>
        </div>
      </div>
    );
  }

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">User Management</h1>
        <p className="mt-1 text-sm text-gray-600">
          Manage users and admin privileges (Total: {users.length})
        </p>
      </div>

      {error && (
        <div className="mb-4 bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg flex justify-between items-center">
          <span>{error}</span>
          <button
            onClick={fetchUsers}
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
              Search by phone or team
            </label>
            <input
              type="text"
              placeholder="e.g., +1234567890"
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
              value={filterAdmin}
              onChange={(e) => setFilterAdmin(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
            >
              <option value="all">All Users ({users.length})</option>
              <option value="admin">Admins ({users.filter(u => u.is_admin).length})</option>
              <option value="regular">Regular Users ({users.filter(u => !u.is_admin).length})</option>
            </select>
          </div>
        </div>
      </div>

      {/* Users Table */}
      <div className="bg-white shadow overflow-hidden sm:rounded-md">
        {filteredUsers.length === 0 ? (
          <div className="p-8 text-center">
            <p className="text-gray-500">No users found matching your criteria</p>
          </div>
        ) : (
          <ul className="divide-y divide-gray-200">
            {filteredUsers.map((user) => (
              <li key={user.id}>
                <div className="px-4 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors">
                  <div className="flex items-center flex-1">
                    <div className="flex-shrink-0">
                      <div className="h-10 w-10 rounded-full bg-gradient-to-br from-indigo-500 to-blue-500 flex items-center justify-center text-white font-bold">
                        {user.phone_number.charAt(user.phone_number.length - 1)}
                      </div>
                    </div>
                    <div className="ml-4 flex-1">
                      <div className="text-sm font-medium text-gray-900">
                        {user.phone_number}
                      </div>
                      <div className="text-sm text-gray-500">
                        {user.team_name ? (
                          <>
                            {user.team_name} • {user.team_location}
                          </>
                        ) : (
                          'No team assigned'
                        )}
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center space-x-4 ml-4">
                    <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-medium ${
                      user.is_admin
                        ? 'bg-purple-100 text-purple-800'
                        : 'bg-gray-100 text-gray-800'
                    }`}>
                      {user.is_admin ? '👑 Admin' : 'Regular'}
                    </span>
                    <button
                      onClick={() => handleToggleAdmin(user.id, user.is_admin)}
                      disabled={actionLoading}
                      className={`${
                        user.is_admin
                          ? 'bg-red-100 text-red-700 hover:bg-red-200'
                          : 'bg-green-100 text-green-700 hover:bg-green-200'
                      } px-3 py-1 rounded-md text-sm font-medium transition-colors disabled:opacity-50`}
                    >
                      {user.is_admin ? 'Remove Admin' : 'Make Admin'}
                    </button>
                    {!user.is_admin && (
                      <button
                        onClick={() => {
                          setSelectedUser(user);
                          setShowDeleteModal(true);
                        }}
                        disabled={actionLoading}
                        className="bg-red-100 text-red-700 hover:bg-red-200 px-3 py-1 rounded-md text-sm font-medium transition-colors disabled:opacity-50"
                      >
                        Delete
                      </button>
                    )}
                  </div>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>

      {/* Delete Confirmation Modal */}
      {showDeleteModal && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50 flex items-center justify-center">
          <div className="relative p-5 border w-96 shadow-lg rounded-md bg-white">
            <div className="mt-3">
              <h3 className="text-lg font-bold text-gray-900 mb-4">
                Delete User
              </h3>
              <p className="text-sm text-gray-600 mb-4">
                Are you sure you want to delete user <strong>{selectedUser?.phone_number}</strong>?
              </p>
              <p className="text-sm text-red-600 mb-4 bg-red-50 p-3 rounded">
                ⚠️ This action cannot be undone and will delete their team and all associated data.
              </p>
              <div className="flex justify-end space-x-3">
                <button
                  onClick={() => {
                    setShowDeleteModal(false);
                    setSelectedUser(null);
                  }}
                  disabled={actionLoading}
                  className="bg-gray-300 text-gray-700 px-4 py-2 rounded-md text-sm font-medium hover:bg-gray-400 disabled:opacity-50"
                >
                  Cancel
                </button>
                <button
                  onClick={handleDeleteUser}
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

export default UserManagement;