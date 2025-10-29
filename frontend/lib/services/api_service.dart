import '../core/api_client.dart';

class ApiService {
  final ApiClient _client = ApiClient.instance;

  // Auth endpoints
  Future<String> login(String phoneNumber, String password) async {
    final resp = await _client.postJson(
      '/api/auth/login',
      body: {'phone_number': phoneNumber, 'password': password},
    );

    final token = resp['token']?.toString();
    if (token == null) throw Exception('No token received');

    await _client.setToken(token);
    return token;
  }

  Future<void> logout() async {
    await _client.postJson('/api/auth/logout');
    await _client.clearToken();
  }

  // Tournament endpoints
  Future<List<dynamic>> getTournaments() async {
    final resp = await _client.getJson('/api/tournaments');
    return resp['tournaments'] ?? [];
  }

  Future<Map<String, dynamic>> getTournamentDetails(int id) async {
    final resp = await _client.getJson('/api/tournaments/$id');
    return resp['tournament'] ?? {};
  }

  // Team endpoints
  Future<List<dynamic>> getTeams() async {
    final resp = await _client.getJson('/api/teams');
    return resp['teams'] ?? [];
  }

  Future<Map<String, dynamic>> getTeamDetails(int id) async {
    final resp = await _client.getJson('/api/teams/$id');
    return resp['team'] ?? {};
  }

  // Match endpoints
  Future<List<dynamic>> getLiveMatches() async {
    final resp = await _client.getJson('/api/matches/live');
    return resp['matches'] ?? [];
  }

  Future<Map<String, dynamic>> getMatchDetails(int id) async {
    final resp = await _client.getJson('/api/matches/$id');
    return resp['match'] ?? {};
  }

  // Scoring endpoints
  Future<void> recordBall(int matchId, Map<String, dynamic> ballData) async {
    await _client.postJson('/api/live-score/ball/$matchId', body: ballData);
  }

  Future<void> endInnings(int matchId, int inningsId) async {
    await _client.postJson('/api/live-score/end-innings/$matchId/$inningsId');
  }

  // Player endpoints
  Future<List<dynamic>> getPlayers(int teamId) async {
    final resp = await _client.getJson('/api/teams/$teamId/players');
    return resp['players'] ?? [];
  }

  Future<Map<String, dynamic>> getPlayerStats(int playerId) async {
    final resp = await _client.getJson('/api/players/$playerId/stats');
    return resp['stats'] ?? {};
  }
}
