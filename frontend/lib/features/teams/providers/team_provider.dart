import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';

class TeamProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<dynamic> _teams = [];
  dynamic _selectedTeam;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<dynamic> get teams => List.unmodifiable(_teams);
  dynamic get selectedTeam => _selectedTeam;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch user's teams
  Future<void> fetchMyTeam() async {
    _setLoading(true);
    _error = null;

    try {
      _selectedTeam = await _apiService.getMyTeam();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Fetch my team error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Fetch all teams
  Future<void> fetchTeams() async {
    _setLoading(true);
    _error = null;

    try {
      _teams = await _apiService.getTeams();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Fetch teams error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create team
  Future<dynamic> createTeam(Map<String, dynamic> data) async {
    _setLoading(true);
    _error = null;

    try {
      final team = await _apiService.createTeam(data);
      _teams.insert(0, team);
      _selectedTeam = team;
      notifyListeners();
      return team;
    } catch (e) {
      _error = e.toString();
      debugPrint('Create team error: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update team
  Future<dynamic> updateTeam(int id, Map<String, dynamic> data) async {
    _setLoading(true);
    _error = null;

    try {
      final updatedTeam = await _apiService.updateTeam(id, data);
      final index = _teams.indexWhere((t) => t['id'] == id);
      if (index >= 0) {
        _teams[index] = updatedTeam;
      }
      if (_selectedTeam?['id'] == id) {
        _selectedTeam = updatedTeam;
      }
      notifyListeners();
      return updatedTeam;
    } catch (e) {
      _error = e.toString();
      debugPrint('Update team error: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Get team by ID
  dynamic getTeamById(int id) {
    try {
      return _teams.firstWhere((t) => t['id'] == id);
    } catch (e) {
      return null;
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void clear() {
    _teams = [];
    _selectedTeam = null;
    _error = null;
  }
}
