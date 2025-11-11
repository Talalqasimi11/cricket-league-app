import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;
import '../core/api_client.dart';
import '../core/caching/cache_manager.dart';
import '../models/match.dart';
import '../models/tournament.dart';
import '../models/player_match_stats.dart';
import '../models/team_tournament_summary.dart';
import '../models/feedback.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  final ApiClient _apiClient = ApiClient.instance;
  final CacheManager _cacheManager = CacheManager.instance;

  // Helper method to parse response
  Future<T> _parseResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        return fromJson(data);
      } catch (e) {
        debugPrint('Parse error: $e');
        rethrow;
      }
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  // Helper method to parse list response
  Future<List<T>> _parseListResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final dynamic data = jsonDecode(response.body);
        if (data is List) {
          return data
              .map((item) => fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (data is Map<String, dynamic>) {
          final items = data['data'] as List?;
          if (items != null) {
            return items
                .map((item) => fromJson(item as Map<String, dynamic>))
                .toList();
          }
        }
        return [];
      } catch (e) {
        debugPrint('Parse list error: $e');
        rethrow;
      }
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  // ====================== TOURNAMENT ENDPOINTS ======================

  Future<List<Tournament>> getTournaments({String? status}) async {
    try {
      // Try cache first
      final cacheKey = 'tournaments_$status';
      final cached = await _cacheManager.get<List>(cacheKey);
      if (cached != null) {
        debugPrint('Using cached tournaments');
        return cached
            .map((item) => Tournament.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      final path = status != null
          ? '/api/tournaments?status=$status'
          : '/api/tournaments';
      final response = await _apiClient.get(
        path,
        cacheDuration: const Duration(minutes: 10),
      );
      final result = await _parseListResponse(response, Tournament.fromJson);

      // Cache the result
      await _cacheManager.set(
        cacheKey,
        result.map((t) => t.toJson()).toList(),
        memoryExpiry: const Duration(minutes: 5),
        persistentExpiry: const Duration(minutes: 10),
      );

      return result;
    } catch (e) {
      debugPrint('Get tournaments error: $e');
      rethrow;
    }
  }

  Future<Tournament> getTournament(int id) async {
    try {
      final response = await _apiClient.get('/api/tournaments/$id');
      return await _parseResponse(response, Tournament.fromJson);
    } catch (e) {
      debugPrint('Get tournament error: $e');
      rethrow;
    }
  }

  Future<Tournament> createTournament(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/api/tournaments', body: data);
      return await _parseResponse(response, Tournament.fromJson);
    } catch (e) {
      debugPrint('Create tournament error: $e');
      rethrow;
    }
  }

  Future<Tournament> updateTournament(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('/api/tournaments/$id', body: data);
      return await _parseResponse(response, Tournament.fromJson);
    } catch (e) {
      debugPrint('Update tournament error: $e');
      rethrow;
    }
  }

  // ====================== MATCH ENDPOINTS ======================

  Future<List<Match>> getMatches({String? status, int? tournamentId}) async {
    try {
      // Try cache first
      final cacheKey = 'matches_${status}_$tournamentId';
      final cached = await _cacheManager.get<List>(cacheKey);
      if (cached != null) {
        debugPrint('Using cached matches');
        return cached
            .map((item) => Match.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      String path = '/api/matches';
      final params = <String>[];
      if (status != null) params.add('status=$status');
      if (tournamentId != null) params.add('tournament_id=$tournamentId');
      if (params.isNotEmpty) {
        path += '?${params.join("&")}';
      }

      final response = await _apiClient.get(
        path,
        cacheDuration: const Duration(minutes: 5),
      );
      final result = await _parseListResponse(response, Match.fromJson);

      // Cache the result
      await _cacheManager.set(
        cacheKey,
        result.map((m) => m.toJson()).toList(),
        memoryExpiry: const Duration(minutes: 3),
        persistentExpiry: const Duration(minutes: 5),
      );

      return result;
    } catch (e) {
      debugPrint('Get matches error: $e');
      rethrow;
    }
  }

  Future<Match> getMatch(int id) async {
    try {
      final response = await _apiClient.get('/api/matches/$id');
      return await _parseResponse(response, Match.fromJson);
    } catch (e) {
      debugPrint('Get match error: $e');
      rethrow;
    }
  }

  Future<Match> createMatch(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/api/matches', body: data);
      return await _parseResponse(response, Match.fromJson);
    } catch (e) {
      debugPrint('Create match error: $e');
      rethrow;
    }
  }

  Future<Match> updateMatch(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('/api/matches/$id', body: data);
      return await _parseResponse(response, Match.fromJson);
    } catch (e) {
      debugPrint('Update match error: $e');
      rethrow;
    }
  }

  // ====================== PLAYER MATCH STATS ENDPOINTS ======================

  Future<List<PlayerMatchStats>> getPlayerMatchStats(int matchId) async {
    try {
      final response = await _apiClient.get(
        '/api/player-match-stats?match_id=$matchId',
        cacheDuration: const Duration(minutes: 5),
      );
      return await _parseListResponse(response, PlayerMatchStats.fromJson);
    } catch (e) {
      debugPrint('Get player match stats error: $e');
      rethrow;
    }
  }

  Future<PlayerMatchStats> createPlayerMatchStats(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.post(
        '/api/player-match-stats',
        body: data,
      );
      return await _parseResponse(response, PlayerMatchStats.fromJson);
    } catch (e) {
      debugPrint('Create player match stats error: $e');
      rethrow;
    }
  }

  // ====================== TEAM TOURNAMENT SUMMARY ENDPOINTS ======================

  Future<List<TeamTournamentSummary>> getTeamTournamentSummary(
    int tournamentId,
  ) async {
    try {
      final response = await _apiClient.get(
        '/api/team-tournament-summary?tournament_id=$tournamentId',
        cacheDuration: const Duration(minutes: 10),
      );
      return await _parseListResponse(response, TeamTournamentSummary.fromJson);
    } catch (e) {
      debugPrint('Get team tournament summary error: $e');
      rethrow;
    }
  }

  // ====================== FEEDBACK ENDPOINTS ======================

  Future<Feedback> submitFeedback(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/api/feedback', body: data);
      return await _parseResponse(response, Feedback.fromJson);
    } catch (e) {
      debugPrint('Submit feedback error: $e');
      rethrow;
    }
  }

  // ====================== TEAM ENDPOINTS ======================

  Future<dynamic> getMyTeam() async {
    try {
      final response = await _apiClient.get(
        '/api/teams/my-team',
        cacheDuration: const Duration(minutes: 10),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      debugPrint('Get my team error: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getTeams() async {
    try {
      final response = await _apiClient.get(
        '/api/teams',
        cacheDuration: const Duration(minutes: 10),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          return data['data'] as List;
        }
        return [];
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      debugPrint('Get teams error: $e');
      rethrow;
    }
  }

  Future<dynamic> createTeam(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/api/teams', body: data);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      debugPrint('Create team error: $e');
      rethrow;
    }
  }

  Future<dynamic> updateTeam(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('/api/teams/$id', body: data);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      debugPrint('Update team error: $e');
      rethrow;
    }
  }

  // ====================== PLAYER ENDPOINTS ======================

  Future<List<dynamic>> getPlayers({int? teamId}) async {
    try {
      final path = teamId != null
          ? '/api/players?team_id=$teamId'
          : '/api/players';
      final response = await _apiClient.get(
        path,
        cacheDuration: const Duration(minutes: 10),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          return data['data'] as List;
        }
        return [];
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      debugPrint('Get players error: $e');
      rethrow;
    }
  }

  Future<dynamic> getPlayer(int id) async {
    try {
      final response = await _apiClient.get('/api/players/$id');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      debugPrint('Get player error: $e');
      rethrow;
    }
  }

  // ====================== TOURNAMENT TEAM ENDPOINTS ======================

  Future<List<dynamic>> getTournamentTeams(int tournamentId) async {
    try {
      final response = await _apiClient.get(
        '/api/tournament-teams?tournament_id=$tournamentId',
        cacheDuration: const Duration(minutes: 10),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          return data['data'] as List;
        }
        return [];
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      debugPrint('Get tournament teams error: $e');
      rethrow;
    }
  }

  Future<dynamic> registerTeamForTournament(
    int tournamentId,
    int teamId,
  ) async {
    try {
      final response = await _apiClient.post(
        '/api/tournament-teams',
        body: {'tournament_id': tournamentId, 'team_id': teamId},
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      debugPrint('Register team for tournament error: $e');
      rethrow;
    }
  }

  // ====================== IMAGE UPLOAD ENDPOINTS ======================

  /// Delete player or team image
  Future<bool> deleteImage(String type, int id) async {
    try {
      final response = await _apiClient.delete('/api/uploads/$type/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Delete image error: $e');
      rethrow;
    }
  }

  /// Get image URL for display
  String getImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';
    // Construct full URL from relative path
    return imagePath;
  }
}
