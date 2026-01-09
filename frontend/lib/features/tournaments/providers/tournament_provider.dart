import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import '../../../core/api_client.dart';
import '../../../core/retry_policy.dart';
import '../../../core/offline/offline_manager.dart';
import '../../../models/pending_operation.dart';
import '../../../models/team.dart';
import '../../../core/error_handler.dart';
import '../models/tournament_model.dart';

class TournamentProvider extends ChangeNotifier {
  final List<TournamentModel> _tournaments = [];
  bool _isLoading = false;
  String? _error;
  String _filter = 'all'; // all, active, upcoming, completed, mine
  int? _currentUserId;
  OfflineManager? _offlineManager;

  void setOfflineManager(OfflineManager manager) {
    _offlineManager = manager;
  }

  List<TournamentModel> get tournaments => List.unmodifiable(_tournaments);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filter => _filter;

  bool canEdit(TournamentModel tournament) =>
      _currentUserId != null &&
      tournament.createdBy == _currentUserId.toString();

  List<TournamentModel> get filteredTournaments {
    switch (_filter) {
      case 'active':
        // [CHANGED] 'Live' section now includes both active and upcoming
        return _tournaments.where((t) => t.isActive || t.isUpcoming).toList();
      case 'upcoming':
        return _tournaments.where((t) => t.isUpcoming).toList();
      case 'completed':
        return _tournaments.where((t) => t.isCompleted).toList();
      case 'mine':
        if (_currentUserId != null) {
          return _tournaments
              .where((t) => t.createdBy == _currentUserId.toString())
              .toList();
        }
        return [];
      default:
        return _tournaments;
    }
  }

  void setFilter(String filter) {
    if (_filter != filter) {
      _filter = filter;
      notifyListeners();
    }
  }

  void setCurrentUserId(int? userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      notifyListeners();
    }
  }

  Future<void> fetchTournaments({bool forceRefresh = false}) async {
    if (_isLoading) return;
    _setLoading(true);
    _error = null;

    try {
      final response = await RetryPolicy.execute(
        apiCall: () => ApiClient.instance.get(
          '/api/tournaments',
          forceRefresh: forceRefresh,
        ),
      );

      final decoded = jsonDecode(response.body);
      List<dynamic> data =
          decoded is Map<String, dynamic> && decoded.containsKey('data')
          ? decoded['data'] as List<dynamic>
          : (decoded as List<dynamic>);

      _tournaments.clear();
      _tournaments.addAll(
        data.map((json) => TournamentModel.fromJson(json)).toList(),
      );

      notifyListeners();
    } catch (e) {
      _handleError(e, 'Failed to load tournaments');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createTournament(Map<String, dynamic> data) async {
    return _sendTournamentRequest(
      apiCall: () => ApiClient.instance.post('/api/tournaments', body: data),
      offlineOperationType: OperationType.create,
      entityData: data,
      errorMessage: 'Failed to create tournament',
    );
  }

  Future<bool> updateTournament(String id, Map<String, dynamic> data) async {
    return _sendTournamentRequest(
      apiCall: () => ApiClient.instance.put('/api/tournaments/$id', body: data),
      offlineOperationType: OperationType.update,
      entityId: int.tryParse(id) ?? 0,
      entityData: data,
      errorMessage: 'Failed to update tournament',
    );
  }

  Future<bool> deleteTournament(String id) async {
    if (_isLoading) return false;
    _setLoading(true);
    _error = null;

    try {
      final response = await RetryPolicy.execute(
        apiCall: () => ApiClient.instance.delete('/api/tournaments/$id'),
      );

      if (response.statusCode == 200) {
        // Force refresh to clear cache and get updated list
        await fetchTournaments(forceRefresh: true);
        return true;
      } else {
        _error = _extractErrorMessage(response.body, response.statusCode);
        return false;
      }
    } catch (e) {
      _handleError(e, 'Failed to delete tournament');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Team>> fetchTournamentTeams(String tournamentId) async {
    try {
      final response = await RetryPolicy.execute(
        apiCall: () => ApiClient.instance.get(
          '/api/tournament-teams/$tournamentId',
          forceRefresh: true,
        ),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> data = [];

        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          data = decoded['data'];
        } else if (decoded is List) {
          data = decoded;
        }

        return data.map((json) {
          final map = json as Map<String, dynamic>;
          return Team(
            id: (map['team_id'] ?? map['id'])?.toString() ?? '',
            teamName: (map['team_name'] ?? map['temp_team_name']) ?? 'Unknown',
            location: map['team_location'] ?? map['temp_team_location'],
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching teams: $e');
    }
    return [];
  }

  Future<bool> registerTeam(
    String tournamentId,
    Map<String, dynamic> teamData,
  ) async {
    return _sendTournamentRequest(
      apiCall: () => ApiClient.instance.post(
        '/api/tournaments/$tournamentId/teams',
        body: teamData,
      ),
      entityData: teamData,
      errorMessage: 'Failed to register team',
      offlineOperationType: OperationType.update,
      entityId: int.tryParse(tournamentId),
    );
  }

  Future<bool> _sendTournamentRequest({
    required Future<Response> Function() apiCall,
    required Map<String, dynamic> entityData,
    required String errorMessage,
    OperationType? offlineOperationType,
    int? entityId,
  }) async {
    if (_isLoading) return false;
    _setLoading(true);
    _error = null;

    try {
      final response = await RetryPolicy.execute(apiCall: apiCall);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchTournaments(forceRefresh: true);
        return true;
      } else {
        _error = _extractErrorMessage(response.body, response.statusCode);
        return false;
      }
    } catch (e) {
      _handleError(e, errorMessage);

      // Offline Logic
      final isNetworkError =
          e.toString().contains('SocketException') ||
          e.toString().contains('ClientException') ||
          e.toString().contains('Connection refused');

      if (_offlineManager != null &&
          (!_offlineManager!.isOnline || isNetworkError) &&
          offlineOperationType != null) {
        try {
          await _offlineManager!.queueOperation(
            operationType: offlineOperationType,
            entityType: 'tournament',
            entityId: entityId ?? 0,
            data: entityData,
          );
          debugPrint('$errorMessage queued for offline sync');
          return true;
        } catch (queueError) {
          debugPrint('Error queuing operation: $queueError');
        }
      }
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

  void _handleError(Object e, String message) {
    if (e is SocketException) {
      _error =
          'No internet connection. Please check your network and try again.';
    } else if (e is ApiHttpException) {
      _error = e.message;
    } else {
      _error = message;
    }
    debugPrint('$message: $e');
    notifyListeners();
  }

  String _extractErrorMessage(String responseBody, int statusCode) {
    try {
      final data = jsonDecode(responseBody);
      if (data is Map<String, dynamic> && data.containsKey('error')) {
        return data['error'];
      }
    } catch (_) {}
    if (statusCode >= 500) return 'Server error. Please try again later.';
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Authentication failed. Please log in again.';
      case 403:
        return 'Access denied. You do not have permission.';
      case 404:
        return 'Resource not found.';
      default:
        return 'Operation failed (Status: $statusCode).';
    }
  }
}
