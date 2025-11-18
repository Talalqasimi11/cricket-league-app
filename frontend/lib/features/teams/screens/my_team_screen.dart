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
  bool _isAuthenticated = false;
  bool _isDisposed = false;

  Map<String, dynamic>? _teamData;
  List<Player> _players = [];
  final List<Map<String, dynamic>> _matches = [];

  // Safe helpers
  String _safeString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    final str = value.toString().trim();
    return str.isNotEmpty ? str : defaultValue;
  }

  int _safeInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    if (value is num) return value.toInt();
    return defaultValue;
  }

  dynamic _safeJsonDecode(String body) {
    try {
      if (body.isEmpty) {
        throw const FormatException('Empty response body');
      }
      return jsonDecode(body);
    } on FormatException catch (e) {
      debugPrint('JSON decode error: $e');
      debugPrint('Response body: $body');
      throw FormatException('Invalid JSON response: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected decode error: $e');
      rethrow;
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  // Simplified Getters for Team Data
  String get teamName => _safeString(_teamData?['team_name'], 'Team Name');
  
  String? get teamLogoUrl {
    final logo = _teamData?['team_logo_url']?.toString() ??
        _teamData?['team_logo']?.toString();
    return logo?.isNotEmpty == true ? logo : null;
  }
  
  int get trophies => _safeInt(_teamData?['trophies'], 0);
  int get teamId => _safeInt(_teamData?['id'], 0);
  int get matchesWon => _safeInt(_teamData?['matches_won'], 0);
  String get ownerName => _safeString(_teamData?['owner_name'], 'Team Owner');
  
  String get ownerPhone {
    final phone = _safeString(
      _teamData?['owner_phone'] ?? _teamData?['captain_phone'],
      '',
    );
    
    if (phone.isEmpty) return '';
    
    // Mask phone number - show last 4 digits only
    if (phone.length <= 4) return phone;
    return '****${phone.substring(phone.length - 4)}';
  }

  String? get ownerImage {
    final image = _teamData?['owner_image']?.toString() ??
        _teamData?['captain_image']?.toString();
    return image?.isNotEmpty == true ? image : null;
  }

  @override
  void initState() {
    super.initState();
    _loadFromCacheAndFetch();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Load from cache first, then fetch fresh data
  Future<void> _loadFromCacheAndFetch() async {
    await _loadFromCache();
    if (!_isDisposed) {
      await _fetchTeamData();
    }
  }

  /// Load team data from cache
  Future<void> _loadFromCache() async {
    try {
      final cachedTeamData = await cacheService.getCachedTeamData();
      final cachedPlayersData = await cacheService.getCachedPlayersData();

      if (!_isDisposed && cachedTeamData != null) {
        _safeSetState(() {
          _teamData = cachedTeamData;
        });
      }

      if (!_isDisposed && cachedPlayersData != null) {
        final players = <Player>[];
        
        // Parse players with error handling for each
        for (final playerData in cachedPlayersData) {
          try {
            if (playerData is Map<String, dynamic>) {
              players.add(Player.fromJson(playerData));
            }
          } catch (e) {
            debugPrint('Error parsing cached player: $e');
          }
        }

        if (players.isNotEmpty) {
          _safeSetState(() {
            _players = players;
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load from cache: $e');
      // Cache load failure shouldn't break the app
    }
  }

  /// Fetches team data which includes players
  Future<void> _fetchTeamData() async {
    if (_isDisposed) return;

    _safeSetState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final token = await storage.read(key: 'jwt_token');
      
      if (token == null || token.isEmpty) {
        if (!_isDisposed) {
          _safeSetState(() {
            _isAuthenticated = false;
            _isLoading = false;
            _teamData = null;
            _players = [];
          });
        }
        return;
      }

      _isAuthenticated = true;

      final teamResponse = await ApiClient.instance.get(
        '/api/teams/my-team',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (_isDisposed) return;

      if (teamResponse.statusCode == 200) {
        await _handleSuccessResponse(teamResponse);
      } else if (teamResponse.statusCode == 401 ||
          teamResponse.statusCode == 403) {
        await _handleAuthError();
      } else if (teamResponse.statusCode == 404) {
        await _handleNotFoundResponse();
      } else if (teamResponse.statusCode >= 500) {
        throw Exception('Server error (${teamResponse.statusCode}). Please try again.');
      } else {
        throw Exception('Failed to load team: ${teamResponse.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching team data: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (!_isDisposed && mounted) {
        _safeSetState(() => _error = e.toString());
        ErrorHandler.showErrorSnackBar(context, _error);
      }
    } finally {
      if (!_isDisposed) {
        _safeSetState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSuccessResponse(dynamic teamResponse) async {
    try {
      final decoded = _safeJsonDecode(teamResponse.body);
      
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid response format');
      }

      if (_isDisposed) return;

      _safeSetState(() {
        _teamData = decoded;
      });

      // Process players from team response
      await _processPlayers(decoded);

      // Cache team data
      await _cacheTeamData(decoded);
    } catch (e) {
      debugPrint('Error handling success response: $e');
      rethrow;
    }
  }

  Future<void> _processPlayers(Map<String, dynamic> teamData) async {
    try {
      final playersData = teamData['players'];
      
      if (playersData == null) {
        _safeSetState(() => _players = []);
        return;
      }

      if (playersData is! List) {
        debugPrint('Expected List for players but got: ${playersData.runtimeType}');
        _safeSetState(() => _players = []);
        return;
      }

      final players = <Player>[];
      final playerJsonList = <Map<String, dynamic>>[];

      for (final playerData in playersData) {
        try {
          if (playerData is Map<String, dynamic>) {
            final player = Player.fromJson(playerData);
            players.add(player);
            playerJsonList.add(playerData);
          } else {
            debugPrint('Invalid player data type: ${playerData.runtimeType}');
          }
        } catch (e) {
          debugPrint('Error parsing player: $e');
        }
      }

      if (_isDisposed) return;

      _safeSetState(() {
        _players = players;
      });

      // Cache players data
      if (playerJsonList.isNotEmpty) {
        try {
          await cacheService.cachePlayersData(playerJsonList);
        } catch (e) {
          debugPrint('Error caching players: $e');
        }
      }
    } catch (e) {
      debugPrint('Error processing players: $e');
      _safeSetState(() => _players = []);
    }
  }

  Future<void> _cacheTeamData(Map<String, dynamic> teamData) async {
    try {
      final teamDataToCache = Map<String, dynamic>.from(teamData);
      teamDataToCache.remove('players');
      await cacheService.cacheTeamData(teamDataToCache);
    } catch (e) {
      debugPrint('Error caching team data: $e');
    }
  }

  Future<void> _handleAuthError() async {
    debugPrint('Authentication error, logging out...');
    await _logout();
  }

  Future<void> _handleNotFoundResponse() async {
    debugPrint('Team not found (404) - user might not have a team yet');
    
    if (!_isDisposed) {
      _safeSetState(() {
        _teamData = null;
        _players = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty && _teamData == null) {
      return _buildErrorState(theme);
    }

    if (_teamData == null && !_isAuthenticated) {
      return _buildLoginPrompt();
    }

    return RefreshIndicator(
      onRefresh: _fetchTeamData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileSection(),
          const SizedBox(height: 24),
          _buildMyTeamSection(),
          const SizedBox(height: 24),
          _buildMyMatchesSection(),
          const SizedBox(height: 32),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Team',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchTeamData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
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
        _buildProfileAvatar(cs),
        const SizedBox(height: 12),
        Text(
          ownerName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (ownerPhone.isNotEmpty)
          Text(
            ownerPhone,
            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface),
          ),
      ],
    );
  }

  Widget _buildProfileAvatar(ColorScheme cs) {
    if (ownerImage != null) {
      return CircleAvatar(
        radius: 56,
        backgroundColor: cs.surfaceContainerHighest,
        child: ClipOval(
          child: Image.network(
            ownerImage!,
            width: 112,
            height: 112,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading profile image: $error');
              return Icon(Icons.person, color: cs.onSurface, size: 40);
            },
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 56,
      backgroundColor: cs.surfaceContainerHighest,
      child: Icon(Icons.person, color: cs.onSurface, size: 40),
    );
  }

  Widget _buildMyTeamSection() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "My Team",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _teamData != null
            ? _buildTeamCard(theme, cs)
            : _buildCreateTeamCard(theme, cs),
      ],
    );
  }

  Widget _buildTeamCard(ThemeData theme, ColorScheme cs) {
    return Card(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: _buildTeamLogo(cs),
        title: Text(
          teamName,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          "Matches Won: $matchesWon",
          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: cs.onSurface),
        onTap: () => _navigateToTeamDashboard(),
      ),
    );
  }

  Widget _buildTeamLogo(ColorScheme cs) {
    if (teamLogoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          teamLogoUrl!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 50,
              height: 50,
              color: cs.surfaceContainerHighest,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading team logo: $error');
            return Container(
              width: 50,
              height: 50,
              color: cs.surfaceContainerHighest,
              child: Icon(Icons.shield, color: cs.onSurface),
            );
          },
        ),
      );
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.shield, color: cs.onSurface),
    );
  }

  void _navigateToTeamDashboard() {
    if (!mounted || _isDisposed) return;

    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeamDashboardScreen(
            teamName: teamName,
            teamLogoUrl: teamLogoUrl,
            trophies: trophies,
            players: List.from(_players), // Create defensive copy
            teamId: teamId,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to team dashboard: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open team dashboard')),
        );
      }
    }
  }

  Widget _buildCreateTeamCard(ThemeData theme, ColorScheme cs) {
    return Card(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.add,
            color: cs.onPrimaryContainer,
            size: 28,
          ),
        ),
        title: Text(
          "Create Your Team",
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
        ),
        subtitle: Text(
          "Join tournaments and manage players",
          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: cs.primary,
        ),
        onTap: () => _navigateToCreateTeam(),
      ),
    );
  }

  Future<void> _navigateToCreateTeam() async {
    if (!mounted || _isDisposed) return;

    try {
      final result = await Navigator.pushNamed(context, '/my-team/create');
      
      if (result == true && !_isDisposed && mounted) {
        await _fetchTeamData();
      }
    } catch (e) {
      debugPrint('Error navigating to create team: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open create team screen')),
        );
      }
    }
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
          ..._matches.map((match) => const Card()),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: _logout,
      child: const Text(
        "Logout",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Login Required',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'You need to be logged in to view and manage your team information.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToLogin(),
              icon: const Icon(Icons.login),
              label: const Text('Login'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToLogin() async {
    if (!mounted || _isDisposed) return;

    try {
      await Navigator.pushNamed(context, '/login');
      
      if (!_isDisposed && mounted) {
        await _fetchTeamData();
      }
    } catch (e) {
      debugPrint('Error navigating to login: $e');
    }
  }

  Future<void> _logout() async {
    if (_isDisposed || !mounted) return;

    try {
      await ApiClient.instance.logout();
    } catch (e) {
      debugPrint('Error during logout: $e');
    }

    if (!_isDisposed && mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}