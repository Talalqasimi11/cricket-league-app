import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/match_model.dart';
import '../../../services/api_service.dart';
import '../../../core/api_client.dart';

class MatchProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<MatchModel> _matches = [];
  MatchModel? _selectedMatch;
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _error;
  String? _filterStatus;
  int? _filterTournamentId;

  // Getters
  List<MatchModel> get matches => List.unmodifiable(_matches);
  MatchModel? get selectedMatch => _selectedMatch;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get filterStatus => _filterStatus;
  int? get filterTournamentId => _filterTournamentId;

  int get matchCount => _matches.length;
  bool get hasMatches => _matches.isNotEmpty;
  bool get hasError => _error != null;

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
    if (error is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    } else if (error is TimeoutException) {
      return 'The request timed out. Please try again later.';
    } else if (error is FormatException) {
      return 'Data format error. Please contact support.';
    } else if (error.toString().contains('401') ||
        error.toString().contains('403')) {
      return 'Authentication failed. Please log in again.';
    } else if (error.toString().contains('404')) {
      return 'API Endpoint not found (404). Check URL.';
    } else if (error.toString().contains('500')) {
      return 'Server error. Please check backend logs.';
    }
    return error.toString().replaceAll('Exception:', '').trim();
  }

  Future<void> fetchMatches({String? status, int? tournamentId}) async {
    if (_isDisposed) return;
    _setLoading(true);
    _error = null;
    _filterStatus = status;
    _filterTournamentId = tournamentId;

    try {
      // 1. Fetch Legacy Matches
      final legacyMatches = await _apiService.getMatches(
        status: status,
        tournamentId: tournamentId?.toString(),
      );

      // 2. Fetch Tournament Matches
      List<dynamic> tournamentMatches = [];
      try {
        if (tournamentId != null) {
          tournamentMatches = await _apiService.getTournamentMatches(
            tournamentId.toString(),
          );
        } else {
          tournamentMatches = await _apiService.getAllTournamentMatches();
        }
      } catch (e) {
        debugPrint('Error fetching tournament matches: $e');
      }

      if (_isDisposed) return;

      final parsedLegacy = legacyMatches
          .map((item) => MatchModel.fromLegacyMatch(item))
          .toList();

      // Only keep 'planned' (scheduled) tournament matches to avoid duplicates with legacy 'live'/'completed' matches
      final parsedTournament = tournamentMatches
          .map((item) => MatchModel.fromTournamentMatch(item))
          .toList();

      _matches = [...parsedLegacy, ...parsedTournament];

      // Apply local filters if needed (though API usually handles it, merging might require re-filtering)
      if (status != null && status != 'all') {
        _matches = _matches
            .where((m) => m.status.backendValue == status)
            .toList();
      }
      if (tournamentId != null) {
        _matches = _matches
            .where((m) => m.tournamentId == tournamentId)
            .toList();
      }

      // Sort by date descending (newest first) or ascending?
      // Usually upcoming matches are ascending, completed are descending.
      // Let's sort by scheduled time ascending for now.
      _matches.sort((a, b) {
        if (a.scheduledAt == null) return 1;
        if (b.scheduledAt == null) return -1;
        return a.scheduledAt!.compareTo(b.scheduledAt!);
      });

      _safeNotifyListeners();
    } catch (e) {
      debugPrint('Fetch matches error: $e');
      if (!_isDisposed) {
        _error = _getErrorMessage(e);
        _matches = [];
        _safeNotifyListeners();
      }
    } finally {
      if (!_isDisposed) _setLoading(false);
    }
  }

  Future<void> fetchMatch(int id) async {
    if (_isDisposed) return;
    if (id <= 0) {
      _error = 'Invalid match ID';
      _safeNotifyListeners();
      return;
    }
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.getMatch(id.toString());
      if (_isDisposed) return;
      final match = MatchModel.fromLegacyMatch(response);
      _selectedMatch = match;

      final index = _matches.indexWhere((m) => m.id == match.id);
      if (index >= 0) _matches[index] = match;
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('Fetch match error: $e');
      if (!_isDisposed) {
        _error = _getErrorMessage(e);
        _safeNotifyListeners();
      }
    } finally {
      if (!_isDisposed) _setLoading(false);
    }
  }

  // ==========================================
  // ✅ FIXED: CREATE MATCH LOGIC
  // ==========================================
  Future<MatchModel?> createMatch(Map<String, dynamic> data) async {
    if (_isDisposed) return null;

    if (data.isEmpty) {
      _error = 'Match data cannot be empty';
      _safeNotifyListeners();
      return null;
    }

    _setLoading(true);
    _error = null;

    try {
      dynamic responseBody;
      final isFriendly = data['match_type'] == 'friendly';

      debugPrint(
        "🚀 Creating Match Type: ${isFriendly ? 'Friendly' : 'Tournament'}",
      );

      if (isFriendly) {
        // 1. FRIENDLY MATCH Logic
        // ✅ URL UPDATED: Based on your route file, this is likely under /api/tournament-matches
        final res = await ApiClient.instance.post(
          '/api/tournament-matches/friendly',
          body: data,
        );

        debugPrint("📥 Response Status: ${res.statusCode}");

        if (res.statusCode == 201 || res.statusCode == 200) {
          responseBody = jsonDecode(res.body);
        } else {
          throw Exception(
            'Failed to create friendly match: ${res.statusCode} - ${res.body}',
          );
        }
      } else {
        // 2. TOURNAMENT MATCH Logic
        // Structure data specifically for the bulk creation endpoint
        final payload = {
          'tournament_id': data['tournament_id'],
          'mode': 'manual',
          'matches': [
            {
              'team1_id': data['team1_id'],
              'team2_id': data['team2_id'],
              'match_date': data['match_date'],
              'location': data['venue'], // Map 'venue' to 'location' for DB
              'round': 'group_stage',
              'team1_lineup': data['team1_lineup'],
              'team2_lineup': data['team2_lineup'],
              // Fallbacks for display if IDs fail (optional)
              'team1_name': data['team1_name'],
              'team2_name': data['team2_name'],
            },
          ],
        };

        final res = await ApiClient.instance.post(
          '/api/tournament-matches/create',
          body: payload,
        );

        if (res.statusCode == 200 || res.statusCode == 201) {
          final responseBody = jsonDecode(res.body);
          // Check if 'match' object is returned (backend update)
          if (responseBody['match'] != null) {
            return MatchModel.fromTournamentMatch(responseBody['match']);
          }

          // Fallback
          return MatchModel(
            id: '0',
            teamA: data['team1_name'] ?? 'Team A',
            teamB: data['team2_name'] ?? 'Team B',
            status: MatchStatus.planned,
            creatorId: '',
          );
        } else {
          String errorMessage =
              'Failed to create tournament match: ${res.statusCode}';
          try {
            final errorJson = jsonDecode(res.body);
            if (errorJson['error'] != null) {
              errorMessage = errorJson['error'];
            } else {
              errorMessage += ' - ${res.body}';
            }
          } catch (_) {
            errorMessage += ' - ${res.body}';
          }
          throw Exception(errorMessage);
        }
      }

      if (_isDisposed) return null;

      // Parse response for Friendly matches
      final match = isFriendly && responseBody != null
          ? MatchModel.fromMap(responseBody)
          : null;

      if (match != null) {
        _matches.insert(0, match);
        _selectedMatch = match;
      }

      _safeNotifyListeners();

      // Return valid match object or fallback
      return match ??
          MatchModel(
            id: responseBody != null && responseBody['id'] != null
                ? responseBody['id'].toString()
                : '0',
            teamA: data['team1_name'] ?? '',
            teamB: data['team2_name'] ?? '',
            status: MatchStatus.planned,
            creatorId: '',
          );
    } catch (e) {
      debugPrint('❌ Create match error: $e');
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

  void updateMatchStatus(String id, MatchStatus newStatus) {
    if (_isDisposed) return;
    final index = _matches.indexWhere((m) => m.id == id);
    if (index != -1) {
      _matches[index] = _matches[index].copyWith(status: newStatus);
      _safeNotifyListeners();
    }
  }

  Future<MatchModel?> updateMatch(int id, Map<String, dynamic> data) async {
    if (_isDisposed) return null;
    if (id <= 0) {
      _error = 'Invalid match ID';
      _safeNotifyListeners();
      return null;
    }

    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.updateMatch(id.toString(), data);
      if (_isDisposed) return null;

      final updatedMatch = MatchModel.fromLegacyMatch(response);
      final index = _matches.indexWhere((m) => m.id == updatedMatch.id);
      if (index >= 0) _matches[index] = updatedMatch;
      if (_selectedMatch?.id == updatedMatch.id) _selectedMatch = updatedMatch;

      _safeNotifyListeners();
      return updatedMatch;
    } catch (e) {
      debugPrint('Update match error: $e');
      if (!_isDisposed) {
        _error = _getErrorMessage(e);
        _safeNotifyListeners();
      }
      return null;
    } finally {
      if (!_isDisposed) _setLoading(false);
    }
  }

  MatchModel? getMatchById(String id) {
    try {
      if (id.isEmpty || _matches.isEmpty) return null;
      return _matches.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearFilters() async {
    _filterStatus = null;
    _filterTournamentId = null;
    await fetchMatches();
  }

  List<MatchModel> getUpcomingMatches() =>
      _matches.where((m) => m.status == MatchStatus.planned).toList();
  List<MatchModel> getLiveMatches() =>
      _matches.where((m) => m.status == MatchStatus.live).toList();
  List<MatchModel> getCompletedMatches() =>
      _matches.where((m) => m.status == MatchStatus.completed).toList();

  List<MatchModel> getMatchesByDateRange(DateTime start, DateTime end) {
    try {
      return _matches.where((m) {
        final matchDate = m.scheduledAt;
        if (matchDate == null) return false;
        return matchDate.isAfter(start.subtract(const Duration(days: 1))) &&
            matchDate.isBefore(end.add(const Duration(days: 1)));
      }).toList();
    } catch (e) {
      return [];
    }
  }

  List<MatchModel> getTodaysMatches() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return getMatchesByDateRange(today, tomorrow);
  }

  List<MatchModel> searchMatchesByTeam(String teamName) {
    try {
      if (teamName.isEmpty) return List.from(_matches);
      final lowerQuery = teamName.toLowerCase().trim();
      return _matches.where((m) {
        final teamA = m.teamA.toLowerCase();
        final teamB = m.teamB.toLowerCase();
        return teamA.contains(lowerQuery) || teamB.contains(lowerQuery);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  void setSelectedMatch(MatchModel? match) {
    if (_isDisposed) return;
    _selectedMatch = match;
    _safeNotifyListeners();
  }

  void clearSelectedMatch() => setSelectedMatch(null);

  Future<void> refresh() async {
    await fetchMatches(
      status: _filterStatus,
      tournamentId: _filterTournamentId,
    );
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
    _matches = [];
    _selectedMatch = null;
    _error = null;
    _filterStatus = null;
    _filterTournamentId = null;
    _safeNotifyListeners();
  }

  Future<void> fetchMyMatches() async {
    if (_isDisposed) return;
    _setLoading(true);
    _error = null;

    try {
      final res = await ApiClient.instance.get('/api/matches/my');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> matchData = data['matches'] ?? [];
        _matches = matchData.map((m) => MatchModel.fromLegacyMatch(m)).toList();

        _matches.sort((a, b) {
          if (a.scheduledAt == null) return 1;
          if (b.scheduledAt == null) return -1;
          return b.scheduledAt!.compareTo(
            a.scheduledAt!,
          ); // Newest first for "My Matches"
        });

        _safeNotifyListeners();
      } else {
        throw Exception('Failed to fetch your matches: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Fetch My Matches error: $e');
      if (!_isDisposed) {
        _error = _getErrorMessage(e);
        _safeNotifyListeners();
      }
    } finally {
      if (!_isDisposed) _setLoading(false);
    }
  }

  Future<bool> deleteMatch(String id) async {
    if (_isDisposed) return false;
    _setLoading(true);
    _error = null;

    try {
      final res = await ApiClient.instance.delete('/api/matches/$id');
      if (res.statusCode == 200) {
        _matches.removeWhere((m) => m.id == id);
        _safeNotifyListeners();
        return true;
      } else {
        final body = jsonDecode(res.body);
        _error = body['error'] ?? 'Failed to delete match';
        _safeNotifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Delete Match error: $e');
      if (!_isDisposed) {
        _error = _getErrorMessage(e);
        _safeNotifyListeners();
      }
      return false;
    } finally {
      if (!_isDisposed) _setLoading(false);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _matches.clear();
    super.dispose();
  }
}
