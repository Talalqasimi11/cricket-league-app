import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/api_client.dart';
import '../../../core/cache_service.dart';
import '../../../core/error_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/player.dart';
import 'player_dashboard_screen.dart';
import '../../../widgets/image_upload_widget.dart';

class TeamDashboardScreen extends StatefulWidget {
  final int? teamId;
  final String? teamName;
  final String? teamLogoUrl;
  final int? trophies;
  final List<Player>? players;

  const TeamDashboardScreen({
    super.key,
    this.teamId,
    this.teamName,
    this.teamLogoUrl,
    this.trophies,
    this.players,
  });

  @override
  State<TeamDashboardScreen> createState() => _TeamDashboardScreenState();
}

class _TeamDashboardScreenState extends State<TeamDashboardScreen> {
  final storage = const FlutterSecureStorage();
  final cacheService = CacheService();

  bool _isLoading = true;
  bool _isOffline = false;
  bool _isLoadingFromCache = false;
  bool _isDisposed = false;
  int _retryCount = 0;
  
  static const int _maxRetries = 3;
  static const Duration _baseDelay = Duration(seconds: 1);
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  String teamName = '';
  String teamLogoUrl = '';
  String teamLocation = '';
  int trophies = 0;
  List<Player> players = [];
  String? captainPlayerId;
  String? viceCaptainPlayerId;

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

  String _getErrorMessage(dynamic error) {
    if (error == null) return 'Unknown error';
    final message = error.toString();
    return message.replaceAll('Exception:', '').trim();
  }

