// lib/features/tournaments/providers/tournament_team_registration_provider.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../../../core/retry_policy.dart';
import '../../../models/team.dart';

class TournamentTeamRegistrationProvider extends ChangeNotifier {
  // [Fixed] Made optional in constructor to allow Provider creation before ID is known
  String? tournamentId;

  final List<Team> _teams = [];
  final Set<String> _selectedTeamIds = {};
  bool _isLoading = false;
  bool _isAddingTeam = false;
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isDisposed = false;

  // Constructor
  TournamentTeamRegistrationProvider() {
    _searchController.addListener(_onSearchChanged);
  }

  // [Added] Method to set ID and init
  Future<void> init(String id) async {
    tournamentId = id;
    if (id.isEmpty) {
      _error = 'Invalid tournament ID';
      notifyListeners();
      return;
    }
    await fetchTeams();
  }

  dynamic _safeJsonDecode(String body) {
    try {
      if (body.isEmpty) {
        throw const FormatException('Empty response body');
      }
      return jsonDecode(body);
    } on FormatException catch (e) {
      debugPrint('JSON decode error: $e');
      throw FormatException('Invalid JSON response: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected decode error: $e');
      rethrow;
    }
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

  List<Team> get teams => List.unmodifiable(_teams);

  List<Team> get filteredTeams {
    try {
      if (_searchQuery.isEmpty) {
        return _teams
            .where((team) => !_registeredTeamIds.contains(team.id.toString()))
            .toList();
      }

      final query = _searchQuery.toLowerCase().trim();
      return _teams.where((team) {
        try {
          // [Added] Filter out already registered teams
          if (_registeredTeamIds.contains(team.id.toString())) {
            return false;
          }

          final teamName = team.teamName.toLowerCase();
          final location = team.location?.toLowerCase() ?? '';
          return teamName.contains(query) || location.contains(query);
        } catch (e) {
          debugPrint('Error filtering team: $e');
          return false;
        }
      }).toList();
    } catch (e) {
      debugPrint('Error filtering teams: $e');
      return List.from(_teams);
    }
  }

  Set<Team> get selectedTeams {
    try {
      return _teams
          .where((team) => _selectedTeamIds.contains(team.id.toString()))
          .toSet();
    } catch (e) {
      debugPrint('Error getting selected teams: $e');
      return {};
    }
  }

  bool get isLoading => _isLoading;
  bool get isAddingTeam => _isAddingTeam;
  String? get error => _error;
  TextEditingController get searchController => _searchController;
  String get searchQuery => _searchQuery;

  final Set<String> _registeredTeamIds = {};

  Future<void> fetchTeams() async {
    if (_isLoading || _isDisposed) return;

    _setLoading(true);
    _error = null;

    try {
      // 1. Fetch ALL teams
      debugPrint("🔍 Fetching teams from /api/teams...");
      final allTeamsResponse = await RetryPolicy.execute(
        apiCall: () => ApiClient.instance.get('/api/teams'),
      );

      // 2. Fetch REGISTERED teams for this tournament
      debugPrint(
        "🔍 Fetching registered teams for tournament $tournamentId...",
      );
      final registeredTeamsResponse = await RetryPolicy.execute(
        apiCall: () => ApiClient.instance.get(
          '/api/tournament-teams?tournament_id=$tournamentId',
        ),
      );

      if (_isDisposed) return;

      // Process Registered Teams
      _registeredTeamIds.clear();
      if (registeredTeamsResponse.statusCode == 200) {
        final decoded = _safeJsonDecode(registeredTeamsResponse.body);
        List<dynamic> data = [];
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          data = decoded['data'];
        }

        for (final item in data) {
          if (item is Map && item['team_id'] != null) {
            _registeredTeamIds.add(item['team_id'].toString());
          }
        }
      }

      // Process All Teams
      if (allTeamsResponse.statusCode == 200) {
        final decoded = _safeJsonDecode(allTeamsResponse.body);
        List<dynamic> data = [];

        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('data') && decoded['data'] is List) {
            data = decoded['data'];
          } else if (decoded.containsKey('teams') && decoded['teams'] is List) {
            data = decoded['teams'];
          } else if (decoded.containsKey('results') &&
              decoded['results'] is List) {
            data = decoded['results'];
          }
        } else if (decoded is List) {
          data = decoded;
        }

        _teams.clear();
        for (final item in data) {
          try {
            if (item is Map<String, dynamic>) {
              final team = Team.fromJson(item);
              if (team.id.toString().isNotEmpty) {
                _teams.add(team);
              }
            }
          } catch (e) {
            debugPrint('❌ Error parsing individual team: $e');
          }
        }
      } else {
        _error = 'Failed to load teams (${allTeamsResponse.statusCode})';
      }
    } catch (e) {
      if (_isDisposed) return;
      _error = e is SocketException
          ? 'No internet connection.'
          : 'Failed to load teams.';
      debugPrint('❌ Exception in fetchTeams: $e');
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  void toggleTeamSelection(Team team) {
    if (_isDisposed) return;

    try {
      if (team.id.isEmpty) return;

      if (_selectedTeamIds.contains(team.id.toString())) {
        _selectedTeamIds.remove(team.id.toString());
      } else {
        _selectedTeamIds.add(team.id.toString());
      }

      _safeNotifyListeners();
    } catch (e) {
      debugPrint('Error toggling team selection: $e');
    }
  }

  Future<bool> addSelectedTeams() async {
    if (_selectedTeamIds.isEmpty || _isLoading || _isDisposed) return false;

    if (tournamentId == null || tournamentId!.isEmpty) {
      _error = 'Invalid tournament ID';
      _safeNotifyListeners();
      return false;
    }

    _setLoading(true);
    _error = null;

    try {
      final teamIds = List<String>.from(_selectedTeamIds);

      final response = await RetryPolicy.execute(
        apiCall: () => ApiClient.instance.post(
          '/api/tournaments/$tournamentId/teams',
          body: {'team_ids': teamIds},
        ),
      );

      if (_isDisposed) return false;

      if (response.statusCode == 201 || response.statusCode == 200) {
        _selectedTeamIds.clear();
        return true;
      }

      try {
        final data = _safeJsonDecode(response.body);
        if (response.statusCode == 400) {
          _error = data is Map<String, dynamic>
              ? (data['error']?.toString() ?? 'Invalid team data')
              : 'Invalid team data';
        } else if (response.statusCode == 401) {
          _error = 'Session expired. Please login again.';
        } else {
          _error = 'Failed to add teams (${response.statusCode})';
        }
      } catch (e) {
        _error = 'Failed to add teams (${response.statusCode})';
      }

      return false;
    } catch (e) {
      if (_isDisposed) return false;
      _error = e is SocketException
          ? 'No internet connection.'
          : 'Failed to add teams.';
      debugPrint('Error adding teams: $e');
      return false;
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  Future<bool> addUnregisteredTeam(String name, String location) async {
    if (_isAddingTeam || _isDisposed) return false;

    final teamName = name.trim();
    final teamLocation = location.trim();

    if (teamName.isEmpty) {
      _error = 'Team name is required';
      _safeNotifyListeners();
      return false;
    }

    _setAddingTeam(true);
    _error = null;

    try {
      final response = await RetryPolicy.execute(
        apiCall: () => ApiClient.instance.post(
          '/api/teams',
          body: {
            'team_name': teamName,
            'team_location': teamLocation.isNotEmpty ? teamLocation : null,
            'is_temporary': true,
          },
        ),
      );

      if (_isDisposed) return false;

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchTeams();
        return true;
      }

      _error = 'Failed to create team (${response.statusCode})';
      return false;
    } catch (e) {
      if (_isDisposed) return false;
      _error = 'Failed to create team.';
      return false;
    } finally {
      if (!_isDisposed) {
        _setAddingTeam(false);
      }
    }
  }

  void clearError() {
    if (_isDisposed) return;
    if (_error != null) {
      _error = null;
      _safeNotifyListeners();
    }
  }

  void _onSearchChanged() {
    if (_isDisposed) return;
    final newQuery = _searchController.text.trim();
    if (_searchQuery != newQuery) {
      _searchQuery = newQuery;
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

  void _setAddingTeam(bool adding) {
    if (_isDisposed) return;
    if (_isAddingTeam != adding) {
      _isAddingTeam = adding;
      _safeNotifyListeners();
    }
  }

  void clearSelection() {
    if (_isDisposed) return;
    if (_selectedTeamIds.isNotEmpty) {
      _selectedTeamIds.clear();
      _safeNotifyListeners();
    }
  }

  int get teamCount => _teams.length;
  int get selectedTeamCount => _selectedTeamIds.length;

  bool isTeamSelected(Team team) {
    if (team.id.isEmpty) return false;
    return _selectedTeamIds.contains(team.id.toString());
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _teams.clear();
    _selectedTeamIds.clear();
    super.dispose();
  }
}
