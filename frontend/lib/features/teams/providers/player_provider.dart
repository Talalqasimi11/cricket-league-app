import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';
import '../models/player.dart';

class PlayerProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Player> _players = [];
  Player? _selectedPlayer;
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _error;
  int? _teamFilter;

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

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      try {
        notifyListeners();
      } catch (e) {
        debugPrint('Error notifying listeners: $e');
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error == null) return 'Unknown error';
    final message = error.toString();
    return message.replaceAll('Exception:', '').trim();
  }

  // Getters
  List<Player> get players => List.unmodifiable(_players);
  Player? get selectedPlayer => _selectedPlayer;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get teamFilter => _teamFilter;

  // Get player count
  int get playerCount => _players.length;

  // Check if has players
  bool get hasPlayers => _players.isNotEmpty;

  // Fetch all players
  Future<void> fetchPlayers({int? teamId}) async {
    if (_isDisposed) return;

    _setLoading(true);
    _error = null;
    _teamFilter = teamId;

    try {
      // FIX: Convert int? to String? for API call
      final dynamic response = await _apiService.getPlayers(
        teamId: teamId?.toString()
      );

      if (_isDisposed) return;

      if (response == null) {
        _players = [];
        _safeNotifyListeners();
        return;
      }

      // Parse response
      List<dynamic> rawPlayers = [];
      
      if (response is List) {
        rawPlayers = response;
      } else if (response is Map<String, dynamic>) {
        if (response['players'] is List) {
          rawPlayers = response['players'] as List;
        } else if (response['data'] is List) {
          rawPlayers = response['data'] as List;
        }
      }

      final parsedPlayers = <Player>[];

      for (final playerData in rawPlayers) {
        try {
          if (playerData is Map<String, dynamic>) {
            final player = Player.fromJson(playerData);
            if (player.isValid) {
              parsedPlayers.add(player);
            } else {
              debugPrint('Skipping invalid player: ${playerData['id']}');
            }
          } else {
            debugPrint('Invalid player data type: ${playerData.runtimeType}');
          }
        } catch (e) {
          debugPrint('Error parsing player: $e');
          // Continue processing other players
        }
      }

      if (!_isDisposed) {
        _players = parsedPlayers;
        _safeNotifyListeners();
      }
    } catch (e, stackTrace) {
      debugPrint('Fetch players error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (!_isDisposed) {
        _error = _getErrorMessage(e);
        _safeNotifyListeners();
      }
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  // Fetch single player
  Future<void> fetchPlayer(String playerId) async {
    if (_isDisposed) return;

    // Validate player ID
    if (playerId.isEmpty) {
      _error = 'Invalid player ID';
      _safeNotifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;

    try {
      final dynamic response = await _apiService.getPlayer(playerId);

      if (_isDisposed) return;

      if (response == null) {
        _selectedPlayer = null;
        _error = 'Player not found';
        _safeNotifyListeners();
        return;
      }

      // Parse response
      Map<String, dynamic>? playerData;

      if (response is Map<String, dynamic>) {
        if (response['player'] is Map<String, dynamic>) {
          playerData = response['player'] as Map<String, dynamic>;
        } else if (response.containsKey('id')) {
          playerData = response;
        }
      }

      if (playerData != null) {
        _selectedPlayer = Player.fromJson(playerData);
        
        // Update player in list if exists
        final index = _players.indexWhere((p) => p.id == _selectedPlayer!.id);
        if (index != -1) {
          _players[index] = _selectedPlayer!;
        }
      } else {
        _selectedPlayer = null;
        _error = 'Invalid player data';
      }

      if (!_isDisposed) {
        _safeNotifyListeners();
      }
    } catch (e, stackTrace) {
      debugPrint('Fetch player error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (!_isDisposed) {
        _error = _getErrorMessage(e);
        _safeNotifyListeners();
      }
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  // Get player by ID
  Player? getPlayerById(String playerId) {
    try {
      if (playerId.isEmpty || _players.isEmpty) {
        return null;
      }

      return _players.firstWhere(
        (p) => p.id == playerId,
        orElse: () => throw StateError('Player not found'),
      );
    } on StateError {
      debugPrint('Player not found with ID: $playerId');
      return null;
    } catch (e) {
      debugPrint('Error getting player by ID: $e');
      return null;
    }
  }

  // Search players
  List<Player> searchPlayers(String query) {
    try {
      if (query.isEmpty) return List.from(_players);

      final lowerQuery = query.toLowerCase().trim();
      
      return _players.where((player) {
        try {
          final name = player.playerName.toLowerCase();
          final role = player.playerRole.toLowerCase();
          
          return name.contains(lowerQuery) || role.contains(lowerQuery);
        } catch (e) {
          debugPrint('Error searching player: $e');
          return false;
        }
      }).toList();
    } catch (e) {
      debugPrint('Error in searchPlayers: $e');
      return [];
    }
  }

  // Filter by role
  List<Player> filterByRole(String role) {
    try {
      if (role.isEmpty) return List.from(_players);

      final lowerRole = role.toLowerCase().trim();
      
      return _players.where((player) {
        try {
          return player.playerRole.toLowerCase() == lowerRole;
        } catch (e) {
          debugPrint('Error filtering player: $e');
          return false;
        }
      }).toList();
    } catch (e) {
      debugPrint('Error in filterByRole: $e');
      return [];
    }
  }

  // Get all available roles
  List<String> getAllRoles() {
    try {
      final roles = <String>{};
      
      for (final player in _players) {
        try {
          if (player.playerRole.isNotEmpty) {
            roles.add(player.playerRole);
          }
        } catch (e) {
          debugPrint('Error getting role from player: $e');
        }
      }
      
      final rolesList = roles.toList();
      rolesList.sort(); // Sort alphabetically
      return rolesList;
    } catch (e) {
      debugPrint('Error getting all roles: $e');
      return [];
    }
  }

  // Get players by team
  List<Player> getPlayersByTeam(int teamId) {
    try {
      return _players.where((player) {
        // Assuming Player model has a teamId field
        // Adjust based on your actual Player model
        return true; // Placeholder - implement based on your model
      }).toList();
    } catch (e) {
      debugPrint('Error getting players by team: $e');
      return [];
    }
  }

  // Get top scorers
  List<Player> getTopScorers({int limit = 10}) {
    try {
      final sortedPlayers = List<Player>.from(_players);
      sortedPlayers.sort((a, b) => b.runs.compareTo(a.runs));
      return sortedPlayers.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting top scorers: $e');
      return [];
    }
  }

  // Get top wicket takers
  List<Player> getTopWicketTakers({int limit = 10}) {
    try {
      final sortedPlayers = List<Player>.from(_players);
      sortedPlayers.sort((a, b) => b.wickets.compareTo(a.wickets));
      return sortedPlayers.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting top wicket takers: $e');
      return [];
    }
  }

  // Get players by role type
  List<Player> getBatsmen() {
    try {
      return _players.where((p) => p.isBatsman).toList();
    } catch (e) {
      debugPrint('Error getting batsmen: $e');
      return [];
    }
  }

  List<Player> getBowlers() {
    try {
      return _players.where((p) => p.isBowler).toList();
    } catch (e) {
      debugPrint('Error getting bowlers: $e');
      return [];
    }
  }

  List<Player> getAllRounders() {
    try {
      return _players.where((p) => p.isAllRounder).toList();
    } catch (e) {
      debugPrint('Error getting all-rounders: $e');
      return [];
    }
  }

  List<Player> getWicketKeepers() {
    try {
      return _players.where((p) => p.isWicketKeeper).toList();
    } catch (e) {
      debugPrint('Error getting wicket-keepers: $e');
      return [];
    }
  }

  // Update player in list
  void updatePlayer(Player player) {
    try {
      if (_isDisposed) return;

      final index = _players.indexWhere((p) => p.id == player.id);
      
      if (index != -1) {
        _players[index] = player;
        
        // Update selected player if it's the same
        if (_selectedPlayer?.id == player.id) {
          _selectedPlayer = player;
        }
        
        _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating player: $e');
    }
  }

  // Add player to list
  void addPlayer(Player player) {
    try {
      if (_isDisposed) return;

      // Check if player already exists
      final existingIndex = _players.indexWhere((p) => p.id == player.id);
      
      if (existingIndex == -1) {
        _players.add(player);
        _safeNotifyListeners();
      } else {
        debugPrint('Player already exists, updating instead');
        updatePlayer(player);
      }
    } catch (e) {
      debugPrint('Error adding player: $e');
    }
  }

  // Remove player from list
  void removePlayer(String playerId) {
    try {
      if (_isDisposed) return;

      final initialLength = _players.length;
      _players.removeWhere((p) => p.id == playerId);
      
      if (_players.length != initialLength) {
        // Player was removed
        if (_selectedPlayer?.id == playerId) {
          _selectedPlayer = null;
        }
        
        _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Error removing player: $e');
    }
  }

  // Set selected player
  void setSelectedPlayer(Player? player) {
    try {
      if (_isDisposed) return;

      if (_selectedPlayer != player) {
        _selectedPlayer = player;
        _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Error setting selected player: $e');
    }
  }

  // Clear selected player
  void clearSelectedPlayer() {
    setSelectedPlayer(null);
  }

  // Refresh players
  Future<void> refresh() async {
    await fetchPlayers(teamId: _teamFilter);
  }

  void _setLoading(bool loading) {
    try {
      if (_isDisposed) return;

      if (_isLoading != loading) {
        _isLoading = loading;
        _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Error setting loading state: $e');
    }
  }

  // Clear error
  void clearError() {
    if (_isDisposed) return;

    if (_error != null) {
      _error = null;
      _safeNotifyListeners();
    }
  }

  // Clear all data
  void clear() {
    if (_isDisposed) return;

    try {
      _players = [];
      _selectedPlayer = null;
      _error = null;
      _teamFilter = null;
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('Error clearing data: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    
    try {
      // Dispose API service if it has resources
      // _apiService.dispose(); // Uncomment if ApiService has dispose method
    } catch (e) {
      debugPrint('Error disposing API service: $e');
    }

    try {
      _players.clear();
    } catch (e) {
      debugPrint('Error clearing players on dispose: $e');
    }

    super.dispose();
  }
}