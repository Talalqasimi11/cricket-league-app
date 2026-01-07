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

  // Safe JSON decode helper
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

  // Helper method to parse response
  Future<T> _parseResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic data = _safeJsonDecode(response.body);

        if (data is! Map<String, dynamic>) {
          throw FormatException('Expected Map but got: ${data.runtimeType}');
        }

        return fromJson(data);
      } else {
        final errorBody = response.body.isNotEmpty
            ? response.body
            : 'No error details';
        throw Exception('HTTP ${response.statusCode}: $errorBody');
      }
    } catch (e, stackTrace) {
      debugPrint('Parse error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Helper method to parse list response
  Future<List<T>> _parseListResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic data = _safeJsonDecode(response.body);

        List<dynamic> items = [];

        if (data is List) {
          items = data;
        } else if (data is Map<String, dynamic>) {
          if (data['data'] is List) {
            items = data['data'] as List;
          } else if (data['items'] is List) {
            items = data['items'] as List;
          }
        }

        final results = <T>[];

        for (final item in items) {
          try {
            if (item is Map<String, dynamic>) {
              results.add(fromJson(item));
            } else {
              debugPrint('Invalid item type: ${item.runtimeType}');
            }
          } catch (e) {
            debugPrint('Error parsing individual item: $e');
            // Continue processing other items
          }
        }

        return results;
      } else {
        final errorBody = response.body.isNotEmpty
            ? response.body
            : 'No error details';
        throw Exception('HTTP ${response.statusCode}: $errorBody');
      }
    } catch (e, stackTrace) {
      debugPrint('Parse list error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
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
        final tournaments = <Tournament>[];

        for (final item in cached) {
          try {
            if (item is Map<String, dynamic>) {
              tournaments.add(Tournament.fromJson(item));
            }
          } catch (e) {
            debugPrint('Error parsing cached tournament: $e');
          }
        }

        if (tournaments.isNotEmpty) {
          return tournaments;
        }
      }

      final path = status != null
          ? '/api/tournaments?status=$status'
          : '/api/tournaments';

      final response = await _apiClient.get(
        path,
        cacheDuration: const Duration(minutes: 10),
      );

      final result = await _parseListResponse(response, Tournament.fromJson);

      // Cache the result - only cache valid data
      if (result.isNotEmpty) {
        try {
          await _cacheManager.set(
            cacheKey,
            result.map((t) => t.toJson()).toList(),
            memoryExpiry: const Duration(minutes: 5),
            persistentExpiry: const Duration(minutes: 10),
          );
        } catch (e) {
          debugPrint('Error caching tournaments: $e');
        }
      }

      return result;
    } catch (e, stackTrace) {
      debugPrint('Get tournaments error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Tournament> getTournament(String id) async {
    try {
      if (id.isEmpty) {
        throw Exception('Invalid tournament ID');
      }

      final response = await _apiClient.get('/api/tournaments/$id');
      return await _parseResponse(response, Tournament.fromJson);
    } catch (e, stackTrace) {
      debugPrint('Get tournament error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Tournament> createTournament(Map<String, dynamic> data) async {
    try {
      if (data.isEmpty) {
        throw Exception('Tournament data is required');
      }

      final response = await _apiClient.post('/api/tournaments', body: data);
      return await _parseResponse(response, Tournament.fromJson);
    } catch (e, stackTrace) {
      debugPrint('Create tournament error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Tournament> updateTournament(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      if (id.isEmpty) {
        throw Exception('Invalid tournament ID');
      }
      if (data.isEmpty) {
        throw Exception('Update data is required');
      }

      final response = await _apiClient.put('/api/tournaments/$id', body: data);
      return await _parseResponse(response, Tournament.fromJson);
    } catch (e, stackTrace) {
      debugPrint('Update tournament error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ====================== MATCH ENDPOINTS ======================

  Future<List<Match>> getAllTournamentMatches() async {
    try {
      final response = await _apiClient.get(
        '/api/tournament-matches',
        cacheDuration: const Duration(minutes: 2),
      );
      return await _parseListResponse(response, Match.fromTournamentMatch);
    } catch (e, stackTrace) {
      debugPrint('Get all tournament matches error: $e');
      debugPrint('Stack trace: $stackTrace');
      // Return empty list instead of throwing to allow partial data loading
      return [];
    }
  }

  Future<List<Match>> getTournamentMatches(String tournamentId) async {
    try {
      if (tournamentId.isEmpty) {
        throw Exception('Invalid tournament ID');
      }
      final response = await _apiClient.get(
        '/api/tournament-matches/$tournamentId',
        cacheDuration: const Duration(minutes: 2),
      );
      return await _parseListResponse(response, Match.fromTournamentMatch);
    } catch (e, stackTrace) {
      debugPrint('Get tournament matches error: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<List<Match>> getMatches({String? status, String? tournamentId}) async {
    try {
      // Try cache first
      final cacheKey = 'matches_${status}_$tournamentId';
      final cached = await _cacheManager.get<List>(cacheKey);

      if (cached != null) {
        debugPrint('Using cached matches');
        final matches = <Match>[];

        for (final item in cached) {
          try {
            if (item is Map<String, dynamic>) {
              matches.add(Match.fromJson(item));
            }
          } catch (e) {
            debugPrint('Error parsing cached match: $e');
          }
        }

        if (matches.isNotEmpty) {
          return matches;
        }
      }

      String path = '/api/matches';
      final params = <String>[];
      if (status != null && status.isNotEmpty) params.add('status=$status');
      if (tournamentId != null && tournamentId.isNotEmpty) {
        params.add('tournament_id=$tournamentId');
      }
      if (params.isNotEmpty) {
        path += '?${params.join("&")}';
      }

      final response = await _apiClient.get(
        path,
        cacheDuration: const Duration(seconds: 30),
      );

      final result = await _parseListResponse(response, Match.fromJson);

      // Cache the result
      if (result.isNotEmpty) {
        try {
          await _cacheManager.set(
            cacheKey,
            result.map((m) => m.toJson()).toList(),
            memoryExpiry: const Duration(minutes: 3),
            persistentExpiry: const Duration(minutes: 5),
          );
        } catch (e) {
          debugPrint('Error caching matches: $e');
        }
      }

      return result;
    } catch (e, stackTrace) {
      debugPrint('Get matches error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Match> getMatch(String id) async {
    try {
      if (id.isEmpty) {
        throw Exception('Invalid match ID');
      }

      final response = await _apiClient.get('/api/matches/$id');
      return await _parseResponse(response, Match.fromJson);
    } catch (e, stackTrace) {
      debugPrint('Get match error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Match> createMatch(Map<String, dynamic> data) async {
    try {
      if (data.isEmpty) {
        throw Exception('Match data is required');
      }

      final response = await _apiClient.post('/api/matches', body: data);
      return await _parseResponse(response, Match.fromJson);
    } catch (e, stackTrace) {
      debugPrint('Create match error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Match> updateMatch(String id, Map<String, dynamic> data) async {
    try {
      if (id.isEmpty) {
        throw Exception('Invalid match ID');
      }
      if (data.isEmpty) {
        throw Exception('Update data is required');
      }

      final response = await _apiClient.put('/api/matches/$id', body: data);
      return await _parseResponse(response, Match.fromJson);
    } catch (e, stackTrace) {
      debugPrint('Update match error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ====================== PLAYER MATCH STATS ENDPOINTS ======================

  Future<List<PlayerMatchStats>> getPlayerMatchStats(String matchId) async {
    try {
      if (matchId.isEmpty) {
        throw Exception('Invalid match ID');
      }

      final response = await _apiClient.get(
        '/api/player-match-stats?match_id=$matchId',
        cacheDuration: const Duration(minutes: 5),
      );
      return await _parseListResponse(response, PlayerMatchStats.fromJson);
    } catch (e, stackTrace) {
      debugPrint('Get player match stats error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<PlayerMatchStats> createPlayerMatchStats(
    Map<String, dynamic> data,
  ) async {
    try {
      if (data.isEmpty) {
        throw Exception('Player match stats data is required');
      }

      final response = await _apiClient.post(
        '/api/player-match-stats',
        body: data,
      );
      return await _parseResponse(response, PlayerMatchStats.fromJson);
    } catch (e, stackTrace) {
      debugPrint('Create player match stats error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ====================== TEAM TOURNAMENT SUMMARY ENDPOINTS ======================

  Future<List<TeamTournamentSummary>> getTeamTournamentSummary(
    String tournamentId,
  ) async {
    try {
      if (tournamentId.isEmpty) {
        throw Exception('Invalid tournament ID');
      }

      final response = await _apiClient.get(
        '/api/team-tournament-summary?tournament_id=$tournamentId',
        cacheDuration: const Duration(minutes: 10),
      );
      return await _parseListResponse(response, TeamTournamentSummary.fromJson);
    } catch (e, stackTrace) {
      debugPrint('Get team tournament summary error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ====================== UPLOAD ENDPOINTS ======================

  Future<String> uploadImage(dynamic file) async {
    try {
      // 'file' should be a dart:io File
      // We can't type it rigidly as File here due to conditional imports in some archs,
      // but assuming IO for this project.

      final uri = Uri.parse('${ApiClient.baseUrl}/api/uploads/temp');
      final request = http.MultipartRequest('POST', uri);

      // Add headers (Auth)
      final token = await _apiClient.token;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add file
      // Assuming 'file' has 'path' property
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = _safeJsonDecode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('imageUrl')) {
          return data['imageUrl'];
        }
        throw Exception('Invalid upload response format');
      }
      throw Exception('Upload failed: ${response.statusCode}');
    } catch (e, stackTrace) {
      debugPrint('Upload image error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ====================== FEEDBACK ENDPOINTS ======================

  Future<Feedback> submitFeedback(Map<String, dynamic> data) async {
    try {
      if (data.isEmpty) {
        throw Exception('Feedback data is required');
      }

      final response = await _apiClient.post('/api/feedback', body: data);
      return await _parseResponse(response, Feedback.fromJson);
    } catch (e, stackTrace) {
      debugPrint('Submit feedback error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ====================== TEAM ENDPOINTS ======================

  Future<Map<String, dynamic>?> getMyTeam() async {
    try {
      final response = await _apiClient.get(
        '/api/teams/my-team',
        cacheDuration: const Duration(minutes: 10),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = _safeJsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          return data;
        }

        debugPrint('Unexpected data type: ${data.runtimeType}');
        return null;
      }

      throw Exception('HTTP ${response.statusCode}');
    } catch (e, stackTrace) {
      debugPrint('Get my team error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTeams({
    bool forceRefresh = false,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/teams',
        cacheDuration: const Duration(minutes: 10),
        forceRefresh: forceRefresh,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic data = _safeJsonDecode(response.body);

        List<dynamic> items = [];

        if (data is List) {
          items = data;
        } else if (data is Map<String, dynamic>) {
          if (data['data'] is List) {
            items = data['data'] as List;
          } else if (data['teams'] is List) {
            items = data['teams'] as List;
          }
        }

        final results = <Map<String, dynamic>>[];

        for (final item in items) {
          if (item is Map<String, dynamic>) {
            results.add(item);
          }
        }

        return results;
      }

      throw Exception('HTTP ${response.statusCode}');
    } catch (e, stackTrace) {
      debugPrint('Get teams error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> createTeam(Map<String, dynamic> data) async {
    try {
      if (data.isEmpty) {
        throw Exception('Team data is required');
      }

      final response = await _apiClient.post('/api/teams/my-team', body: data);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = _safeJsonDecode(response.body);

        if (responseData is Map<String, dynamic>) {
          return responseData;
        }

        debugPrint('Unexpected data type: ${responseData.runtimeType}');
        return null;
      }

      throw Exception('HTTP ${response.statusCode}');
    } catch (e, stackTrace) {
      debugPrint('Create team error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> updateTeam(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      if (id.isEmpty) {
        throw Exception('Invalid team ID');
      }
      if (data.isEmpty) {
        throw Exception('Update data is required');
      }

      final response = await _apiClient.put('/api/teams/$id', body: data);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = _safeJsonDecode(response.body);

        if (responseData is Map<String, dynamic>) {
          return responseData;
        }

        debugPrint('Unexpected data type: ${responseData.runtimeType}');
        return null;
      }

      throw Exception('HTTP ${response.statusCode}');
    } catch (e, stackTrace) {
      debugPrint('Update team error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<bool> deleteTeam(String id) async {
    try {
      if (id.isEmpty) {
        throw Exception('Invalid team ID');
      }

      final response = await _apiClient.delete('/api/teams/$id');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e, stackTrace) {
      debugPrint('Delete team error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ====================== PLAYER ENDPOINTS ======================

  Future<List<Map<String, dynamic>>> getPlayers({String? teamId}) async {
    try {
      final path = teamId != null && teamId.isNotEmpty
          ? '/api/players?team_id=$teamId'
          : '/api/players';

      final response = await _apiClient.get(
        path,
        cacheDuration: const Duration(minutes: 10),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic data = _safeJsonDecode(response.body);

        List<dynamic> items = [];

        if (data is List) {
          items = data;
        } else if (data is Map<String, dynamic> && data['data'] is List) {
          items = data['data'] as List;
        }

        final results = <Map<String, dynamic>>[];

        for (final item in items) {
          if (item is Map<String, dynamic>) {
            results.add(item);
          }
        }

        return results;
      }

      throw Exception('HTTP ${response.statusCode}');
    } catch (e, stackTrace) {
      debugPrint('Get players error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getPlayer(String id) async {
    try {
      if (id.isEmpty) {
        throw Exception('Invalid player ID');
      }

      final response = await _apiClient.get('/api/players/$id');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = _safeJsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          return data;
        }

        debugPrint('Unexpected data type: ${data.runtimeType}');
        return null;
      }

      throw Exception('HTTP ${response.statusCode}');
    } catch (e, stackTrace) {
      debugPrint('Get player error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createPlayer(Map<String, dynamic> data) async {
    try {
      if (data.isEmpty) {
        throw Exception('Player data is required');
      }

      final response = await _apiClient.post('/api/players', body: data);
      return await _parseResponse(response, (json) => json);
    } catch (e, stackTrace) {
      debugPrint('Create player error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ====================== TOURNAMENT TEAM ENDPOINTS ======================

  Future<List<Map<String, dynamic>>> getTournamentTeams(
    String tournamentId,
  ) async {
    try {
      if (tournamentId.isEmpty) {
        throw Exception('Invalid tournament ID');
      }

      final response = await _apiClient.get(
        '/api/tournament-teams?tournament_id=$tournamentId',
        cacheDuration: const Duration(minutes: 10),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic data = _safeJsonDecode(response.body);

        List<dynamic> items = [];

        if (data is List) {
          items = data;
        } else if (data is Map<String, dynamic> && data['data'] is List) {
          items = data['data'] as List;
        }

        final results = <Map<String, dynamic>>[];

        for (final item in items) {
          if (item is Map<String, dynamic>) {
            results.add(item);
          }
        }

        return results;
      }

      throw Exception('HTTP ${response.statusCode}');
    } catch (e, stackTrace) {
      debugPrint('Get tournament teams error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> registerTeamForTournament(
    String tournamentId,
    String teamId,
  ) async {
    try {
      if (tournamentId.isEmpty || teamId.isEmpty) {
        throw Exception('Invalid tournament or team ID');
      }

      final response = await _apiClient.post(
        '/api/tournament-teams',
        body: {'tournament_id': tournamentId, 'team_id': teamId},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = _safeJsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          return data;
        }

        debugPrint('Unexpected data type: ${data.runtimeType}');
        return null;
      }

      throw Exception('HTTP ${response.statusCode}');
    } catch (e, stackTrace) {
      debugPrint('Register team for tournament error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ====================== TOURNAMENT STATS ENDPOINTS ======================

  /// Get top scorers for a tournament
  Future<List<Map<String, dynamic>>> getTopScorers(String tournamentId) async {
    try {
      if (tournamentId.isEmpty) {
        throw Exception('Invalid tournament ID');
      }

      final response = await _apiClient.get(
        '/api/tournament-stats/$tournamentId/batting',
        cacheDuration: const Duration(minutes: 5),
      );
      return await _parseListResponse(response, (json) => json);
    } catch (e, stackTrace) {
      debugPrint('Get top scorers error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get top wicket takers for a tournament
  Future<List<Map<String, dynamic>>> getTopWicketTakers(
    String tournamentId,
  ) async {
    try {
      if (tournamentId.isEmpty) {
        throw Exception('Invalid tournament ID');
      }

      final response = await _apiClient.get(
        '/api/tournament-stats/$tournamentId/bowling',
        cacheDuration: const Duration(minutes: 5),
      );
      return await _parseListResponse(response, (json) => json);
    } catch (e, stackTrace) {
      debugPrint('Get top wicket takers error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get sixes leaderboard for a tournament
  Future<List<Map<String, dynamic>>> getSixesLeaderboard(
    String tournamentId,
  ) async {
    try {
      if (tournamentId.isEmpty) {
        throw Exception('Invalid tournament ID');
      }

      final response = await _apiClient.get(
        '/api/tournament-stats/$tournamentId/sixes',
        cacheDuration: const Duration(minutes: 5),
      );
      return await _parseListResponse(response, (json) => json);
    } catch (e, stackTrace) {
      debugPrint('Get sixes leaderboard error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get tournament summary
  Future<Map<String, dynamic>> getTournamentSummary(String tournamentId) async {
    try {
      if (tournamentId.isEmpty) {
        throw Exception('Invalid tournament ID');
      }

      final response = await _apiClient.get(
        '/api/tournament-stats/$tournamentId/summary',
        cacheDuration: const Duration(minutes: 5),
      );
      return await _parseResponse(response, (json) => json);
    } catch (e, stackTrace) {
      debugPrint('Get tournament summary error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ====================== IMAGE UPLOAD ENDPOINTS ======================

  /// Upload player photo
  Future<Map<String, dynamic>?> uploadPlayerPhoto(
    String playerId,
    dynamic imageFile,
  ) async {
    try {
      if (playerId.isEmpty) {
        throw Exception('Invalid player ID');
      }
      if (imageFile == null) {
        throw Exception('Image file is required');
      }

      final response = await _apiClient.uploadFile(
        '/api/uploads/player/$playerId',
        imageFile,
        fieldName: 'photo',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _safeJsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          return data;
        }

        debugPrint('Unexpected data type: ${data.runtimeType}');
        return null;
      }

      return null;
    } catch (e, stackTrace) {
      debugPrint('Upload player photo error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Upload team logo
  Future<Map<String, dynamic>?> uploadTeamLogo(
    String teamId,
    dynamic imageFile,
  ) async {
    try {
      if (teamId.isEmpty) {
        throw Exception('Invalid team ID');
      }
      if (imageFile == null) {
        throw Exception('Image file is required');
      }

      final response = await _apiClient.uploadFile(
        '/api/uploads/team/$teamId',
        imageFile,
        fieldName: 'logo',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _safeJsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          return data;
        }

        debugPrint('Unexpected data type: ${data.runtimeType}');
        return null;
      }

      return null;
    } catch (e, stackTrace) {
      debugPrint('Upload team logo error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Delete player or team image
  Future<bool> deleteImage(String type, String id) async {
    try {
      if (type.isEmpty || id.isEmpty) {
        throw Exception('Invalid type or ID');
      }

      final response = await _apiClient.delete('/api/uploads/$type/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e, stackTrace) {
      debugPrint('Delete image error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get image URL for display
  String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';

    // If already a full URL, return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // Construct full URL from relative path
    final baseUrl = ApiClient.baseUrl;
    final normalizedPath = imagePath.startsWith('/')
        ? imagePath
        : '/$imagePath';

    // Remove trailing slash from base if present (though ApiClient normalizes it)
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    return '$normalizedBase$normalizedPath';
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      await _cacheManager.clearAll();
      debugPrint('Cache cleared successfully');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Clear specific cache entry
  Future<void> clearCacheEntry(String key) async {
    try {
      await _cacheManager.remove(key);
      debugPrint('Cache entry cleared: $key');
    } catch (e) {
      debugPrint('Error clearing cache entry: $e');
    }
  }
}
