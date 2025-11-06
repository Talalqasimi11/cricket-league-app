import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../../core/api_client.dart';
import '../../../core/retry_policy.dart';
import '../../../core/websocket_service.dart';

/// State for a live match
class LiveMatch {
  final String id;
  final String team1Name;
  final String team2Name;
  final int team1Score;
  final int team2Score;
  final int team1Wickets;
  final int team2Wickets;
  final double team1Overs;
  final double team2Overs;
  final String currentInnings;
  final String status;
  final String tournamentName;

  LiveMatch({
    required this.id,
    required this.team1Name,
    required this.team2Name,
    required this.team1Score,
    required this.team2Score,
    required this.team1Wickets,
    required this.team2Wickets,
    required this.team1Overs,
    required this.team2Overs,
    required this.currentInnings,
    required this.status,
    required this.tournamentName,
  });

  factory LiveMatch.fromJson(Map<String, dynamic> json) {
    return LiveMatch(
      id: json['id'].toString(),
      team1Name: json['team1_name'],
      team2Name: json['team2_name'],
      team1Score: json['team1_score'] ?? 0,
      team2Score: json['team2_score'] ?? 0,
      team1Wickets: json['team1_wickets'] ?? 0,
      team2Wickets: json['team2_wickets'] ?? 0,
      team1Overs: double.parse((json['team1_overs'] ?? '0.0').toString()),
      team2Overs: double.parse((json['team2_overs'] ?? '0.0').toString()),
      currentInnings: json['current_innings'] ?? 'First',
      status: json['status'] ?? 'Not Started',
      tournamentName: json['tournament_name'] ?? '',
    );
  }

  LiveMatch copyWith({
    String? id,
    String? team1Name,
    String? team2Name,
    int? team1Score,
    int? team2Score,
    int? team1Wickets,
    int? team2Wickets,
    double? team1Overs,
    double? team2Overs,
    String? currentInnings,
    String? status,
    String? tournamentName,
  }) {
    return LiveMatch(
      id: id ?? this.id,
      team1Name: team1Name ?? this.team1Name,
      team2Name: team2Name ?? this.team2Name,
      team1Score: team1Score ?? this.team1Score,
      team2Score: team2Score ?? this.team2Score,
      team1Wickets: team1Wickets ?? this.team1Wickets,
      team2Wickets: team2Wickets ?? this.team2Wickets,
      team1Overs: team1Overs ?? this.team1Overs,
      team2Overs: team2Overs ?? this.team2Overs,
      currentInnings: currentInnings ?? this.currentInnings,
      status: status ?? this.status,
      tournamentName: tournamentName ?? this.tournamentName,
    );
  }
}

/// Provider for managing live matches state
class LiveMatchProvider extends ChangeNotifier {
  final Map<String, LiveMatch> _matches = {};
  String? _selectedMatchId;
  bool _isLoading = false;
  String? _error;
  final WebSocketService _webSocketService = WebSocketService.instance;

  // Getters
  List<LiveMatch> get matches => List.unmodifiable(_matches.values);
  LiveMatch? get selectedMatch =>
      _selectedMatchId != null ? _matches[_selectedMatchId] : null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Constructor sets up WebSocket callbacks
  LiveMatchProvider() {
    _setupWebSocketCallbacks();
  }

  void _setupWebSocketCallbacks() {
    _webSocketService.onScoreUpdate = _handleScoreUpdate;
    _webSocketService.onInningsEnded = _handleInningsEnded;
    _webSocketService.onError = _handleWebSocketError;
    _webSocketService.onConnected = _handleWebSocketConnected;
    _webSocketService.onDisconnected = _handleWebSocketDisconnected;
  }

  // WebSocket callback handlers
  void _handleScoreUpdate(Map<String, dynamic> data) {
    final matchId = data['matchId']?.toString();
    if (matchId == null) return;

    _updateMatchScore(matchId, data);
  }

  void _handleInningsEnded(Map<String, dynamic> data) {
    final matchId = data['matchId']?.toString();
    if (matchId == null) return;

    _updateMatchStatus(matchId, {'status': 'Innings Ended'});
  }

  void _handleWebSocketError(String error) {
    _error = error;
    notifyListeners();
  }

  void _handleWebSocketConnected() {
    _error = null;
    notifyListeners();
  }

  void _handleWebSocketDisconnected() {
    // Handle disconnection - could implement polling fallback here
  }

  // Update match score from WebSocket message
  void _updateMatchScore(String matchId, Map<String, dynamic> data) {
    final match = _matches[matchId];
    if (match == null) return;

    _matches[matchId] = match.copyWith(
      team1Score: (data['team1_score'] as num?)?.toInt() ?? match.team1Score,
      team2Score: (data['team2_score'] as num?)?.toInt() ?? match.team2Score,
      team1Wickets:
          (data['team1_wickets'] as num?)?.toInt() ?? match.team1Wickets,
      team2Wickets:
          (data['team2_wickets'] as num?)?.toInt() ?? match.team2Wickets,
      team1Overs: (data['team1_overs'] as num?)?.toDouble() ?? match.team1Overs,
      team2Overs: (data['team2_overs'] as num?)?.toDouble() ?? match.team2Overs,
      currentInnings:
          (data['current_innings'] as String?) ?? match.currentInnings,
    );

    notifyListeners();
  }

  // Update match status from WebSocket message
  void _updateMatchStatus(String matchId, Map<String, dynamic> data) {
    final match = _matches[matchId];
    if (match == null) return;

    final newStatus = data['status'] as String?;
    if (newStatus != null) {
      _matches[matchId] = match.copyWith(status: newStatus);
      notifyListeners();
    }
  }

  // Handle match completion
  void _handleMatchComplete(String matchId, Map<String, dynamic> data) {
    final match = _matches[matchId];
    if (match == null) return;

    _matches[matchId] = match.copyWith(
      status: 'Completed',
      team1Score:
          (data['final_team1_score'] as num?)?.toInt() ?? match.team1Score,
      team2Score:
          (data['final_team2_score'] as num?)?.toInt() ?? match.team2Score,
    );

    notifyListeners();
  }

  // Fetch live matches with retry policy
  Future<void> fetchLiveMatches() async {
    if (_isLoading) return;

    _setLoading(true);
    _error = null;

    try {
      final response = await RetryPolicy.execute(
        apiCall: () => ApiClient.instance.get('/api/matches/live'),
      );

      final jsonData = jsonDecode(response.body) as List<dynamic>;

      // Update matches map
      _matches.clear();
      for (final matchData in jsonData) {
        if (matchData is Map<String, dynamic>) {
          final match = LiveMatch.fromJson(matchData);
          _matches[match.id] = match;
        }
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching live matches: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Select a match to watch
  Future<void> selectMatch(String matchId) async {
    if (_selectedMatchId == matchId) return;

    // Disconnect from previous match if any
    if (_selectedMatchId != null) {
      await _webSocketService.disconnect();
    }

    _selectedMatchId = matchId;
    notifyListeners();

    // Connect to new match WebSocket
    await _webSocketService.connect(matchId);
  }

  // Clear selected match
  Future<void> clearSelectedMatch() async {
    if (_selectedMatchId == null) return;

    await _webSocketService.disconnect();
    _selectedMatchId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    super.dispose();
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
}
