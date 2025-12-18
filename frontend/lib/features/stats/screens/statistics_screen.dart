import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/api_client.dart';
import '../../../services/api_service.dart';
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

  // Typed for safer access
  Map<String, dynamic> _overviewStats = {};
  List<Map<String, dynamic>> _playerStats = [];
  List<Map<String, dynamic>> _teamStats = [];

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
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        ApiClient.instance.get('/api/stats/overview'),
        ApiClient.instance.get('/api/stats/players'),
        ApiClient.instance.get('/api/stats/teams'),
      ]);

      Map<String, dynamic> newOverview = _overviewStats;
      List<Map<String, dynamic>> newPlayers = _playerStats;
      List<Map<String, dynamic>> newTeams = _teamStats;

      if (results[0].statusCode == 200) {
        final data = jsonDecode(results[0].body) as Map<String, dynamic>;
        newOverview = data;
      }
      if (results[1].statusCode == 200) {
        final data = jsonDecode(results[1].body) as Map<String, dynamic>;
        final players = (data['players'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        newPlayers = players ?? [];
      }
      if (results[2].statusCode == 200) {
        final data = jsonDecode(results[2].body) as Map<String, dynamic>;
        final teams = (data['teams'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        newTeams = teams ?? [];
      }

      if (!mounted) return;
      setState(() {
        _overviewStats = newOverview;
        _playerStats = newPlayers;
        _teamStats = newTeams;
      });

      final failed = results.where((r) => r.statusCode != 200);
      if (failed.isNotEmpty && mounted) {
        await ErrorDialog.showApiError(
          context,
          response: failed.first,
          onRetry: _fetchAllStatistics,
        );
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

  // Helper: initials
  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    return name.trim().characters.first.toUpperCase();
  }

  // Helper: number parsing
  num _toNumber(dynamic value, {num defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // Helper: decimal formatting
  String _formatDecimal(
    dynamic value,
    int decimals, {
    String defaultValue = '0.0',
  }) {
    try {
      final number = _toNumber(value);
      return number.toStringAsFixed(decimals);
    } catch (_) {
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
              icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
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
            unselectedLabelColor: theme.colorScheme.onSurface.withValues(
              alpha: 0.6,
            ),
            indicatorColor: theme.colorScheme.primary,
          ),
        ),
        body: _loading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Loading statistics...',
                      style: AppTypographyExtended.bodyMedium.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
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
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Top Stats Row 1
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
          // Top Stats Row 2
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

          // Top Players Section (Preview)
          if (_playerStats.isNotEmpty) ...[
            const Text(
              'Top Performers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._playerStats.take(3).map((player) {
              final rank = _playerStats.indexOf(player) + 1;
              return _buildPlayerListItem(player, rank);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayersTab() {
    return RefreshIndicator(
      onRefresh: _fetchStatistics,
      child: _playerStats.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 160),
                Center(child: Text('No player statistics available')),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _playerStats.length,
              itemBuilder: (context, index) {
                return _buildPlayerListItem(_playerStats[index], index + 1);
              },
            ),
    );
  }

  // ✅ Detailed Player Card with Real Image & Full Stats
  Widget _buildPlayerListItem(Map<String, dynamic> player, int index) {
    final playerName = player['player_name']?.toString() ?? 'Unknown Player';
    final teamName = player['team_name']?.toString() ?? 'Unknown Team';
    final playerRole = player['player_role']?.toString() ?? 'Role';

    // ✅ FIX: Load image from backend url using shared ApiService helper
    final imageUrl = ApiService().getImageUrl(
      player['player_image_url']?.toString(),
    );

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: Avatar, Name, Rank
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.shade100,
                  ),
                  child: ClipOval(
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Text(
                                _getInitials(playerName),
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              _getInitials(playerName),
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '#$index',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. ✅ Detailed Stats Grid (Matches, Runs, Avg, SR, 100s, 50s, Wickets)
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              children: [
                _buildMiniStat(
                  'Matches',
                  _toNumber(player['matches_played']).toString(),
                ),
                _buildMiniStat(
                  'Runs',
                  _toNumber(player['total_runs']).toString(),
                ),
                _buildMiniStat(
                  'Avg',
                  _formatDecimal(player['batting_average'], 1),
                ),
                _buildMiniStat('SR', _formatDecimal(player['strike_rate'], 1)),
                _buildMiniStat(
                  '100s',
                  _toNumber(player['hundreds']).toString(),
                ),
                _buildMiniStat('50s', _toNumber(player['fifties']).toString()),
                _buildMiniStat(
                  'Wickets',
                  _toNumber(
                    player['wickets_taken'] ?? player['wickets'],
                  ).toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper for the small stats grid inside player card
  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildTeamsTab() {
    return RefreshIndicator(
      onRefresh: _fetchStatistics,
      child: _teamStats.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 160),
                Center(child: Text('No team statistics available')),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _teamStats.length,
              itemBuilder: (context, index) {
                final team = _teamStats[index];
                final teamName =
                    team['team_name']?.toString() ?? 'Unknown Team';
                final totalPlayers = _toNumber(team['total_players']);

                // ✅ FIX: Load Real Team Logo from backend
                final logoUrl = ApiService().getImageUrl(
                  team['team_logo_url']?.toString() ??
                      team['team_logo']?.toString(),
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.shade50,
                              ),
                              child: ClipOval(
                                child: logoUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: logoUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const Center(
                                              child: SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(
                                              Icons.shield,
                                              color: Colors.blue,
                                            ),
                                      )
                                    : const Icon(
                                        Icons.shield,
                                        color: Colors.blue,
                                      ),
                              ),
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
              },
            ),
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
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
            style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
