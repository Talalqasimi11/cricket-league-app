import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';
import '../../../models/team.dart';

class TeamProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Team> _teams = [];
  Team? _selectedTeam;
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _error;

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
  List<Team> get teams => List.unmodifiable(_teams);
  Team? get selectedTeam => _selectedTeam;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get team count
  int get teamCount => _teams.length;

  // Check if has teams
  bool get hasTeams => _teams.isNotEmpty;

  // Check if has selected team
  bool get hasSelectedTeam => _selectedTeam != null;

  // Fetch user's team
  Future<void> fetchMyTeam() async {
    if (_isDisposed) return;

    _setLoading(true);
    _error = null;

    try {
      final dynamic response = await _apiService.getMyTeam();

      if (_isDisposed) return;

      if (response == null) {
        _selectedTeam = null;
        _safeNotifyListeners();
        return;
      }

      // Parse response
      Map<String, dynamic>? teamData;

      if (response is Map<String, dynamic>) {
        if (response['team'] is Map<String, dynamic>) {
          teamData = response['team'] as Map<String, dynamic>;
        } else if (response.containsKey('id')) {
          teamData = response;
        }
      }

      if (teamData != null) {
        _selectedTeam = Team.fromJson(teamData);
      } else {
        _selectedTeam = null;
        _error = 'Invalid team data';
      }

      if (!_isDisposed) {
        _safeNotifyListeners();
      }
    } catch (e, stackTrace) {
      debugPrint('Fetch my team error: $e');
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

  // Fetch all teams
  Future<void> fetchTeams() async {
    if (_isDisposed) return;

    _setLoading(true);
    _error = null;

    try {
      final dynamic response = await _apiService.getTeams();

      if (_isDisposed) return;

      if (response == null) {
        _teams = [];
        _safeNotifyListeners();
        return;
      }

      // Parse response
      List<dynamic> rawTeams = [];
      
      if (response is List) {
        rawTeams = response;
      } else if (response is Map<String, dynamic>) {
        if (response['teams'] is List) {
          rawTeams = response['teams'] as List;
        } else if (response['data'] is List) {
          rawTeams = response['data'] as List;
        }
      }

      final parsedTeams = <Team>[];

      for (final teamData in rawTeams) {
        try {
          if (teamData is Map<String, dynamic>) {
            final team = Team.fromJson(teamData);
            if (team.id.isNotEmpty && team.teamName.isNotEmpty) {
              parsedTeams.add(team);
            } else {
              debugPrint('Skipping invalid team: ${teamData['id']}');
            }
          } else {
            debugPrint('Invalid team data type: ${teamData.runtimeType}');
          }
        } catch (e) {
          debugPrint('Error parsing team: $e');
          // Continue processing other teams
        }
      }

      if (!_isDisposed) {
        _teams = parsedTeams;
        _safeNotifyListeners();
      }
    } catch (e, stackTrace) {
      debugPrint('Fetch teams error: $e');
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

  // Create team
  Future<Team?> createTeam(Map<String, dynamic> data) async {
    if (_isDisposed) return null;

    // Validate input data
    if (data.isEmpty) {
      _error = 'Team data is required';
      _safeNotifyListeners();
      return null;
    }

    _setLoading(true);
    _error = null;

    try {
      final dynamic response = await _apiService.createTeam(data);

      if (_isDisposed) return null;

      if (response == null) {
        _error = 'Failed to create team';
        _safeNotifyListeners();
        return null;
      }

      // Parse response
      Map<String, dynamic>? teamData;

      if (response is Map<String, dynamic>) {
        if (response['team'] is Map<String, dynamic>) {
          teamData = response['team'] as Map<String, dynamic>;
        } else if (response.containsKey('id')) {
          teamData = response;
        }
      }

      if (teamData != null) {
        final team = Team.fromJson(teamData);
        
        if (!_isDisposed) {
          _teams.insert(0, team);
          _selectedTeam = team;
          _safeNotifyListeners();
        }
        
        return team;
      } else {
        _error = 'Invalid team data received';
        _safeNotifyListeners();
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Create team error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (!_isDisposed) {
        _error = _getErrorMessage(e);
        _safeNotifyListeners();
      }
      
      return null;
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  // Update team
  Future<Team?> updateTeam(String teamId, Map<String, dynamic> data) async {
    if (_isDisposed) return null;

    // Validate input
    if (teamId.isEmpty) {
      _error = 'Invalid team ID';
      _safeNotifyListeners();
      return null;
    }

    if (data.isEmpty) {
      _error = 'Update data is required';
      _safeNotifyListeners();
      return null;
    }

    _setLoading(true);
    _error = null;

    try {
      final dynamic response = await _apiService.updateTeam(teamId, data);

      if (_isDisposed) return null;

      if (response == null) {
        _error = 'Failed to update team';
        _safeNotifyListeners();
        return null;
      }

      // Parse response
      Map<String, dynamic>? teamData;

      if (response is Map<String, dynamic>) {
        if (response['team'] is Map<String, dynamic>) {
          teamData = response['team'] as Map<String, dynamic>;
        } else if (response.containsKey('id')) {
          teamData = response;
        }
      }

      if (teamData != null) {
        final updatedTeam = Team.fromJson(teamData);
        
        if (!_isDisposed) {
          // Update in list
          final index = _teams.indexWhere((t) => t.id == teamId);
          if (index >= 0 && index < _teams.length) {
            _teams[index] = updatedTeam;
          }
          
          // Update selected team if it's the same
          if (_selectedTeam?.id == teamId) {
            _selectedTeam = updatedTeam;
          }
          
          _safeNotifyListeners();
        }
        
        return updatedTeam;
      } else {
        _error = 'Invalid team data received';
        _safeNotifyListeners();
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Update team error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (!_isDisposed) {
        _error = _getErrorMessage(e);
        _safeNotifyListeners();
      }
      
      return null;
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  // Delete team
  Future<bool> deleteTeam(String teamId) async {
    if (_isDisposed) return false;

    if (teamId.isEmpty) {
      _error = 'Invalid team ID';
      _safeNotifyListeners();
      return false;
    }

    _setLoading(true);
    _error = null;

    try {
      await _apiService.deleteTeam(teamId);

      if (_isDisposed) return false;

      // Remove from list
      _teams.removeWhere((t) => t.id == teamId);
      
      // Clear selected team if it was deleted
      if (_selectedTeam?.id == teamId) {
        _selectedTeam = null;
      }
      
      if (!_isDisposed) {
        _safeNotifyListeners();
      }
      
      return true;
    } catch (e, stackTrace) {
      debugPrint('Delete team error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (!_isDisposed) {
        _error = _getErrorMessage(e);
        _safeNotifyListeners();
      }
      
      return false;
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  // Get team by ID
  Team? getTeamById(String teamId) {
    try {
      if (teamId.isEmpty || _teams.isEmpty) {
        return null;
      }

      return _teams.firstWhere(
        (t) => t.id == teamId,
        orElse: () => throw StateError('Team not found'),
      );
    } on StateError {
      debugPrint('Team not found with ID: $teamId');
      return null;
    } catch (e) {
      debugPrint('Error getting team by ID: $e');
      return null;
    }
  }

  // Search teams
  List<Team> searchTeams(String query) {
    try {
      if (query.isEmpty) return List.from(_teams);

      final lowerQuery = query.toLowerCase().trim();
      
      return _teams.where((team) {
        try {
          final name = team.teamName.toLowerCase();
          final location = team.location?.toLowerCase() ?? '';
          
          return name.contains(lowerQuery) || location.contains(lowerQuery);
        } catch (e) {
          debugPrint('Error searching team: $e');
          return false;
        }
      }).toList();
    } catch (e) {
      debugPrint('Error in searchTeams: $e');
      return [];
    }
  }

  // Get top teams by trophies
  List<Team> getTopTeams({int limit = 10}) {
    try {
      final sortedTeams = List<Team>.from(_teams);
      sortedTeams.sort((a, b) => b.trophies.compareTo(a.trophies));
      return sortedTeams.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting top teams: $e');
      return [];
    }
  }

  // Update team in list
  void updateTeamInList(Team team) {
    try {
      if (_isDisposed) return;

      final index = _teams.indexWhere((t) => t.id == team.id);
      
      if (index != -1 && index < _teams.length) {
        _teams[index] = team;
        
        // Update selected team if it's the same
        if (_selectedTeam?.id == team.id) {
          _selectedTeam = team;
        }
        
        _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating team in list: $e');
    }
  }

  // Add team to list
  void addTeamToList(Team team) {
    try {
      if (_isDisposed) return;

      // Check if team already exists
      final existingIndex = _teams.indexWhere((t) => t.id == team.id);
      
      if (existingIndex == -1) {
        _teams.add(team);
        _safeNotifyListeners();
      } else {
        debugPrint('Team already exists, updating instead');
        updateTeamInList(team);
      }
    } catch (e) {
      debugPrint('Error adding team to list: $e');
    }
  }

  // Remove team from list
  void removeTeamFromList(String teamId) {
    try {
      if (_isDisposed) return;

      final initialLength = _teams.length;
      _teams.removeWhere((t) => t.id == teamId);
      
      if (_teams.length != initialLength) {
        // Team was removed
        if (_selectedTeam?.id == teamId) {
          _selectedTeam = null;
        }
        
        _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Error removing team from list: $e');
    }
  }

  // Set selected team
  void setSelectedTeam(Team? team) {
    try {
      if (_isDisposed) return;

      if (_selectedTeam != team) {
        _selectedTeam = team;
        _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Error setting selected team: $e');
    }
  }

  // Clear selected team
  void clearSelectedTeam() {
    setSelectedTeam(null);
  }

  // Refresh teams
  Future<void> refresh() async {
    await fetchTeams();
  }

  // Refresh my team
  Future<void> refreshMyTeam() async {
    await fetchMyTeam();
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
      _teams = [];
      _selectedTeam = null;
      _error = null;
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
      _teams.clear();
    } catch (e) {
      debugPrint('Error clearing teams on dispose: $e');
    }

    super.dispose();
  }
}