import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';

class TournamentStatsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // State
  bool _isLoading = false;
  String? _error;
  
  // Data
  List<Map<String, dynamic>> _topScorers = [];
  List<Map<String, dynamic>> _topBowlers = [];
  List<Map<String, dynamic>> _sixesLeaderboard = [];
  Map<String, dynamic> _summary = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get topScorers => _topScorers;
  List<Map<String, dynamic>> get topBowlers => _topBowlers;
  List<Map<String, dynamic>> get sixesLeaderboard => _sixesLeaderboard;
  Map<String, dynamic> get summary => _summary;

  bool get hasData => _topScorers.isNotEmpty || _topBowlers.isNotEmpty || _summary.isNotEmpty;

  /// Fetch all stats for a tournament
  Future<void> fetchTournamentStats(String tournamentId, {bool forceRefresh = false}) async {
    // If we already have data and aren't forcing a refresh, return silently (cache strategy)
    if (hasData && !forceRefresh) return;

    _isLoading = true;
    _error = null;
    // Notify listeners immediately so UI shows loading skeleton
    notifyListeners();

    try {
      // Fetch all data in parallel for performance
      final results = await Future.wait([
        _apiService.getTopScorers(tournamentId),
        _apiService.getTopWicketTakers(tournamentId),
        _apiService.getSixesLeaderboard(tournamentId),
        _apiService.getTournamentSummary(tournamentId),
      ]);

      _topScorers = results[0] as List<Map<String, dynamic>>;
      _topBowlers = results[1] as List<Map<String, dynamic>>;
      _sixesLeaderboard = results[2] as List<Map<String, dynamic>>;
      _summary = results[3] as Map<String, dynamic>;

    } catch (e) {
      _error = 'Failed to load tournament statistics';
      debugPrint('TournamentStatsProvider Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear stats when leaving a tournament screen
  void clear() {
    _topScorers = [];
    _topBowlers = [];
    _sixesLeaderboard = [];
    _summary = {};
    _error = null;
    _isLoading = false;
    // No notifyListeners() needed here usually, unless UI is still active
  }
}