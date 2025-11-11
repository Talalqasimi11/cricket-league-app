import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/api_client.dart';
import '../../../core/retry_policy.dart';
import '../../../core/offline/offline_manager.dart';
import '../../../models/pending_operation.dart';
import '../models/tournament_model.dart';

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
  final String? createdBy; // User ID of the tournament creator

  Tournament({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.teamCount,
    required this.matchCount,
    this.createdBy,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] ?? 'upcoming';
    final normalizedStatus = TournamentStatus.fromString(rawStatus).toString();

    return Tournament(
      id: json['id'].toString(),
      name: json['tournament_name'] ?? json['name'] ?? '',
      description: json['description'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date'] ?? json['start_date']),
      status: normalizedStatus,
      teamCount: json['team_count'] ?? 0,
      matchCount: json['match_count'] ?? 0,
      createdBy: json['created_by']?.toString(),
    );
  }
}

/// Provider for managing tournament state
class TournamentProvider extends ChangeNotifier {
  final List<Tournament> _tournaments = [];
  bool _isLoading = false;
  String? _error;
  String _filter = 'all'; // all, active, upcoming, completed, mine
  int? _currentUserId;
  OfflineManager? _offlineManager;

  // Set offline manager
  void setOfflineManager(OfflineManager manager) {
    _offlineManager = manager;
  }

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
      case 'mine':
        // Filter tournaments created by the current user
        if (_currentUserId != null) {
          return _tournaments
              .where((t) => t.createdBy == _currentUserId.toString())
              .toList();
        }
        // If no user ID, return empty list
        return [];
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

  // Set current user ID for filtering
  void setCurrentUserId(int? userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
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

      final decoded = jsonDecode(response.body);
      List<dynamic> data = [];
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        data = decoded['data'] as List<dynamic>;
      } else if (decoded is List<dynamic>) {
        data = decoded;
      }

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

      // Queue for offline sync if offline manager is available
      if (_offlineManager != null && !_offlineManager!.isOnline) {
        try {
          await _offlineManager!.queueOperation(
            operationType: OperationType.create,
            entityType: 'tournament',
            entityId: 0, // Will be assigned by server
            data: tournamentData,
          );
          debugPrint('Tournament creation queued for offline sync');
          // Consider it successful for UI purposes
          return true;
        } catch (queueError) {
          debugPrint('Error queuing tournament creation: $queueError');
        }
      }

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

      // Queue for offline sync if offline manager is available
      if (_offlineManager != null && !_offlineManager!.isOnline) {
        try {
          await _offlineManager!.queueOperation(
            operationType: OperationType.update,
            entityType: 'tournament',
            entityId: int.parse(id),
            data: tournamentData,
          );
          debugPrint('Tournament update queued for offline sync');
          return true;
        } catch (queueError) {
          debugPrint('Error queuing tournament update: $queueError');
        }
      }

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
