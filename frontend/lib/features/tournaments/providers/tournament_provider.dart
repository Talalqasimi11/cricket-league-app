import 'package:flutter/foundation.dart';
import '../../../core/api_client.dart';
import '../../../core/retry_policy.dart';

/// State for a tournament
class Tournament {
  final String id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final int teamCount;
  final int matchCount;

  Tournament({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.teamCount,
    required this.matchCount,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'].toString(),
      name: json['name'],
      description: json['description'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: json['status'],
      teamCount: json['team_count'] ?? 0,
      matchCount: json['match_count'] ?? 0,
    );
  }
}

/// Provider for managing tournament state
class TournamentProvider extends ChangeNotifier {
  final List<Tournament> _tournaments = [];
  bool _isLoading = false;
  String? _error;
  String _filter = 'all'; // all, active, upcoming, completed

  // Getters
  List<Tournament> get tournaments => List.unmodifiable(_tournaments);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filter => _filter;

  // Filtered tournaments
  List<Tournament> get filteredTournaments {
    switch (_filter) {
      case 'active':
        return _tournaments
            .where((t) => t.status.toLowerCase() == 'active')
            .toList();
      case 'upcoming':
        return _tournaments
            .where((t) => t.status.toLowerCase() == 'upcoming')
            .toList();
      case 'completed':
        return _tournaments
            .where((t) => t.status.toLowerCase() == 'completed')
            .toList();
      default:
        return _tournaments;
    }
  }

  // Set filter
  void setFilter(String filter) {
    if (_filter != filter) {
      _filter = filter;
      notifyListeners();
    }
  }

  // Fetch tournaments with retry policy
  Future<void> fetchTournaments() async {
    if (_isLoading) return;

    _setLoading(true);
    _error = null;

    try {
      final response = await RetryPolicy.execute(
        apiCall: () => ApiClient.instance.get('/api/tournaments'),
      );

      final List<dynamic> data = await response.body as List<dynamic>;
      _tournaments.clear();
      _tournaments.addAll(
        data.map((json) => Tournament.fromJson(json)).toList(),
      );

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching tournaments: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create tournament
  Future<bool> createTournament(Map<String, dynamic> tournamentData) async {
    if (_isLoading) return false;

    _setLoading(true);
    _error = null;

    try {
      final response = await RetryPolicy.execute(
        apiCall: () =>
            ApiClient.instance.post('/api/tournaments', body: tournamentData),
      );

      if (response.statusCode == 201) {
        await fetchTournaments(); // Refresh list
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating tournament: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update tournament
  Future<bool> updateTournament(
    String id,
    Map<String, dynamic> tournamentData,
  ) async {
    if (_isLoading) return false;

    _setLoading(true);
    _error = null;

    try {
      final response = await RetryPolicy.execute(
        apiCall: () => ApiClient.instance.put(
          '/api/tournaments/$id',
          body: tournamentData,
        ),
      );

      if (response.statusCode == 200) {
        await fetchTournaments(); // Refresh list
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating tournament: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete tournament
  Future<bool> deleteTournament(String id) async {
    if (_isLoading) return false;

    _setLoading(true);
    _error = null;

    try {
      final response = await RetryPolicy.execute(
        apiCall: () => ApiClient.instance.delete('/api/tournaments/$id'),
      );

      if (response.statusCode == 200) {
        _tournaments.removeWhere((t) => t.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting tournament: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
}