  @override
  void initState() {
    super.initState();
    teamName = _safeString(widget.teamName, 'Team');
    teamLogoUrl = _safeString(widget.teamLogoUrl, '');
    trophies = widget.trophies ?? 0;
    players = widget.players != null ? List.from(widget.players!) : [];

    _initializeConnectivity();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeConnectivity() async {
    try {
      final initialResults = await Connectivity().checkConnectivity();
      final isInitiallyConnected = 
          initialResults.contains(ConnectivityResult.mobile) ||
          initialResults.contains(ConnectivityResult.wifi) ||
          initialResults.contains(ConnectivityResult.ethernet);

      if (!_isDisposed) {
        _safeSetState(() {
          _isOffline = !isInitiallyConnected;
        });
      }

      _startConnectivityMonitoring();
      await _loadFromCacheAndFetch();
    } catch (e) {
      debugPrint('Error initializing connectivity: $e');
    }
  }

  void _startConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        if (_isDisposed) return;

        final isConnected =
            results.contains(ConnectivityResult.mobile) ||
            results.contains(ConnectivityResult.wifi) ||
            results.contains(ConnectivityResult.ethernet);

        final wasOffline = _isOffline;

        _safeSetState(() {
          _isOffline = !isConnected;
        });

        if (!wasOffline && isConnected && _isOffline) {
          _retryCount = 0;
          _fetchTeamDetails();
        }
      },
      onError: (error) {
        debugPrint('Connectivity subscription error: $error');
      },
    );
  }

  Future<void> _loadFromCacheAndFetch() async {
    if (_isDisposed) return;
    
    await _loadFromCache();

    if (!_isDisposed) {
      await _fetchTeamDetails();
    }
  }

  Future<void> _loadFromCache() async {
    if (_isDisposed) return;

    _safeSetState(() => _isLoadingFromCache = true);

    try {
      final cachedTeamData = await cacheService.getCachedTeamData();
      final cachedPlayersData = await cacheService.getCachedPlayersData();

      if (_isDisposed) return;

      if (cachedTeamData != null) {
        _safeSetState(() {
          teamName = _safeString(cachedTeamData['team_name'], teamName);
          teamLogoUrl = _safeString(cachedTeamData['team_logo_url'], teamLogoUrl);
          teamLocation = _safeString(cachedTeamData['team_location'], teamLocation);
          trophies = _safeInt(cachedTeamData['trophies'], trophies);
          captainPlayerId = cachedTeamData['captain_player_id']?.toString();
          viceCaptainPlayerId = cachedTeamData['vice_captain_player_id']?.toString();
        });
      }

      if (cachedPlayersData != null) {
        final cachedPlayers = <Player>[];
        
        for (final playerData in cachedPlayersData) {
          try {
            if (playerData is Map<String, dynamic>) {
              cachedPlayers.add(Player.fromJson(playerData));
            }
          } catch (e) {
            debugPrint('Error parsing cached player: $e');
          }
        }

        if (cachedPlayers.isNotEmpty && !_isDisposed) {
          _safeSetState(() {
            players = cachedPlayers;
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load from cache: $e');
    } finally {
      if (!_isDisposed) {
        _safeSetState(() => _isLoadingFromCache = false);
      }
    }
  }

  Future<void> _fetchTeamDetails() async {
    if (_isDisposed) return;

    _safeSetState(() => _isLoading = true);

    try {
      final token = await storage.read(key: 'jwt_token');

      if (token == null || token.isEmpty) {
        await _handleAuthError();
        return;
      }

      final teamResponse = await ApiClient.instance.get(
        '/api/teams/my-team',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (_isDisposed) return;

      if (teamResponse.statusCode == 200) {
        await _handleSuccessResponse(teamResponse);
      } else if (teamResponse.statusCode == 401 || teamResponse.statusCode == 403) {
        await _handleAuthError();
      } else if (teamResponse.statusCode == 404) {
        _showError('Team not found.');
      } else if (teamResponse.statusCode >= 500) {
        await _handleRetryableError('Server error (${teamResponse.statusCode})');
      } else {
        _showError('Could not refresh team data (${teamResponse.statusCode}).');
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching team details: $e');
      debugPrint('Stack trace: $stackTrace');

      if (e is SocketException) {
        await _handleRetryableError('No internet connection. Please check your network and try again.');
      } else {
        await _handleRetryableError('Network error: ${_getErrorMessage(e)}');
      }
    } finally {
      if (!_isDisposed) {
        _safeSetState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSuccessResponse(dynamic teamResponse) async {
    try {
      final data = _safeJsonDecode(teamResponse.body);

      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid response format');
      }

      if (_isDisposed) return;

      _safeSetState(() {
        teamName = _safeString(data['team_name'], teamName);
        teamLogoUrl = _safeString(
          data['team_logo_url'] ?? data['team_logo'],
          teamLogoUrl,
        );
        teamLocation = _safeString(data['team_location'], teamLocation);
        trophies = _safeInt(data['trophies'], trophies);
        captainPlayerId = data['captain_player_id']?.toString();
        viceCaptainPlayerId = data['vice_captain_player_id']?.toString();
      });

      await _processPlayers(data);
      await _cacheTeamData(data);

      _retryCount = 0;
    } catch (e) {
      debugPrint('Error handling success response: $e');
      rethrow;
    }
  }

  Future<void> _processPlayers(Map<String, dynamic> data) async {
    try {
      final playersData = data['players'];

      if (playersData == null) {
        _safeSetState(() => players = []);
        return;
      }

      if (playersData is! List) {
        debugPrint('Expected List for players but got: ${playersData.runtimeType}');
        _safeSetState(() => players = []);
        return;
      }

      final parsedPlayers = <Player>[];
      final playerJsonList = <Map<String, dynamic>>[];

      for (final playerData in playersData) {
        try {
          if (playerData is Map<String, dynamic>) {
            final player = Player.fromJson(playerData);
            parsedPlayers.add(player);
            playerJsonList.add(playerData);
          }
        } catch (e) {
          debugPrint('Error parsing player: $e');
        }
      }

      if (_isDisposed) return;

      _safeSetState(() {
        players = parsedPlayers;
      });

      if (playerJsonList.isNotEmpty) {
        try {
          await cacheService.cachePlayersData(playerJsonList);
        } catch (e) {
          debugPrint('Error caching players: $e');
        }
      }
    } catch (e) {
      debugPrint('Error processing players: $e');
      _safeSetState(() => players = []);
    }
  }

  Future<void> _cacheTeamData(Map<String, dynamic> data) async {
    try {
      final teamDataToCache = Map<String, dynamic>.from(data);
      teamDataToCache.remove('players');
      await cacheService.cacheTeamData(teamDataToCache);
    } catch (e) {
      debugPrint('Error caching team data: $e');
    }
  }

    // Continuing from Part 1...

  Future<void> _handleAuthError() async {
    try {
      await storage.delete(key: 'jwt_token');
    } catch (e) {
      debugPrint('Error deleting token: $e');
    }

    if (!_isDisposed && mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _handleRetryableError(String errorMessage) async {
    if (_isDisposed) return;

    if (_retryCount < _maxRetries) {
      _retryCount++;
      final delay = Duration(
        milliseconds: _baseDelay.inMilliseconds * (1 << (_retryCount - 1)),
      );

      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$errorMessage. Retrying in ${delay.inSeconds}s... ($_retryCount/$_maxRetries)',
            ),
            duration: delay,
          ),
        );
      }

      await Future.delayed(delay);
      
      if (!_isDisposed && mounted) {
        await _fetchTeamDetails();
      }
    } else {
      _showRetrySnackBar(errorMessage);
    }
  }

  void _showRetrySnackBar(String errorMessage) {
    if (!mounted || _isDisposed) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$errorMessage. Tap to retry.'),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () {
            _retryCount = 0;
            _fetchTeamDetails();
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted || _isDisposed) return;
    ErrorHandler.showErrorSnackBar(context, message);
  }

  void _showSuccess(String message) {
    if (!mounted || _isDisposed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ $message')),
    );
  }

  Future<void> _addPlayer(String name, String role) async {
    if (_isDisposed) return;

    final token = await storage.read(key: 'jwt_token');
    
    if (token == null || token.isEmpty) {
      await _handleAuthError();
      return;
    }

    // Create placeholder with String ID
    final placeholderId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final placeholder = Player(
      id: placeholderId,
      playerName: name,
      playerRole: role,
      runs: 0,
      matchesPlayed: 0,
      hundreds: 0,
      fifties: 0,
      battingAverage: 0,
      strikeRate: 0,
      wickets: 0,
    );

    _safeSetState(() => players.add(placeholder));

    try {
      final response = await ApiClient.instance.post(
        '/api/players',
        headers: {'Authorization': 'Bearer $token'},
        body: {'player_name': name, 'player_role': role},
      );

      if (_isDisposed) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        await _handleAddPlayerSuccess(response, placeholderId);
      } else if (response.statusCode == 400) {
        await _handleAddPlayerError(response, placeholderId);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        await _handleAuthError();
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Failed to add player (${response.statusCode})');
      }
    } catch (e, stackTrace) {
      debugPrint('Error adding player: $e');
      debugPrint('Stack trace: $stackTrace');

      if (!_isDisposed) {
        _safeSetState(() => players.removeWhere((p) => p.id == placeholderId));
        
        final errorMessage = e is SocketException
            ? 'Failed to add player. Please check your connection and try again.'
            : 'Error: ${_getErrorMessage(e)}';
        
        _showError(errorMessage);
      }
    }
  }

  Future<void> _handleAddPlayerSuccess(
    dynamic response,
    String placeholderId,
  ) async {
    try {
      final data = _safeJsonDecode(response.body);
      
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid response format');
      }

      final newPlayer = Player.fromJson(data);

      if (!_isDisposed) {
        _safeSetState(() {
          final index = players.indexWhere((p) => p.id == placeholderId);
          if (index != -1) {
            players[index] = newPlayer;
          }
        });
        
        _showSuccess('Player added successfully');
      }
    } catch (e) {
      debugPrint('Error handling add player success: $e');
      _showError('Player added but failed to update display');
    }
  }

  Future<void> _handleAddPlayerError(
    dynamic response,
    String placeholderId,
  ) async {
    try {
      final data = _safeJsonDecode(response.body);
      final errorMsg = data is Map<String, dynamic>
          ? (data['error']?.toString() ?? 'Invalid player data')
          : 'Invalid player data';

      if (!_isDisposed) {
        _safeSetState(() => players.removeWhere((p) => p.id == placeholderId));
        _showError(errorMsg);
      }
    } catch (e) {
      debugPrint('Error handling add player error: $e');
      if (!_isDisposed) {
        _safeSetState(() => players.removeWhere((p) => p.id == placeholderId));
        _showError('Failed to add player');
      }
    }
  }

  Future<void> _editTeam(
    String newName,
    String newLocation, {
    String? captainId,
    String? viceCaptainId,
    String? logoUrl,
  }) async {
    if (_isDisposed) return;

    final token = await storage.read(key: 'jwt_token');
    
    if (token == null || token.isEmpty) {
      await _handleAuthError();
      return;
    }

    try {
      final body = {
        'team_name': newName,
        'team_location': newLocation,
        if (logoUrl != null && logoUrl.isNotEmpty) 'team_logo_url': logoUrl,
        'captain_player_id': captainId ?? captainPlayerId,
        'vice_captain_player_id': viceCaptainId ?? viceCaptainPlayerId,
      };

      final response = await ApiClient.instance.put(
        '/api/teams/update',
        headers: {'Authorization': 'Bearer $token'},
        body: body,
      );

      if (_isDisposed) return;

      if (response.statusCode == 200) {
        await _handleEditTeamSuccess(response);
      } else if (response.statusCode == 400) {
        await _handleEditTeamError(response);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        await _handleAuthError();
      } else if (response.statusCode == 404) {
        _showError('Team not found');
      } else if (response.statusCode >= 500) {
        _showError('Server error. Please try again later.');
      } else {
        _showError('Failed to update team (${response.statusCode})');
      }
    } catch (e, stackTrace) {
      debugPrint('Error editing team: $e');
      debugPrint('Stack trace: $stackTrace');

      if (!_isDisposed) {
        final errorMessage = e is SocketException
            ? 'Failed to update team. Please check your connection and try again.'
            : 'Error: ${_getErrorMessage(e)}';
        
        _showError(errorMessage);
      }
    }
  }

  Future<void> _handleEditTeamSuccess(dynamic response) async {
    try {
      final data = _safeJsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid response format');
      }

      if (data['team'] != null && data['team'] is Map<String, dynamic>) {
        final teamData = data['team'] as Map<String, dynamic>;
        
        if (!_isDisposed) {
          _safeSetState(() {
            teamName = _safeString(teamData['team_name'], teamName);
            teamLocation = _safeString(teamData['team_location'], teamLocation);
            teamLogoUrl = _safeString(teamData['team_logo_url'], teamLogoUrl);
            captainPlayerId = teamData['captain_player_id']?.toString();
            viceCaptainPlayerId = teamData['vice_captain_player_id']?.toString();
          });

          _showSuccess('Team Updated');
        }
      }
    } catch (e) {
      debugPrint('Error handling edit team success: $e');
      _showError('Team updated but failed to refresh display');
    }
  }

  Future<void> _handleEditTeamError(dynamic response) async {
    try {
      final data = _safeJsonDecode(response.body);
      final errorMsg = data is Map<String, dynamic>
          ? (data['error']?.toString() ?? 'Invalid team data')
          : 'Invalid team data';
      
      _showError(errorMsg);
    } catch (e) {
      debugPrint('Error handling edit team error: $e');
      _showError('Failed to update team');
    }
  }

  Future<void> _deleteTeam() async {
    if (_isDisposed || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Team'),
        content: const Text(
          'Are you sure you want to delete your team? This action cannot be undone and will remove all players and team data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || _isDisposed) return;

    _safeSetState(() => _isLoading = true);

    final token = await storage.read(key: 'jwt_token');
    
    if (token == null || token.isEmpty) {
      await _handleAuthError();
      return;
    }

    try {
      final response = await ApiClient.instance.delete(
        '/api/teams/my-team',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (_isDisposed) return;

      if (response.statusCode == 200) {
        if (mounted) {
          _showSuccess('Team deleted successfully');
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted && !_isDisposed) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      } else if (response.statusCode == 400) {
        await _handleDeleteTeamError(response);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        await _handleAuthError();
      } else if (response.statusCode == 404) {
        _showError('Team not found');
      } else if (response.statusCode >= 500) {
        _showError('Server error. Please try again later.');
      } else {
        _showError('Failed to delete team (${response.statusCode})');
      }
    } catch (e, stackTrace) {
      debugPrint('Error deleting team: $e');
      debugPrint('Stack trace: $stackTrace');

      if (!_isDisposed) {
        final errorMessage = e is SocketException
            ? 'Failed to delete team. Please check your connection and try again.'
            : 'Error: ${_getErrorMessage(e)}';
        
        _showError(errorMessage);
      }
    } finally {
      if (!_isDisposed) {
        _safeSetState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDeleteTeamError(dynamic response) async {
    try {
      final data = _safeJsonDecode(response.body);
      final errorMsg = data is Map<String, dynamic>
          ? (data['error']?.toString() ?? 'Cannot delete team')
          : 'Cannot delete team';
      
      _showError(errorMsg);
    } catch (e) {
      debugPrint('Error handling delete team error: $e');
      _showError('Failed to delete team');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please wait for the current operation to complete'),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Column(
          children: [
            if (_isOffline) _buildOfflineBanner(),
            if (_isLoadingFromCache && !_isOffline) _buildLoadingCacheBanner(),
            Expanded(child: _buildMainContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.orange.shade800,
      child: const Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'You are offline. Showing cached data. Will sync when connection is restored.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCacheBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.blue.shade800,
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Loading cached data...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        title: Text(
          teamName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: _isLoading
              ? null
              : () {
                  if (mounted && !_isDisposed) {
                    Navigator.pop(context);
                  }
                },
          tooltip: 'Go back',
        ),
      ),
      body: _isLoading && players.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchTeamDetails,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    _buildTeamHeader(),
                    const SizedBox(height: 20),
                    Expanded(child: _buildPlayersList()),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTeamHeader() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade800,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: SizedBox(
              width: 120,
              height: 120,
              child: teamLogoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: teamLogoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) {
                        debugPrint('Error loading team logo: $error');
                        return const Center(
                          child: Icon(
                            Icons.shield,
                            color: Colors.white54,
                            size: 60,
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(Icons.shield, color: Colors.white54, size: 60),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          teamName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, color: Colors.amber.shade400, size: 20),
            const SizedBox(width: 8),
            Text(
              "$trophies ${trophies == 1 ? 'Trophy' : 'Trophies'}",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (teamLocation.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, color: Colors.grey.shade400, size: 18),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  teamLocation,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPlayersList() {
    if (players.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "No players in this team yet.",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        try {
          if (index >= players.length) {
            return const SizedBox.shrink();
          }

          final player = players[index];
          final isCaptain = player.id == captainPlayerId;
          final isViceCaptain = player.id == viceCaptainPlayerId;

          return Card(
            color: const Color(0xFF1A2C22),
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF2D4A3A),
                backgroundImage: player.hasProfileImage
                    ? NetworkImage(player.playerImageUrl!)
                    : null,
                child: !player.hasProfileImage
                    ? Text(
                        player.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
                onBackgroundImageError: (exception, stackTrace) {
                  debugPrint('Error loading player image: $exception');
                },
              ),
              title: Text(
                player.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                "${player.displayRole}\nRuns: ${player.runs} | Avg: ${player.battingAverage.toStringAsFixed(1)}",
                style: const TextStyle(
                  color: Color(0xFFB8E6C1),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: isCaptain
                  ? const Chip(
                      label: Text(
                        'Captain',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: Colors.amber,
                    )
                  : isViceCaptain
                      ? const Chip(
                          label: Text(
                            'Vice Captain',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          backgroundColor: Colors.blue,
                        )
                      : null,
              onTap: () => _navigateToPlayerDashboard(player, index),
            ),
          );
        } catch (e) {
          debugPrint('Error building player card at index $index: $e');
          return const SizedBox.shrink();
        }
      },
    );
  }

  Future<void> _navigateToPlayerDashboard(Player player, int index) async {
    if (_isDisposed || !mounted) return;

    try {
      final updatedPlayer = await Navigator.push<Player>(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerDashboardScreen(player: player),
        ),
      );

      if (updatedPlayer != null && !_isDisposed && index < players.length) {
        _safeSetState(() {
          players[index] = updatedPlayer;
        });
      }
    } catch (e) {
      debugPrint('Error navigating to player dashboard: $e');
    }
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.person_add, color: Colors.white, size: 20),
                  label: const Text(
                    "Add Player",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: _isLoading ? null : () => _showAddPlayerDialog(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                  label: const Text(
                    "Edit Team",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: _isLoading ? null : () => _showEditTeamDialog(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade600,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            icon: const Icon(Icons.delete, size: 20),
            label: const Text(
              "Delete Team",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            onPressed: _isLoading ? null : _deleteTeam,
          ),
        ],
      ),
    );
  }

  void _showAddPlayerDialog(BuildContext context) {
    if (_isDisposed || !mounted) return;

    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final roles = ['Batsman', 'Bowler', 'All-rounder', 'Wicket-keeper'];
    String? selectedRole = roles[0];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text(
              "Add Player",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: "Player Name",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Player name is required';
                      }
                      if (v.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                    style: const TextStyle(fontSize: 16),
                    maxLength: 50,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: "Role",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    items: roles
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(r, style: const TextStyle(fontSize: 16)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => selectedRole = value),
                    validator: (v) => v == null ? 'Role is required' : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  nameController.dispose();
                  Navigator.pop(dialogContext);
                },
                child: const Text(
                  "Cancel",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  
                  final name = nameController.text.trim();
                  if (selectedRole == null) return;
                  
                  _addPlayer(name, selectedRole!);
                  nameController.dispose();
                  Navigator.pop(dialogContext);
                },
                child: const Text(
                  "Add",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      // Ensure controller is disposed
      try {
        nameController.dispose();
      } catch (e) {
        debugPrint('Controller already disposed: $e');
      }
    });
  }

  void _showEditTeamDialog(BuildContext context) {
    if (_isDisposed || !mounted) return;

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: teamName);
    final locationController = TextEditingController(text: teamLocation);
    final logoController = TextEditingController(text: teamLogoUrl);

    String? tempCaptainId = captainPlayerId;
    String? tempViceCaptainId = viceCaptainPlayerId;
    String tempLogoUrl = teamLogoUrl;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text(
              "Edit Team",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: "Team Name",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Team name is required';
                        }
                        if (value.trim().length < 3) {
                          return 'Team name must be at least 3 characters';
                        }
                        return null;
                      },
                      maxLength: 50,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: locationController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: "Team Location",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Team location is required';
                        }
                        return null;
                      },
                      maxLength: 100,
                    ),
                    const SizedBox(height: 16),
                    if (widget.teamId != null)
                      ImageUploadWidget(
                        label: 'Team Logo',
                        currentImageUrl: tempLogoUrl.isNotEmpty ? tempLogoUrl : null,
                        onImageUploaded: (imageUrl) {
                          setDialogState(() {
                            tempLogoUrl = imageUrl ?? '';
                            logoController.text = imageUrl ?? '';
                          });
                        },
                        onImageRemoved: () {
                          setDialogState(() {
                            tempLogoUrl = '';
                            logoController.text = '';
                          });
                        },
                      ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: tempCaptainId,
                      decoration: const InputDecoration(
                        labelText: "Captain",
                        border: OutlineInputBorder(),
                      ),
                      items: players
                          .map(
                            (p) => DropdownMenuItem<String>(
                              value: p.id,
                              child: Text(
                                p.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setDialogState(() => tempCaptainId = v),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: tempViceCaptainId,
                      decoration: const InputDecoration(
                        labelText: "Vice Captain",
                        border: OutlineInputBorder(),
                      ),
                      items: players
                          .map(
                            (p) => DropdownMenuItem<String>(
                              value: p.id,
                              child: Text(
                                p.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setDialogState(() => tempViceCaptainId = v),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  nameController.dispose();
                  locationController.dispose();
                  logoController.dispose();
                  Navigator.pop(dialogContext);
                },
                child: const Text(
                  "Cancel",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;

                  if (tempCaptainId != null && tempCaptainId == tempViceCaptainId) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Captain and Vice Captain must be different players.',
                        ),
                      ),
                    );
                    return;
                  }

                  _editTeam(
                    nameController.text.trim(),
                    locationController.text.trim(),
                    captainId: tempCaptainId,
                    viceCaptainId: tempViceCaptainId,
                    logoUrl: tempLogoUrl.isNotEmpty ? tempLogoUrl : null,
                  );

                  nameController.dispose();
                  locationController.dispose();
                  logoController.dispose();
                  Navigator.pop(dialogContext);
                },
                child: const Text(
                  "Save",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      // Ensure controllers are disposed
      try {
        nameController.dispose();
        locationController.dispose();
        logoController.dispose();
      } catch (e) {
        debugPrint('Controllers already disposed: $e');
      }
    });
  }
}