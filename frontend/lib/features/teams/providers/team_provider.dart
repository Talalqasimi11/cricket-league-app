import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';
import '../../../core/api_client.dart';
import '../../../models/team.dart';
import '../models/player.dart';

class TeamProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // General Teams State
  List<Team> _teams = [];
  Team? _selectedTeam;

  // "My Team" Specific State
  Map<String, dynamic>? _myTeamData;
  List<Player> _myTeamPlayers = [];

  bool _isLoading = false;
  bool _isDisposed = false;
  String? _error;

  // Getters
  List<Team> get teams => List.unmodifiable(_teams);
  Team? get selectedTeam => _selectedTeam;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasTeams => _teams.isNotEmpty;
  int get teamCount => _teams.length;

  // "My Team" Getters
  Map<String, dynamic>? get myTeamData => _myTeamData;
  List<Player> get myTeamPlayers => List.unmodifiable(_myTeamPlayers);
  bool get hasMyTeam => _myTeamData != null;

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
    if (error == null) return 'Unknown error occurred';
    final message = error.toString();
    return message.replaceAll('Exception:', '').trim();
  }

  // ==========================================
  // FETCH MY TEAM (Optimized)
  // ==========================================
  Future<void> fetchMyTeam() async {
    if (_isDisposed) return;

    _setLoading(true);
    _error = null;

    try {
      debugPrint("📥 Fetching My Team Data...");
      // ✅ Correct Direct API Call
      final response = await ApiClient.instance.get(
        '/api/teams/my-team',
        forceRefresh: true, // Force fresh fetch to bypass cache
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          dynamic teamPayload = data;
          // Handle various API wrapper structures
          if (data.containsKey('team')) {
            teamPayload = data['team'];
          } else if (data.containsKey('data')) {
            teamPayload = data['data'];
          }

          _myTeamData = teamPayload;

          // Safe parsing for players
          List<dynamic> playersList = [];
          if (teamPayload['players'] != null) {
            playersList = teamPayload['players'];
          } else if (data['players'] != null) {
            playersList = data['players'];
          }

          _myTeamPlayers = playersList.map((e) => Player.fromJson(e)).toList();
        }
      } else if (response.statusCode == 404) {
        _myTeamData = null;
        _myTeamPlayers = [];
      } else if (response.statusCode == 401) {
        _myTeamData = null;
        _myTeamPlayers = [];
        _error = 'Unauthorized';
      } else {
        _error = 'Failed to load team: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint("❌ Error in fetchMyTeam: $e");
      _error = _getErrorMessage(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createTeam(Map<String, dynamic> teamData) async {
    _setLoading(true);
    try {
      final response = await ApiClient.instance.post(
        '/api/teams/my-team',
        body: teamData,
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchMyTeam();
        return true;
      }
      _error = 'Failed to create team';
      return false;
    } catch (e) {
      _error = _getErrorMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateMyTeam(Map<String, dynamic> updates) async {
    _setLoading(true);
    try {
      final response = await ApiClient.instance.put(
        '/api/teams/update',
        body: updates,
      );
      if (response.statusCode == 200) {
        await fetchMyTeam();
        return true;
      }
      _error = 'Failed to update team';
      return false;
    } catch (e) {
      _error = _getErrorMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteMyTeam() async {
    _setLoading(true);
    try {
      final response = await ApiClient.instance.delete('/api/teams/my-team');
      if (response.statusCode == 200) {
        _myTeamData = null;
        _myTeamPlayers = [];
        _safeNotifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = _getErrorMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addPlayerToMyTeam(String name, String role) async {
    _setLoading(true); // ✅ Added loading state
    try {
      final response = await ApiClient.instance.post(
        '/api/players',
        body: {'player_name': name, 'player_role': role},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchMyTeam();
        return true;
      }
      return false;
    } catch (e) {
      _error = _getErrorMessage(e);
      _safeNotifyListeners();
      return false;
    } finally {
      _setLoading(false); // ✅ Turn off loading
    }
  }

  // ==========================================
  // CREATE PLAYER (GENERIC)
  // ==========================================
  Future<Player?> createPlayer(String teamId, Map<String, dynamic> data) async {
    if (_isDisposed) return null;
    _setLoading(true);
    _error = null;

    try {
      final playerData = {...data, 'team_id': teamId};
      final newPlayerData = await _apiService.createPlayer(playerData);
      return Player.fromJson(newPlayerData);
    } catch (e, stackTrace) {
      debugPrint('Create player error: $e');
      debugPrint('Stack trace: $stackTrace');
      _error = _getErrorMessage(e);
      return null;
    } finally {
      if (!_isDisposed) _setLoading(false);
    }
  }

  // ==========================================
  // GENERAL TEAM METHODS (Dropdowns etc)
  // ==========================================

  Future<void> fetchTeams({bool forceRefresh = false}) async {
    if (_isDisposed) return;
    _setLoading(true);
    _error = null;

    try {
      // ApiService returns List<Map<String, dynamic>>
      final List<Map<String, dynamic>> rawData = await _apiService.getTeams(
        forceRefresh: forceRefresh,
      );

      if (_isDisposed) return;

      // Safe Parsing using Team.fromJson
      _teams = rawData.map<Team>((json) => Team.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Fetch teams error: $e');
      if (!_isDisposed) {
        _error = _getErrorMessage(e);
        _teams = [];
      }
    } finally {
      if (!_isDisposed) _setLoading(false);
    }
  }

  Future<List<Player>> getPlayers(String teamId) async {
    if (_isDisposed) return [];
    _setLoading(true);
    _error = null;
    try {
      final rawPlayers = await _apiService.getPlayers(teamId: teamId);
      final players = (rawPlayers).map((p) => Player.fromJson(p)).toList();
      return players;
    } catch (e) {
      _error = _getErrorMessage(e);
      return [];
    } finally {
      if (!_isDisposed) _setLoading(false);
    }
  }

  Team? getTeamById(String? teamId) {
    try {
      if (teamId == null || teamId.isEmpty || _teams.isEmpty) return null;
      // ✅ Robust comparison (String vs String)
      return _teams.firstWhere(
        (t) => t.id.toString() == teamId.toString(),
        orElse: () => throw StateError('Team not found'),
      );
    } catch (e) {
      return null;
    }
  }

  void setSelectedTeam(Team? team) {
    if (_isDisposed) return;
    if (_selectedTeam != team) {
      _selectedTeam = team;
      _safeNotifyListeners();
    }
  }

  void _setLoading(bool loading) {
    if (_isDisposed) return;
    if (_isLoading != loading) {
      _isLoading = loading;
      _safeNotifyListeners();
    }
  }

  void clearError() {
    if (_isDisposed) return;
    if (_error != null) {
      _error = null;
      _safeNotifyListeners();
    }
  }

  void clear() {
    if (_isDisposed) return;
    _teams = [];
    _myTeamData = null;
    _myTeamPlayers = [];
    _selectedTeam = null;
    _error = null;
    _safeNotifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _teams.clear();
    _myTeamPlayers.clear();
    super.dispose();
  }
}
