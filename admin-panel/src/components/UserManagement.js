import React, { useState, useEffect } from 'react';
import { adminAPI } from '../services/api';

const UserManagement = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedUser, setSelectedUser] = useState(null);
  const [showDeleteModal, setShowDeleteModal] = useState(false);

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      const response = await adminAPI.getAllUsers();
      setUsers(response.data);
    } catch (err) {
      setError(err.response?.data?.error || 'Failed to load users');
    } finally {
      setLoading(false);
    }
  };

  const handleToggleAdmin = async (userId, currentStatus) => {
    try {
      await adminAPI.updateUserAdminStatus(userId, !currentStatus);
      setUsers(users.map(user => 
        user.id === userId 
          ? { ...user, is_admin: !currentStatus }
          : user
      ));
    } catch (err) {
      setError(err.response?.data?.error || 'Failed to update user status');
    }
  };

  const handleDeleteUser = async () => {
    if (!selectedUser) return;
    
    try {
      await adminAPI.deleteUser(selectedUser.id);
      setUsers(users.filter(user => user.id !== selectedUser.id));
      setShowDeleteModal(false);
      setSelectedUser(null);
    } catch (err) {
      setError(err.response?.data?.error || 'Failed to delete user');
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
        <h1 className="text-2xl font-bold text-gray-900">User Management</h1>
        <p className="mt-1 text-sm text-gray-600">
          Manage users and admin privileges
        </p>
      </div>

      {error && (
        <div className="mb-4 bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <div className="bg-white shadow overflow-hidden sm:rounded-md">
        <ul className="divide-y divide-gray-200">
          {users.map((user) => (
            <li key={user.id}>
              <div className="px-4 py-4 flex items-center justify-between">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <div className="h-10 w-10 rounded-full bg-gray-300 flex items-center justify-center">
                      <span className="text-sm font-medium text-gray-700">
                        {user.phone_number.charAt(0)}
                      </span>
                    </div>
                  </div>
                  <div className="ml-4">
                    <div className="text-sm font-medium text-gray-900">
                      {user.phone_number}
                    </div>
                    <div className="text-sm text-gray-500">
                      {user.team_name ? `${user.team_name} (${user.team_location})` : 'No team'}
                    </div>
                  </div>
                </div>
                <div className="flex items-center space-x-4">
                  <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                    user.is_admin 
                      ? 'bg-purple-100 text-purple-800' 
                      : 'bg-gray-100 text-gray-800'
                  }`}>
                    {user.is_admin ? 'Admin' : 'User'}
                  </span>
                  <button
                    onClick={() => handleToggleAdmin(user.id, user.is_admin)}
                    className={`${
                      user.is_admin 
                        ? 'bg-red-100 text-red-700 hover:bg-red-200' 
                        : 'bg-green-100 text-green-700 hover:bg-green-200'
                    } px-3 py-1 rounded-md text-sm font-medium`}
                  >
                    {user.is_admin ? 'Remove Admin' : 'Make Admin'}
                  </button>
                  {!user.is_admin && (
                    <button
                      onClick={() => {
                        setSelectedUser(user);
                        setShowDeleteModal(true);
                      }}
                      className="bg-red-100 text-red-700 hover:bg-red-200 px-3 py-1 rounded-md text-sm font-medium"
                    >
                      Delete
                    </button>
                  )}
                </div>
              </div>
            </li>
          ))}
        </ul>
      </div>

      {/* Delete Confirmation Modal */}
      {showDeleteModal && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
          <div className="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
            <div className="mt-3">
              <h3 className="text-lg font-medium text-gray-900 mb-4">
                Delete User
              </h3>
              <p className="text-sm text-gray-500 mb-4">
                Are you sure you want to delete user {selectedUser?.phone_number}? 
                This action cannot be undone and will also delete their team and all associated data.
              </p>
              <div className="flex justify-end space-x-3">
                <button
                  onClick={() => {
                    setShowDeleteModal(false);
                    setSelectedUser(null);
                  }}
                  className="bg-gray-300 text-gray-700 px-4 py-2 rounded-md text-sm font-medium hover:bg-gray-400"
                >
                  Cancel
                </button>
                <button
                  onClick={handleDeleteUser}
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

export default UserManagement;
