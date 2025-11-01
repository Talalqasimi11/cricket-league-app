import 'package:flutter/foundation.dart';
import '../../../models/match.dart';
import '../../../services/api_service.dart';

class MatchProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Match> _matches = [];
  Match? _selectedMatch;
  bool _isLoading = false;
  String? _error;
  String? _filterStatus;
  int? _filterTournamentId;

  // Getters
  List<Match> get matches => List.unmodifiable(_matches);
  Match? get selectedMatch => _selectedMatch;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get filterStatus => _filterStatus;
  int? get filterTournamentId => _filterTournamentId;

  // Fetch all matches
  Future<void> fetchMatches({String? status, int? tournamentId}) async {
    _setLoading(true);
    _error = null;
    _filterStatus = status;
    _filterTournamentId = tournamentId;

    try {
      _matches = await _apiService.getMatches(
        status: status,
        tournamentId: tournamentId,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Fetch matches error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Fetch single match details
  Future<void> fetchMatch(int id) async {
    _setLoading(true);
    _error = null;

    try {
      _selectedMatch = await _apiService.getMatch(id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Fetch match error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create match
  Future<Match?> createMatch(Map<String, dynamic> data) async {
    _setLoading(true);
    _error = null;

    try {
      final match = await _apiService.createMatch(data);
      _matches.insert(0, match);
      _selectedMatch = match;
      notifyListeners();
      return match;
    } catch (e) {
      _error = e.toString();
      debugPrint('Create match error: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update match
  Future<Match?> updateMatch(int id, Map<String, dynamic> data) async {
    _setLoading(true);
    _error = null;

    try {
      final updatedMatch = await _apiService.updateMatch(id, data);
      final index = _matches.indexWhere((m) => m.id == id);
      if (index >= 0) {
        _matches[index] = updatedMatch;
      }
      if (_selectedMatch?.id == id) {
        _selectedMatch = updatedMatch;
      }
      notifyListeners();
      return updatedMatch;
    } catch (e) {
      _error = e.toString();
      debugPrint('Update match error: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Clear filters
  Future<void> clearFilters() async {
    await fetchMatches();
  }

  // Get matches by status
  List<Match> getMatchesByStatus(String status) {
    return _matches.where((m) => m.status == status).toList();
  }

  // Get upcoming matches
  List<Match> getUpcomingMatches() => getMatchesByStatus('scheduled');

  // Get live matches
  List<Match> getLiveMatches() => getMatchesByStatus('live');

  // Get completed matches
  List<Match> getCompletedMatches() => getMatchesByStatus('completed');

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void clear() {
    _matches = [];
    _selectedMatch = null;
    _error = null;
    _filterStatus = null;
    _filterTournamentId = null;
  }
}
