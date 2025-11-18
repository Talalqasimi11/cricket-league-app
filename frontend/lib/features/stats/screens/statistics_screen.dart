import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/api_client.dart';
import '../../../core/error_dialog.dart';
import '../../../core/theme/theme_config.dart';
import '../../../widgets/error_boundary.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  Map<String, dynamic> _overviewStats = {};
  List<dynamic> _playerStats = [];
  List<dynamic> _teamStats = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAllStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllStatistics() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiClient.instance.get('/api/stats/overview'),
        ApiClient.instance.get('/api/stats/players'),
        ApiClient.instance.get('/api/stats/teams'),
      ]);

      if (results[0].statusCode == 200) {
        final data = jsonDecode(results[0].body) as Map<String, dynamic>;
        setState(() => _overviewStats = data);
      }

      if (results[1].statusCode == 200) {
        final data = jsonDecode(results[1].body) as Map<String, dynamic>;
        setState(() => _playerStats = data['players'] ?? []);
      }

      if (results[2].statusCode == 200) {
        final data = jsonDecode(results[2].body) as Map<String, dynamic>;
        setState(() => _teamStats = data['teams'] ?? []);
      }

      final failedRequests = results.where((r) => r.statusCode != 200);
      if (failedRequests.isNotEmpty) {
        if (mounted) {
          await ErrorDialog.showApiError(
            context,
            response: failedRequests.first,
            onRetry: _fetchAllStatistics,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        await ErrorDialog.showGenericError(
          context,
          error: e,
          onRetry: _fetchAllStatistics,
          showRetryButton: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchStatistics() async {
    await _fetchAllStatistics();
  }

  // Helper function to safely get initials
  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    return name.trim().substring(0, 1).toUpperCase();
  }

  // Helper function to safely convert to number
  num _toNumber(dynamic value, {num defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // Helper function to safely format decimal
  String _formatDecimal(dynamic value, int decimals, {String defaultValue = '0.0'}) {
    try {
      final number = _toNumber(value);
      return number.toStringAsFixed(decimals);
    } catch (e) {
      return defaultValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ScreenErrorBoundary(
      onRetry: _fetchStatistics,
      title: "Statistics",
      message: "An error occurred while loading statistics",
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          title: Text(
            "Statistics",
            style: AppTypographyExtended.headlineSmall.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _fetchStatistics,
              icon: Icon(
                Icons.refresh,
                color: theme.colorScheme.onSurface,
              ),
              tooltip: 'Refresh Statistics',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Players'),
              Tab(text: 'Teams'),
            ],
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            indicatorColor: theme.colorScheme.primary,
          ),
        ),
        body: _loading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading statistics...',
                      style: AppTypographyExtended.bodyMedium.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              )
            : _overviewStats.isEmpty && _playerStats.isEmpty && _teamStats.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.query_stats,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No statistics available',
                          style: AppTypographyExtended.headlineSmall.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Statistics will appear once matches are played',
                          style: AppTypographyExtended.bodyMedium.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _fetchStatistics,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildPlayersTab(),
                      _buildTeamsTab(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final overview = _overviewStats['overview'] as Map<String, dynamic>? ?? {};

    return RefreshIndicator(
      onRefresh: _fetchStatistics,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Matches',
                  _toNumber(overview['total_matches']).toString(),
                  Icons.sports_cricket,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Active Tournaments',
                  _toNumber(overview['active_tournaments']).toString(),
                  Icons.emoji_events,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Registered Teams',
                  _toNumber(overview['total_teams']).toString(),
                  Icons.group,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Players',
                  _toNumber(overview['total_players']).toString(),
                  Icons.person,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_playerStats.isNotEmpty) ...[
            const Text(
              'Top Players',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._playerStats.take(3).map((player) {
              final playerMap = player as Map<String, dynamic>? ?? {};
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      _getInitials(playerMap['player_name'] as String?),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(
                    playerMap['player_name']?.toString() ?? 'Unknown Player',
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    'Runs: ${_toNumber(playerMap['total_runs'])}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    '#${_playerStats.indexOf(player) + 1}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],

          const Text(
            'Platform Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: const Text(
              'Match results and tournament updates will appear here once matches are completed.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersTab() {
    return RefreshIndicator(
      onRefresh: _fetchStatistics,
      child: _playerStats.isEmpty
          ? const Center(
              child: Text('No player statistics available'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _playerStats.length,
              itemBuilder: (context, index) {
                try {
                  final player = _playerStats[index] as Map<String, dynamic>? ?? {};
                  final playerName = player['player_name']?.toString() ?? 'Unknown Player';
                  final teamName = player['team_name']?.toString() ?? 'Unknown Team';
                  final playerRole = player['player_role']?.toString() ?? 'Unknown Role';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                child: Text(
                                  _getInitials(playerName),
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      playerName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '$teamName • $playerRole',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '#${index + 1}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPlayerStat(
                                'Runs',
                                _toNumber(player['total_runs']).toString(),
                              ),
                              _buildPlayerStat(
                                'Avg',
                                _formatDecimal(player['batting_average'], 1),
                              ),
                              _buildPlayerStat(
                                'SR',
                                _formatDecimal(player['strike_rate'], 1),
                              ),
                              _buildPlayerStat(
                                'Wickets',
                                _toNumber(player['wickets_taken']).toString(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                } catch (e) {
                  // Handle individual item errors gracefully
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error loading player #${index + 1}',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  );
                }
              },
            ),
    );
  }

  Widget _buildTeamsTab() {
    return RefreshIndicator(
      onRefresh: _fetchStatistics,
      child: _teamStats.isEmpty
          ? const Center(
              child: Text('No team statistics available'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _teamStats.length,
              itemBuilder: (context, index) {
                try {
                  final team = _teamStats[index] as Map<String, dynamic>? ?? {};
                  final teamName = team['team_name']?.toString() ?? 'Unknown Team';
                  final totalPlayers = _toNumber(team['total_players']);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: const Icon(Icons.shield, color: Colors.blue),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      teamName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '$totalPlayers players',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '#${index + 1}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildTeamStat(
                                'Matches',
                                _toNumber(team['matches_played']).toString(),
                              ),
                              _buildTeamStat(
                                'Won',
                                _toNumber(team['matches_won']).toString(),
                              ),
                              _buildTeamStat(
                                'Win %',
                                '${_formatDecimal(team['win_percentage'], 1)}%',
                              ),
                              _buildTeamStat(
                                'Trophies',
                                _toNumber(team['trophies']).toString(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                } catch (e) {
                  // Handle individual item errors gracefully
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error loading team #${index + 1}',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  );
                }
              },
            ),
    );
  }

  Widget _buildPlayerStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}