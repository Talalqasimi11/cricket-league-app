import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../../player/viewer/player_dashboard_viewer_screen.dart';
import '../../../features/teams/models/player.dart';

class TeamDashboardScreen extends StatefulWidget {
  final int teamId;
  final String? teamName;

  const TeamDashboardScreen({super.key, required this.teamId, this.teamName});

  @override
  State<TeamDashboardScreen> createState() => _TeamDashboardScreenState();
}

class _TeamDashboardScreenState extends State<TeamDashboardScreen> {
  bool _loading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Data State
  String teamName = '';
  String teamLogoUrl = ''; // Renamed for clarity
  String location = '';
  int trophies = 0;
  int matchesPlayed = 0;
  int matchesWon = 0;
  List<Map<String, dynamic>> players = [];

  @override
  void initState() {
    super.initState();
    teamName = widget.teamName ?? 'Loading...';
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  // ✅ Helper to convert relative paths to full URLs
  String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${ApiClient.baseUrl}$path';
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    if (players.isEmpty) setState(() => _loading = true);

    setState(() {
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // 1. Fetch Team Details
      final teamResp = await ApiClient.instance.get(
        '/api/teams/${widget.teamId}',
      );

      if (!mounted) return;

      if (teamResp.statusCode == 200) {
        final dynamic decoded = jsonDecode(teamResp.body);
        if (decoded is Map<String, dynamic>) {
          setState(() {
            teamName = (decoded['team_name'] ?? teamName).toString();
            // ✅ FIX: Convert to full URL here
            teamLogoUrl = _getFullImageUrl(
              decoded['team_logo_url']?.toString(),
            );
            location = (decoded['team_location'] ?? '').toString();
            trophies = _safeInt(decoded['trophies']);
            matchesPlayed = _safeInt(decoded['matches_played']);
            matchesWon = _safeInt(decoded['matches_won']);
          });
        }
      } else if (teamResp.statusCode == 404) {
        _handleError('Team not found.');
        return;
      }

      // 2. Fetch Players
      final pResp = await ApiClient.instance.get(
        '/api/players/team/${widget.teamId}',
      );

      if (mounted && pResp.statusCode == 200) {
        final dynamic decodedPlayers = jsonDecode(pResp.body);
        List<dynamic> rawList = [];

        if (decodedPlayers is List) {
          rawList = decodedPlayers;
        } else if (decodedPlayers is Map<String, dynamic> &&
            decodedPlayers.containsKey('players')) {
          if (decodedPlayers['players'] is List) {
            rawList = decodedPlayers['players'];
          }
        } else if (decodedPlayers is Map<String, dynamic> &&
            decodedPlayers.containsKey('data')) {
          if (decodedPlayers['data'] is List) rawList = decodedPlayers['data'];
        }

        setState(() {
          players = rawList
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
      }
    } on SocketException {
      _handleError('No internet connection.');
    } catch (e) {
      debugPrint("Team Fetch Error: $e");
      _handleError('Failed to load team details.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _safeInt(dynamic val) {
    if (val is int) return val;
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  void _handleError(String message) {
    if (!mounted) return;
    setState(() {
      _hasError = true;
      _errorMessage = message;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: _hasError
          ? _buildErrorState(theme)
          : RefreshIndicator(
              onRefresh: _fetch,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildAppBar(theme),
                  if (_loading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    _buildStatsSection(theme),
                    _buildPlayersList(theme),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        centerTitle: false,
        title: Text(
          teamName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image/Placeholder
            teamLogoUrl.isNotEmpty
                ? Image.network(
                    teamLogoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, _, __) =>
                        Container(color: theme.colorScheme.primary),
                  )
                : Container(
                    color: theme.colorScheme.primary,
                    child: Icon(
                      Icons.shield,
                      size: 80,
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                    ),
                  ),

            // Gradient Overlay for Text Readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (location.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      location,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  _buildStatItem(theme, 'Matches', matchesPlayed.toString()),
                  _buildVerticalDivider(theme),
                  _buildStatItem(theme, 'Won', matchesWon.toString()),
                  _buildVerticalDivider(theme),
                  _buildStatItem(theme, 'Trophies', trophies.toString()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider(ThemeData theme) {
    return Container(
      height: 30,
      width: 1,
      color: theme.colorScheme.outlineVariant,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildStatItem(ThemeData theme, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersList(ThemeData theme) {
    if (players.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 48,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 8),
                Text(
                  "No players found.",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 12),
              child: Text(
                "Squad (${players.length})",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final p = players[index - 1];
          return _buildPlayerTile(theme, p);
        }, childCount: players.length + 1),
      ),
    );
  }

  Widget _buildPlayerTile(ThemeData theme, Map<String, dynamic> p) {
    final pName = (p['player_name'] ?? p['name'] ?? 'Unknown').toString();
    final pRole = (p['player_role'] ?? p['role'] ?? '-').toString();

    // ✅ FIX: Use 'player_image_url' and convert to full URL
    final rawImg = p['player_image_url'] ?? p['image'];
    final avatarUrl = _getFullImageUrl(rawImg?.toString());

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.primaryContainer,
          // ✅ FIX: Properly load image with fallback
          backgroundImage: (avatarUrl.isNotEmpty)
              ? NetworkImage(avatarUrl)
              : null,
          child: (avatarUrl.isEmpty)
              ? Text(
                  pName.isNotEmpty ? pName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(pName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          pRole,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.bar_chart,
            size: 18,
            color: theme.colorScheme.primary,
          ),
        ),
        onTap: () {
          // Convert Map to Player object
          final player = Player.fromJson(p);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerDashboardViewerScreen(player: player),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Oops!', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _fetch,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
