// lib/features/teams/screens/my_team_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../../../core/cache_service.dart';
import '../../../core/json_utils.dart';
import '../../../core/error_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'team_dashboard_screen.dart';
import '../models/player.dart';

class MyTeamScreen extends StatefulWidget {
  const MyTeamScreen({super.key});

  @override
  State<MyTeamScreen> createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends State<MyTeamScreen> {
  final storage = const FlutterSecureStorage();
  final cacheService = CacheService();

  bool _isLoading = true;
  String _error = '';

  // Simplified state variables
  Map<String, dynamic>? _teamData;
  List<Player> _players = [];
  final List<Map<String, dynamic>> _matches = []; // This remains for future use

  // --- Simplified Getters for Team Data ---
  // These getters are now much simpler, assuming a more consistent API response.
  // The Player model already handles variations in keys like 'id' vs '_id'.

  String get teamName => asType<String>(_teamData?['team_name'], 'Team Name');
  String? get teamLogoUrl =>
      _teamData?['team_logo_url']?.toString() ??
      _teamData?['team_logo']?.toString();
  int get trophies => asType<int>(_teamData?['trophies'], 0);
  int get teamId => asType<int>(_teamData?['id'], 0);
  int get matchesWon => asType<int>(_teamData?['matches_won'], 0);
  String get ownerName => 'Team Owner';
  String get ownerPhone {
    final phone =
        _teamData?['owner_phone']?.toString() ??
        _teamData?['captain_phone']?.toString() ??
        '';
    if (phone.isEmpty) return '';
    // Mask phone number - show last 4 digits only
    if (phone.length <= 4) return phone;
    return '****${phone.substring(phone.length - 4)}';
  }

  String? get ownerImage =>
      _teamData?['owner_image']?.toString() ??
      _teamData?['captain_image']?.toString();

  @override
  void initState() {
    super.initState();
    _loadFromCacheAndFetch();
  }

  /// Load from cache first, then fetch fresh data
  Future<void> _loadFromCacheAndFetch() async {
    // First, try to load from cache for instant display
    await _loadFromCache();

    // Then fetch fresh data in the background
    _fetchTeamData();
  }

  /// Load team data from cache
  Future<void> _loadFromCache() async {
    try {
      // Loading from cache

      final cachedTeamData = await cacheService.getCachedTeamData();
      final cachedPlayersData = await cacheService.getCachedPlayersData();

      if (cachedTeamData != null) {
        if (mounted) {
          setState(() {
            _teamData = cachedTeamData;
          });
        }
      }

      if (cachedPlayersData != null) {
        if (mounted) {
          setState(() {
            _players = cachedPlayersData
                .map((p) => Player.fromJson(p))
                .toList();
          });
        }
      }
    } catch (e) {
      // Cache load failure shouldn't break the app
      debugPrint('Failed to load from cache: $e');
    } finally {
      if (mounted) {
        // Cache loading completed
      }
    }
  }

  /// Fetches team data which includes players.
  Future<void> _fetchTeamData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final token = await storage.read(key: 'jwt_token');
    if (token == null) {
      _logout();
      return;
    }

    try {
      // Fetch team data which includes players
      final teamResponse = await ApiClient.instance.get(
        '/api/teams/my-team',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (teamResponse.statusCode == 200) {
        _teamData = jsonDecode(teamResponse.body) as Map<String, dynamic>;

        // Process players from team response
        if (_teamData!['players'] != null) {
          final playersList = _teamData!['players'] as List;
          _players = playersList.map((p) => Player.fromJson(p)).toList();

          // Cache players data
          final playersData = playersList.cast<Map<String, dynamic>>();
          await cacheService.cachePlayersData(playersData);
        }

        // Cache team data (excluding players as they're cached separately)
        final teamDataToCache = Map<String, dynamic>.from(_teamData!);
        teamDataToCache.remove(
          'players',
        ); // Remove players as they're cached separately
        await cacheService.cacheTeamData(teamDataToCache);
      } else if (teamResponse.statusCode == 401 ||
          teamResponse.statusCode == 403) {
        // Auth error - logout and redirect to login
        _logout();
        return;
      } else if (teamResponse.statusCode == 404) {
        // Team not found - this is acceptable, user might not have a team yet
        _teamData = null;
        _players = [];
      } else if (teamResponse.statusCode >= 500) {
        // Server error - show retry option
        throw 'Server error (${teamResponse.statusCode}). Please try again.';
      } else {
        throw 'Failed to load team: ${teamResponse.statusCode}';
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        ErrorHandler.showErrorSnackBar(context, _error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // removed duplicate simple logout; consolidated into the full logout at bottom

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty && _teamData == null
          ? Center(
              child: Text(
                _error,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchTeamData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Profile Section
                  _buildProfileSection(),
                  const SizedBox(height: 24),

                  // My Teams Section
                  _buildMyTeamSection(),
                  const SizedBox(height: 24),

                  // My Matches Section
                  _buildMyMatchesSection(),
                  const SizedBox(height: 32),

                  // Logout Button
                  _buildLogoutButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileSection() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      children: [
        CircleAvatar(
          radius: 56,
          backgroundColor: cs.surfaceContainerHighest,
          backgroundImage: ownerImage != null
              ? NetworkImage(ownerImage!)
              : null,
          child: ownerImage == null
              ? Icon(Icons.person, color: cs.onSurface, size: 40)
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          ownerName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          ownerPhone,
          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface),
        ),
      ],
    );
  }

  Widget _buildMyTeamSection() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "My Teams",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_teamData != null)
          Card(
            color: cs.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  teamLogoUrl ?? "https://picsum.photos/200",
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 50,
                    height: 50,
                    color: cs.surfaceContainerHighest,
                    child: Icon(Icons.shield, color: cs.onSurface),
                  ),
                ),
              ),
              title: Text(
                teamName,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Matches Won: $matchesWon",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurface),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: cs.onSurface),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeamDashboardScreen(
                      teamName: teamName,
                      teamLogoUrl: teamLogoUrl,
                      trophies: trophies,
                      players: _players,
                      teamId: teamId,
                    ),
                  ),
                );
              },
            ),
          )
        else
          Text(
            "You are not part of a team yet.",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cs.onSurface),
          ),
      ],
    );
  }

  Widget _buildMyMatchesSection() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "My Matches",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_matches.isEmpty)
          Text(
            "No recent matches found.",
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
          )
        else
          ..._matches.map((match) {
            // Your match card logic here
            return Card();
          }),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _logout,
      child: const Text(
        "Logout",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  void _logout() async {
    try {
      await ApiClient.instance.logout();
    } catch (_) {}
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
