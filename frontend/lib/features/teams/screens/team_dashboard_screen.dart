import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/api_client.dart';
import '../../../core/cache_service.dart';
import '../../../core/error_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/player.dart';
import 'player_dashboard_screen.dart';

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
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _baseDelay = Duration(seconds: 1);
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  String teamName = '';
  String teamLogoUrl = '';
  String teamLocation = '';
  int trophies = 0;
  List<Player> players = [];
  int? captainPlayerId;
  int? viceCaptainPlayerId;

  @override
  void initState() {
    super.initState();
    teamName = widget.teamName ?? 'Team';
    teamLogoUrl = widget.teamLogoUrl ?? '';
    trophies = widget.trophies ?? 0;
    players = widget.players ?? [];

    _startConnectivityMonitoring();

    _loadFromCacheAndFetch();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _startConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final isConnected = results.contains(ConnectivityResult.mobile) ||
            results.contains(ConnectivityResult.wifi) ||
            results.contains(ConnectivityResult.ethernet);

        if (mounted) {
          setState(() {
            _isOffline = !isConnected;
          });

          if (isConnected && _isOffline) {
            _retryCount = 0;
            _fetchTeamDetails();
          }
        }
      },
    );
  }

  Future<void> _loadFromCacheAndFetch() async {
    await _loadFromCache();

    _fetchTeamDetails();
  }

  Future<void> _loadFromCache() async {
    try {
      setState(() => _isLoadingFromCache = true);

      final cachedTeamData = await cacheService.getCachedTeamData();
      final cachedPlayersData = await cacheService.getCachedPlayersData();

      if (cachedTeamData != null) {
        if (mounted) {
          setState(() {
            teamName = cachedTeamData['team_name']?.toString() ?? teamName;
            teamLogoUrl =
                cachedTeamData['team_logo_url']?.toString() ?? teamLogoUrl;
            teamLocation =
                cachedTeamData['team_location']?.toString() ?? teamLocation;
            trophies =
                (cachedTeamData['trophies'] as num?)?.toInt() ?? trophies;
            captainPlayerId = (cachedTeamData['captain_player_id'] as num?)?.toInt();
            viceCaptainPlayerId =
                (cachedTeamData['vice_captain_player_id'] as num?)?.toInt();
          });
        }
      }

      if (cachedPlayersData != null) {
        if (mounted) {
          setState(() {
            players = cachedPlayersData.map((p) => Player.fromJson(p)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load from cache: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingFromCache = false);
      }
    }
  }

  Future<void> _fetchTeamDetails() async {
    setState(() => _isLoading = true);
    final token = await storage.read(key: 'jwt_token');

    try {
      final teamResponse = await ApiClient.instance.get(
        '/api/teams/my-team',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (teamResponse.statusCode == 200) {
        final data = jsonDecode(teamResponse.body);
        teamName = data['team_name']?.toString() ?? teamName;
        teamLogoUrl =
            data['team_logo_url']?.toString() ??
            data['team_logo']?.toString() ??
            teamLogoUrl;
        teamLocation = data['team_location']?.toString() ?? teamLocation;
        trophies = (data['trophies'] as num?)?.toInt() ?? trophies;

        captainPlayerId = (data['captain_player_id'] as num?)?.toInt();
        viceCaptainPlayerId = (data['vice_captain_player_id'] as num?)?.toInt();

        if (data['players'] != null) {
          final playersList = data['players'] as List;
          players = playersList.map((p) => Player.fromJson(p)).toList();

          final playersData = playersList.cast<Map<String, dynamic>>();
          await cacheService.cachePlayersData(playersData);
        }

        final teamDataToCache = Map<String, dynamic>.from(data);
        teamDataToCache.remove(
          'players',
        ); 
        await cacheService.cacheTeamData(teamDataToCache);

        _retryCount = 0;
      } else if (teamResponse.statusCode == 401 ||
          teamResponse.statusCode == 403) {
        _logout();
        return;
      } else if (teamResponse.statusCode == 404) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, 'Team not found.');
        }
      } else if (teamResponse.statusCode >= 500) {
        await _handleRetryableError(
          'Server error (${teamResponse.statusCode})',
        );
      } else {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(
            context,
            'Could not refresh team data (${teamResponse.statusCode}).',
          );
        }
      }
    } catch (e) {
      await _handleRetryableError('Network error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRetryableError(String errorMessage) async {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      final delay = Duration(
        milliseconds: _baseDelay.inMilliseconds * (1 << (_retryCount - 1)),
      );

      if (mounted) {
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
      if (mounted) {
        _fetchTeamDetails();
      }
    } else {
      if (mounted) {
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
          ),
        );
      }
    }
  }

  Future<void> _addPlayer(String name, String role) async {
    final token = await storage.read(key: 'jwt_token');
    final placeholderId = DateTime.now().millisecondsSinceEpoch * -1;
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

    setState(() => players.add(placeholder));

    try {
      final response = await ApiClient.instance.post(
        '/api/players',
        headers: {'Authorization': 'Bearer $token'},
        body: {'player_name': name, 'player_role': role},
      );

      if (response.statusCode == 201) {
        final newPlayer = Player.fromJson(jsonDecode(response.body));
        setState(() {
          final index = players.indexWhere((p) => p.id == placeholderId);
          if (index != -1) players[index] = newPlayer;
        });
      } else {
        throw 'Failed to add player: ${response.body}';
      }
    } catch (e) {
      setState(() => players.removeWhere((p) => p.id == placeholderId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _editTeam(
    String newName,
    String newLocation, {
    int? captainId,
    int? viceCaptainId,
    String? logoUrl,
  }) async {
    final token = await storage.read(key: 'jwt_token');
    try {
      final response = await ApiClient.instance.put(
        '/api/teams/update',
        headers: {'Authorization': 'Bearer $token'},
        body: {
          'team_name': newName,
          'team_location': newLocation,
          if (logoUrl != null) 'team_logo_url': logoUrl,
          'captain_player_id': captainId ?? captainPlayerId,
          'vice_captain_player_id': viceCaptainId ?? viceCaptainPlayerId,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['team'] != null) {
          final teamData = data['team'];
          setState(() {
            teamName = teamData['team_name']?.toString() ?? teamName;
            teamLocation =
                teamData['team_location']?.toString() ?? teamLocation;
            teamLogoUrl = teamData['team_logo_url']?.toString() ?? teamLogoUrl;
            captainPlayerId =
                (teamData['captain_player_id'] as num?)?.toInt() ??
                captainPlayerId;
            viceCaptainPlayerId =
                (teamData['vice_captain_player_id'] as num?)?.toInt() ??
                viceCaptainPlayerId;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("✅ Team Updated")));
        }
      } else {
        throw 'Failed to update team: ${response.body}';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteTeam() async {
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

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    final token = await storage.read(key: 'jwt_token');

    try {
      final response = await ApiClient.instance.delete(
        '/api/teams/my-team',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Team deleted successfully')),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'Cannot delete team')),
          );
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _logout();
      } else {
        throw 'Failed to delete team: ${response.body}';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _logout() async {
    try {
      await ApiClient.instance.logout();
    } catch (_) {}
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF122118),
      body: Column(
        children: [
          if (_isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Colors.orange.shade800, 
              child: Row(
                children: [
                  Icon(
                    Icons.wifi_off,
                    color: Colors.white,
                    size: 20,
                  ), 
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You are offline. Showing cached data. Will sync when connection is restored.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16, 
                        fontWeight: FontWeight.w600, 
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_isLoadingFromCache && !_isOffline)
            Container(
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
            ),
          Expanded(
            child: Scaffold(
              backgroundColor: const Color(0xFF122118),
              appBar: AppBar(
                backgroundColor: const Color(0xFF122118),
                elevation: 0,
                title: Text(
                  teamName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20, 
                  ),
                ),
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ), 
                  onPressed: () => Navigator.pop(context),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamHeader() => Column(
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
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(
                        Icons.shield,
                        color: Colors.white54,
                        size: 60,
                      ),
                    ),
                  )
                : const Center(
                    child: Icon(
                      Icons.shield,
                      color: Colors.white54,
                      size: 60,
                    ),
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
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events,
            color: Colors.amber.shade400,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            "$trophies ${trophies == 1 ? 'Trophy' : 'Trophies'}",
            style: TextStyle(
              color: Colors.grey.shade300,
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
            Icon(
              Icons.location_on,
              color: Colors.grey.shade400,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              teamLocation,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    ],
  );

  Widget _buildPlayersList() => players.isEmpty
      ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: Colors.grey.shade400, 
              ),
              const SizedBox(height: 16),
              Text(
                "No players in this team yet.",
                style: TextStyle(
                  color: Colors.grey.shade300, 
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )
      : ListView.builder(
          itemCount: players.length,
          itemBuilder: (context, index) {
            final player = players[index];
            bool isCaptain = player.id == captainPlayerId;
            bool isViceCaptain = player.id == viceCaptainPlayerId;
            return Card(
              color: const Color(0xFF1A2C22),
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 2, 
              child: ListTile(
                leading: CircleAvatar(
                  radius: 26, 
                  backgroundColor: const Color(
                    0xFF2D4A3A,
                  ), 
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 24, 
                  ),
                ),
                title: Text(
                  player.playerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16, 
                  ),
                ),
                subtitle: Text(
                  "${player.playerRole}\nRuns: ${player.runs} | Avg: ${player.battingAverage.toStringAsFixed(1)}",
                  style: const TextStyle(
                    color: Color(0xFFB8E6C1), 
                    fontSize: 14, 
                    fontWeight: FontWeight.w400,
                  ),
                ),
                trailing: isCaptain
                    ? Chip(
                        label: const Text(
                          'Captain',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor:
                            Colors.amber.shade700, 
                      )
                    : isViceCaptain
                    ? Chip(
                        label: const Text(
                          'Vice Captain',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor:
                            Colors.blue.shade700, 
                      )
                    : null,
                onTap: () async {
                  final updatedPlayer = await Navigator.push<Player>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayerDashboardScreen(player: player),
                    ),
                  );
                  if (updatedPlayer != null) {
                    setState(() {
                      players[index] = updatedPlayer;
                    });
                  }
                },
              ),
            );
          },
        );

  Widget _buildActionButtons() => Padding(
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
                icon: const Icon(
                  Icons.person_add,
                  color: Colors.white,
                  size: 20,
                ), 
                label: const Text(
                  "Add Player",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16, 
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => _showAddPlayerDialog(context),
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
                icon: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 20,
                ), 
                label: const Text(
                  "Edit Team",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16, 
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => _showEditTeamDialog(context),
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
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: _deleteTeam,
        ),
      ],
    ),
  );

  void _showAddPlayerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final roles = ['Batsman', 'Bowler', 'All-rounder', 'Wicket-keeper'];
    String? selectedRole = roles[0];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          "Add Player",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Player Name",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedRole,
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
              onChanged: (value) => selectedRole = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty || selectedRole == null) return;
              _addPlayer(name, selectedRole!);
              Navigator.pop(context);
            },
            child: const Text(
              "Add",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditTeamDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: teamName);
    final locationController = TextEditingController(text: teamLocation);
    final logoController = TextEditingController(text: teamLogoUrl);
    
    void disposeControllers() {
      nameController.dispose();
      locationController.dispose();
      logoController.dispose();
    }

    int? tempCaptainId = captainPlayerId;
    int? tempViceCaptainId = viceCaptainPlayerId;

    void onSubmit() {
      if (formKey.currentState?.validate() != true) {
        return;
      }

      if (tempCaptainId != null && tempCaptainId == tempViceCaptainId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Captain and Vice Captain must be different players.',
              style: TextStyle(fontSize: 16),
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
        logoUrl: logoController.text.trim().isNotEmpty
            ? logoController.text.trim()
            : null,
      );
      disposeControllers();
      Navigator.pop(context);
    }

    void onCancel() {
      disposeControllers();
      Navigator.pop(context);
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return WillPopScope(
            onWillPop: () async {
              disposeControllers();
              return true;
            },
            child: AlertDialog(
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
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: locationController,
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
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: logoController,
                        decoration: const InputDecoration(
                          labelText: "Team Logo URL",
                          border: OutlineInputBorder(),
                          helperText: 'Leave empty to remove logo',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          try {
                            final uri = Uri.parse(value);
                            if (!uri.hasScheme || !uri.hasAuthority) {
                              return 'Please enter a valid URL';
                            }
                          } catch (_) {
                            return 'Please enter a valid URL';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: tempCaptainId,
                        decoration: const InputDecoration(
                          labelText: "Captain",
                          border: OutlineInputBorder(),
                        ),
                        items: players
                            .map(
                              (p) => DropdownMenuItem<int>(
                                value: p.id,
                                child: Text(p.playerName),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => tempCaptainId = v),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: tempViceCaptainId,
                        decoration: const InputDecoration(
                          labelText: "Vice Captain",
                          border: OutlineInputBorder(),
                        ),
                        items: players
                            .map(
                              (p) => DropdownMenuItem<int>(
                                value: p.id,
                                child: Text(p.playerName),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => tempViceCaptainId = v),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: onCancel,
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
                  onPressed: onSubmit,
                  child: const Text(
                    "Save",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
