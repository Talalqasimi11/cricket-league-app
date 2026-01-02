import React, { useState, useEffect, useCallback } from 'react';
import axios from 'axios';
import Icon from '../components/Icon'; // Using the existing Icon wrapper

const ActivityMonitor = () => {
    const [logs, setLogs] = useState([]);
    const [stats, setStats] = useState({ today_opens: 0, active_devices_24h: 0, active_users_24h: 0 });
    const [loading, setLoading] = useState(true);
    const [page, setPage] = useState(1);
    const [totalPages, setTotalPages] = useState(1);
    const [refreshing, setRefreshing] = useState(false);

    const fetchData = useCallback(async () => {
        setRefreshing(true);
        // Don't show full loading spinner on background refresh
        if (logs.length === 0) setLoading(true);

        try {
            const token = localStorage.getItem('admin_token'); // Fixed token key
            const config = { headers: { Authorization: `Bearer ${token}` } };

            const logsRes = await axios.get(`http://localhost:5000/api/activity/logs?page=${page}&limit=20`, config);
            const statsRes = await axios.get(`http://localhost:5000/api/activity/stats`, config);

            setLogs(logsRes.data.logs);
            setTotalPages(logsRes.data.pagination.total_pages || 1);
            setStats(statsRes.data);
        } catch (error) {
            console.error('Error fetching activity data:', error);
        } finally {
            setLoading(false);
            setRefreshing(false);
        }
    }, [page, logs.length]); // Added logs.length to dependency to ensure partial updates don't break logic, though mainly page matter

    useEffect(() => {
        fetchData();
        const interval = setInterval(fetchData, 30000); // Auto-refresh 30s
        return () => clearInterval(interval);
    }, [fetchData]);

    const handlePageChange = (newPage) => {
        if (newPage >= 1 && newPage <= totalPages) {
            setPage(newPage);
        }
    };

    const getDeviceIconName = (log) => {
        // Heuristic based on metadata or user agent
        const platform = log.metadata?.platform?.toLowerCase() || '';
        if (platform.includes('android') || platform.includes('ios')) {
            return 'smartphone';
        }
        return 'monitor';
    };

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <h1 className="text-2xl font-bold text-gray-900">User Activity Monitor</h1>
                <button
                    onClick={fetchData}
                    className="p-2 text-gray-600 hover:text-indigo-600 hover:bg-gray-100 rounded-full transition-colors"
                    title="Refresh"
                >
                    <Icon name="refreshCw" className={refreshing ? 'animate-spin' : ''} size={20} />
                </button>
            </div>

            {/* Stats Cards */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="bg-white rounded-lg shadow p-6 border-l-4 border-blue-500">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-sm font-medium text-gray-500">App Opens Today</p>
                            <p className="text-3xl font-bold text-gray-900 mt-1">{stats.today_opens}</p>
                        </div>
                        <div className="p-3 bg-blue-50 rounded-full text-blue-600">
                            <Icon name="activity" size={24} />
                        </div>
                    </div>
                </div>

                <div className="bg-white rounded-lg shadow p-6 border-l-4 border-green-500">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-sm font-medium text-gray-500">Active Devices (24h)</p>
                            <p className="text-3xl font-bold text-gray-900 mt-1">{stats.active_devices_24h}</p>
                        </div>
                        <div className="p-3 bg-green-50 rounded-full text-green-600">
                            <Icon name="smartphone" size={24} />
                        </div>
                    </div>
                </div>

                <div className="bg-white rounded-lg shadow p-6 border-l-4 border-orange-500">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-sm font-medium text-gray-500">Active Users (24h)</p>
                            <p className="text-3xl font-bold text-gray-900 mt-1">{stats.active_users_24h}</p>
                        </div>
                        <div className="p-3 bg-orange-50 rounded-full text-orange-600">
                            <Icon name="users" size={24} />
                        </div>
                    </div>
                </div>
            </div>

            {/* Logs Table */}
            <div className="bg-white shadow rounded-lg overflow-hidden">
                <div className="px-6 py-4 border-b border-gray-200">
                    <h3 className="text-lg font-medium text-gray-900">Activity Feed</h3>
                </div>

                {loading && logs.length === 0 ? (
                    <div className="flex justify-center items-center h-64">
                        <Icon name="loader" className="animate-spin text-indigo-600" size={32} />
                    </div>
                ) : (
                    <div className="overflow-x-auto">
                        <table className="min-w-full divide-y divide-gray-200">
                            <thead className="bg-gray-50">
                                <tr>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Time</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Device</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Activity</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Details</th>
                                </tr>
                            </thead>
                            <tbody className="bg-white divide-y divide-gray-200">
                                {logs.map((log) => (
                                    <tr key={log.id} className="hover:bg-gray-50">
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                            {new Date(log.created_at).toLocaleString()}
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <div className="flex items-center text-sm text-gray-900">
                                                <Icon name={getDeviceIconName(log)} size={16} className="mr-2 text-gray-400" />
                                                <span className="font-mono text-xs">{log.device_id?.substring(0, 8)}...</span>
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            {log.username ? (
                                                <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-indigo-100 text-indigo-800">
                                                    {log.username}
                                                </span>
                                            ) : (
                                                <span className="text-sm text-gray-500 italic">Guest</span>
                                            )}
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${log.activity_type === 'APP_OPEN'
                                                    ? 'bg-green-100 text-green-800'
                                                    : 'bg-gray-100 text-gray-800'
                                                }`}>
                                                {log.activity_type}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                            {log.metadata?.device_model || log.metadata?.platform || '-'}
                                        </td>
                                    </tr>
                                ))}
                                {logs.length === 0 && (
                                    <tr>
                                        <td colSpan="5" className="px-6 py-12 text-center text-gray-500">
                                            No activity logs found.
                                        </td>
                                    </tr>
                                )}
                            </tbody>
                        </table>
                    </div>
                )}

                {/* Pagination */}
                <div className="bg-gray-50 px-4 py-3 border-t border-gray-200 flex items-center justify-between sm:px-6">
                    <div className="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
                        <div>
                            <p className="text-sm text-gray-700">
                                Page <span className="font-medium">{page}</span> of <span className="font-medium">{totalPages}</span>
                            </p>
                        </div>
                        <div>
                            <nav className="relative z-0 inline-flex rounded-md shadow-sm -space-x-px" aria-label="Pagination">
                                <button
                                    onClick={() => handlePageChange(page - 1)}
                                    disabled={page === 1}
                                    className={`relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium ${page === 1 ? 'text-gray-300' : 'text-gray-500 hover:bg-gray-50'
                                        }`}
                                >
                                    <span className="sr-only">Previous</span>
                                    <Icon name="chevronLeft" size={16} />
                                </button>
                                <button
                                    onClick={() => handlePageChange(page + 1)}
                                    disabled={page === totalPages}
                                    className={`relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium ${page === totalPages ? 'text-gray-300' : 'text-gray-500 hover:bg-gray-50'
                                        }`}
                                >
                                    <span className="sr-only">Next</span>
                                    <Icon name="chevronRight" size={16} />
                                </button>
                            </nav>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default ActivityMonitor;
