import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../../../core/retry_policy.dart';
import '../../../models/team.dart';

/// State for tournament team registration
class TournamentTeamRegistrationState extends ChangeNotifier {
  final String tournamentId;
  
  final List<Team> _teams = [];
  final Set<String> _selectedTeamIds = {};
  bool _isLoading = false;
  bool _isAddingTeam = false;
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isDisposed = false;
  
  Future<void>? _fetchTeamsFuture;
  
  TournamentTeamRegistrationState(this.tournamentId) {
    if (tournamentId.isEmpty) {
      _error = 'Invalid tournament ID';
      debugPrint('TournamentTeamRegistrationState created with empty tournament ID');
    }
    
    _searchController.addListener(_onSearchChanged);
  }
  
  /// Initialize the provider (call this after construction)
  Future<void> initialize() async {
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
      debugPrint('Response body: $body');
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
        return List.from(_teams);
      }
      
      final query = _searchQuery.toLowerCase().trim();
      return _teams.where((team) {
        try {
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
      return _teams.where((team) => _selectedTeamIds.contains(team.id.toString())).toSet();
    } catch (e) {
      debugPrint('Error getting selected teams: $e');
      return {};
    }
  }
  
  bool get isLoading => _isLoading;
  bool get isAddingTeam => _isAddingTeam;
  String? get error => _error;
  TextEditingController get searchController => _searchController;
  Future<void>? get fetchTeamsFuture => _fetchTeamsFuture;
  String get searchQuery => _searchQuery;
  
  Future<void> fetchTeams() async {
    if (_isLoading || _isDisposed) return;
    
    _setLoading(true);
    _error = null;
    
    try {
      final response = await RetryPolicy.execute(
        apiCall: () => ApiClient.instance.get('/api/teams'),
      );
      
      if (_isDisposed) return;
      
      if (response.statusCode == 200) {
        final decoded = _safeJsonDecode(response.body);
        
        List<dynamic> data = [];
        
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('data')) {
            final dataValue = decoded['data'];
            if (dataValue is List) {
              data = dataValue;
            } else {
              debugPrint('Expected List in "data" but got: ${dataValue.runtimeType}');
            }
          }
        } else if (decoded is List) {
          data = decoded;
        } else {
          debugPrint('Unexpected response format: ${decoded.runtimeType}');
        }
        
        _teams.clear();
        
        for (final item in data) {
          try {
            if (item is Map<String, dynamic>) {
              final team = Team.fromJson(item);
              if (team.id.isNotEmpty && team.teamName.isNotEmpty) {
                _teams.add(team);
              }
            } else {
              debugPrint('Invalid team data type: ${item.runtimeType}');
            }
          } catch (e) {
            debugPrint('Error parsing individual team: $e');
          }
        }
        
        debugPrint('Successfully loaded ${_teams.length} teams');
      } else if (response.statusCode >= 500) {
        _error = 'Server error. Please try again later.';
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _error = 'Authentication failed. Please log in again.';
      } else {
        _error = 'Failed to load teams. Please try again.';
      }
    } catch (e, stackTrace) {
      if (_isDisposed) return;
      
      if (e is SocketException) {
        _error = 'No internet connection. Please check your network and try again.';
      } else {
        _error = 'Failed to load teams. Please try again.';
      }
      debugPrint('Error fetching teams: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }
  
  void toggleTeamSelection(Team team) {
    if (_isDisposed) return;
    
    try {
      if (team.id.isEmpty) {
        debugPrint('Cannot select team with empty ID');
        return;
      }
      
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
    
    if (tournamentId.isEmpty) {
      _error = 'Invalid tournament ID';
      _safeNotifyListeners();
      return false;
    }
    
    _setLoading(true);
    _error = null;
    
    try {
      final teamIds = List<String>.from(_selectedTeamIds);
      
      if (teamIds.isEmpty) {
        _error = 'No teams selected';
        return false;
      }
      
      final response = await RetryPolicy.execute(
        apiCall: () => ApiClient.instance.post(
          '/api/tournaments/$tournamentId/teams',
          body: {'team_ids': teamIds},
        ),
      );
      
      if (_isDisposed) return false;
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        _selectedTeamIds.clear();
        debugPrint('Successfully added ${teamIds.length} teams to tournament');
        return true;
      }
      
      try {
        final data = _safeJsonDecode(response.body);
        
        if (response.statusCode == 400) {
          _error = data is Map<String, dynamic>
              ? (data['error']?.toString() ?? 'Invalid team data')
              : 'Invalid team data';
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          _error = 'Authentication failed. Please log in again.';
        } else if (response.statusCode >= 500) {
          _error = 'Server error. Please try again later.';
        } else {
          _error = 'Failed to add teams (${response.statusCode})';
        }
      } catch (e) {
        debugPrint('Error parsing error response: $e');
        _error = 'Failed to add teams (${response.statusCode})';
      }
      
      return false;
    } catch (e, stackTrace) {
      if (_isDisposed) return false;
      
      if (e is SocketException) {
        _error = 'No internet connection. Please check your network and try again.';
      } else {
        _error = 'Failed to add teams. Please try again.';
      }
      debugPrint('Error adding teams to tournament: $e');
      debugPrint('Stack trace: $stackTrace');
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
    
    if (teamName.length < 2) {
      _error = 'Team name must be at least 2 characters';
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
        debugPrint('Successfully created temporary team: $teamName');
        return true;
      }
      
      try {
        final data = _safeJsonDecode(response.body);
        
        if (response.statusCode == 400) {
          _error = data is Map<String, dynamic>
              ? (data['error']?.toString() ?? 'Invalid team data')
              : 'Invalid team data';
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          _error = 'Authentication failed. Please log in again.';
        } else if (response.statusCode == 409) {
          _error = 'A team with this name already exists';
        } else if (response.statusCode >= 500) {
          _error = 'Server error. Please try again later.';
        } else {
          _error = 'Failed to create team (${response.statusCode})';
        }
      } catch (e) {
        debugPrint('Error parsing error response: $e');
        _error = 'Failed to create team (${response.statusCode})';
      }
      
      return false;
    } catch (e, stackTrace) {
      if (_isDisposed) return false;
      
      if (e is SocketException) {
        _error = 'No internet connection. Please check your network and try again.';
      } else {
        _error = 'Failed to create team. Please try again.';
      }
      debugPrint('Error creating team: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    } finally {
      if (!_isDisposed) {
        _setAddingTeam(false);
      }
    }
  }
  
  void clearError() {
    if (_isDisposed) return;
    
    try {
      if (_error != null) {
        _error = null;
        _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Error clearing error: $e');
    }
  }
  
  void _onSearchChanged() {
    if (_isDisposed) return;
    
    try {
      final newQuery = _searchController.text.trim();
      if (_searchQuery != newQuery) {
        _searchQuery = newQuery;
        _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling search change: $e');
    }
  }
  
  void _setLoading(bool loading) {
    if (_isDisposed) return;
    
    try {
      if (_isLoading != loading) {
        _isLoading = loading;
        _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Error setting loading state: $e');
    }
  }
  
  void _setAddingTeam(bool adding) {
    if (_isDisposed) return;
    
    try {
      if (_isAddingTeam != adding) {
        _isAddingTeam = adding;
        _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Error setting adding team state: $e');
    }
  }
  
  void clearSearch() {
    if (_isDisposed) return;
    
    try {
      _searchController.clear();
      _searchQuery = '';
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('Error clearing search: $e');
    }
  }
  
  void selectAllTeams() {
    if (_isDisposed) return;
    
    try {
      _selectedTeamIds.clear();
      for (final team in _teams) {
        if (team.id.isNotEmpty) {
          _selectedTeamIds.add(team.id.toString());
        }
      }
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('Error selecting all teams: $e');
    }
  }
  
  void clearSelection() {
    if (_isDisposed) return;
    
    try {
      if (_selectedTeamIds.isNotEmpty) {
        _selectedTeamIds.clear();
        _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Error clearing selection: $e');
    }
  }
  
  int get teamCount {
    try {
      return _teams.length;
    } catch (e) {
      debugPrint('Error getting team count: $e');
      return 0;
    }
  }
  
  int get selectedTeamCount {
    try {
      return _selectedTeamIds.length;
    } catch (e) {
      debugPrint('Error getting selected team count: $e');
      return 0;
    }
  }
  
  bool isTeamSelected(Team team) {
    try {
      if (team.id.isEmpty) return false;
      return _selectedTeamIds.contains(team.id.toString());
    } catch (e) {
      debugPrint('Error checking if team is selected: $e');
      return false;
    }
  }
  
  Future<void> refresh() async {
    await fetchTeams();
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    
    try {
      _searchController.removeListener(_onSearchChanged);
      _searchController.dispose();
    } catch (e) {
      debugPrint('Error disposing search controller: $e');
    }
    
    try {
      _teams.clear();
      _selectedTeamIds.clear();
    } catch (e) {
      debugPrint('Error clearing data on dispose: $e');
    }
    
    super.dispose();
  }
}
