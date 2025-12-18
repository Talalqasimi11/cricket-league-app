import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
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
  final DateTime? lastUpdated;

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
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory LiveMatch.fromJson(Map<String, dynamic> json) {
    try {
      return LiveMatch(
        id: json['id']?.toString() ?? '',
        team1Name: json['team1_name']?.toString() ?? 'Team 1',
        team2Name: json['team2_name']?.toString() ?? 'Team 2',
        team1Score: _safeInt(json['team1_score']),
        team2Score: _safeInt(json['team2_score']),
        team1Wickets: _safeInt(json['team1_wickets']),
        team2Wickets: _safeInt(json['team2_wickets']),
        team1Overs: _safeDouble(json['team1_overs']),
        team2Overs: _safeDouble(json['team2_overs']),
        currentInnings: json['current_innings']?.toString() ?? 'First',
        status: json['status']?.toString() ?? 'Not Started',
        tournamentName: json['tournament_name']?.toString() ?? '',
        lastUpdated: _parseDateTime(json['last_updated']),
      );
    } catch (e) {
      debugPrint('Error parsing LiveMatch: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team1_name': team1Name,
      'team2_name': team2Name,
      'team1_score': team1Score,
      'team2_score': team2Score,
      'team1_wickets': team1Wickets,
      'team2_wickets': team2Wickets,
      'team1_overs': team1Overs,
      'team2_overs': team2Overs,
      'current_innings': currentInnings,
      'status': status,
      'tournament_name': tournamentName,
      'last_updated': lastUpdated?.toIso8601String(),
    };
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
    DateTime? lastUpdated,
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
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  // Helper methods for parsing
  static int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // Utility getters
  bool get isLive => status.toLowerCase() == 'live';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isUpcoming => status.toLowerCase() == 'scheduled' || 
                         status.toLowerCase() == 'not started';
  
  String get team1ScoreDisplay => '$team1Score/$team1Wickets ($team1Overs)';
  String get team2ScoreDisplay => '$team2Score/$team2Wickets ($team2Overs)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiveMatch &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'LiveMatch{id: $id, $team1Name vs $team2Name, status: $status}';
  }
}

/// Connection state for WebSocket
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Provider for managing live matches state
class LiveMatchProvider extends ChangeNotifier {
  final Map<String, LiveMatch> _matches = {};
  String? _selectedMatchId;
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _error;
  ConnectionState _connectionState = ConnectionState.disconnected;
  
  final WebSocketService _webSocketService = WebSocketService.instance;
  
  // Polling fallback
  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 5);
  // [Fixed] Removed unused field '_usePolling'

  // Reconnection
  Timer? _reconnectionTimer;
  int _reconnectionAttempts = 0;
  static const int _maxReconnectionAttempts = 5;

  // Getters
  List<LiveMatch> get matches => List.unmodifiable(_matches.values);
  
  LiveMatch? get selectedMatch =>
      _selectedMatchId != null ? _matches[_selectedMatchId] : null;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  ConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == ConnectionState.connected;
  bool get hasMatches => _matches.isNotEmpty;
  int get matchCount => _matches.length;

  // Get matches by status
  List<LiveMatch> get liveMatches =>
      _matches.values.where((m) => m.isLive).toList();
  
  List<LiveMatch> get upcomingMatches =>
      _matches.values.where((m) => m.isUpcoming).toList();
  
  List<LiveMatch> get completedMatches =>
      _matches.values.where((m) => m.isCompleted).toList();

  // Constructor sets up WebSocket callbacks
  LiveMatchProvider() {
    _setupWebSocketCallbacks();
  }

  /// Safe notify listeners with disposal check
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      try {
        notifyListeners();
      } catch (e) {
        debugPrint('Error notifying listeners: $e');
      }
    }
  }

  /// Setup WebSocket event handlers
  void _setupWebSocketCallbacks() {
    try {
      _webSocketService.onScoreUpdate = _handleScoreUpdate;
      _webSocketService.onInningsEnded = _handleInningsEnded;
      _webSocketService.onError = _handleWebSocketError;
      _webSocketService.onConnected = _handleWebSocketConnected;
      _webSocketService.onDisconnected = _handleWebSocketDisconnected;
    } catch (e) {
      debugPrint('Error setting up WebSocket callbacks: $e');
    }
  }

  // ==================== WebSocket Handlers ====================

  /// Handle score update from WebSocket
  void _handleScoreUpdate(Map<String, dynamic> data) {
    try {
      final matchId = data['matchId']?.toString();
      if (matchId == null || matchId.isEmpty) {
        debugPrint('Invalid matchId in score update');
        return;
      }

      _updateMatchScore(matchId, data);
      _reconnectionAttempts = 0; // Reset on successful update
    } catch (e) {
      debugPrint('Error handling score update: $e');
    }
  }

  /// Handle innings ended event
  void _handleInningsEnded(Map<String, dynamic> data) {
    try {
      final matchId = data['matchId']?.toString();
      if (matchId == null || matchId.isEmpty) {
        debugPrint('Invalid matchId in innings ended event');
        return;
      }

      _updateMatchStatus(matchId, {'status': 'Innings Ended'});
    } catch (e) {
      debugPrint('Error handling innings ended: $e');
    }
  }

  /// Handle WebSocket error
  void _handleWebSocketError(String error) {
    try {
      if (_isDisposed) return;

      _error = error;
      _connectionState = ConnectionState.error;
      debugPrint('WebSocket error: $error');

      // Fallback to polling
      _startPollingFallback();
      
      // Try reconnection
      _scheduleReconnection();

      _safeNotifyListeners();
    } catch (e) {
      debugPrint('Error handling WebSocket error: $e');
    }
  }

  /// Handle WebSocket connected
  void _handleWebSocketConnected() {
    try {
      if (_isDisposed) return;

      _error = null;
      _connectionState = ConnectionState.connected;
      _reconnectionAttempts = 0;
      
      // Stop polling if active
      _stopPolling();

      debugPrint('WebSocket connected successfully');
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('Error handling WebSocket connected: $e');
    }
  }

  /// Handle WebSocket disconnected
  void _handleWebSocketDisconnected() {
    try {
      if (_isDisposed) return;

      _connectionState = ConnectionState.disconnected;
      debugPrint('WebSocket disconnected');

      // Start polling fallback
      _startPollingFallback();
      
      // Try reconnection
      _scheduleReconnection();

      _safeNotifyListeners();
    } catch (e) {
      debugPrint('Error handling WebSocket disconnected: $e');
    }
  }

  // ==================== Data Updates ====================

  /// Update match score from WebSocket data
  void _updateMatchScore(String matchId, Map<String, dynamic> data) {
    try {
      final match = _matches[matchId];
      if (match == null) {
        debugPrint('Match not found for score update: $matchId');
        return;
      }

      _matches[matchId] = match.copyWith(
        team1Score: _extractInt(data, 'team1_score', match.team1Score),
        team2Score: _extractInt(data, 'team2_score', match.team2Score),
        team1Wickets: _extractInt(data, 'team1_wickets', match.team1Wickets),
        team2Wickets: _extractInt(data, 'team2_wickets', match.team2Wickets),
        team1Overs: _extractDouble(data, 'team1_overs', match.team1Overs),
        team2Overs: _extractDouble(data, 'team2_overs', match.team2Overs),
        currentInnings: data['current_innings']?.toString() ?? match.currentInnings,
        lastUpdated: DateTime.now(),
      );

      _safeNotifyListeners();
    } catch (e) {
      debugPrint('Error updating match score: $e');
    }
  }

  /// Update match status
  void _updateMatchStatus(String matchId, Map<String, dynamic> data) {
    try {
      final match = _matches[matchId];
      if (match == null) {
        debugPrint('Match not found for status update: $matchId');
        return;
      }

      final newStatus = data['status']?.toString();
      if (newStatus != null && newStatus.isNotEmpty) {
        _matches[matchId] = match.copyWith(
          status: newStatus,
          lastUpdated: DateTime.now(),
        );
        _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating match status: $e');
    }
  }

  // ==================== API Methods ====================

  /// Fetch live matches with retry policy
  Future<void> fetchLiveMatches() async {
    if (_isDisposed || _isLoading) return;

    _setLoading(true);
    _error = null;

    try {
      final response = await RetryPolicy.execute(
        apiCall: () => ApiClient.instance.get('/api/matches/live'),
      );

      if (_isDisposed) return;

      // Validate response
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch live matches: ${response.statusCode}');
      }

      final dynamic jsonData = jsonDecode(response.body);
      
      // Handle both array and object responses
      List<dynamic> matchesData = [];
      if (jsonData is List) {
        matchesData = jsonData;
      } else if (jsonData is Map<String, dynamic>) {
        if (jsonData['matches'] is List) {
          matchesData = jsonData['matches'] as List;
        } else if (jsonData['data'] is List) {
          matchesData = jsonData['data'] as List;
        }
      }

      // Update matches map
      final newMatches = <String, LiveMatch>{};
      
      for (final matchData in matchesData) {
        try {
          if (matchData is Map<String, dynamic>) {
            final match = LiveMatch.fromJson(matchData);
            if (match.id.isNotEmpty) {
              newMatches[match.id] = match;
            }
          }
        } catch (e) {
          debugPrint('Error parsing match data: $e');
          // Continue processing other matches
        }
      }

      if (!_isDisposed) {
        _matches.clear();
        _matches.addAll(newMatches);
        _safeNotifyListeners();
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching live matches: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (!_isDisposed) {
        _error = _getErrorMessage(e);
        _safeNotifyListeners();
      }
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  /// Fetch a specific live match
  Future<void> fetchLiveMatch(String matchId) async {
    if (_isDisposed || matchId.isEmpty) return;

    try {
      final response = await RetryPolicy.execute(
        apiCall: () => ApiClient.instance.get('/api/matches/$matchId/live'),
      );

      if (_isDisposed) return;

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch match: ${response.statusCode}');
      }

      final dynamic jsonData = jsonDecode(response.body);
      
      Map<String, dynamic>? matchData;
      if (jsonData is Map<String, dynamic>) {
        if (jsonData['match'] is Map<String, dynamic>) {
          matchData = jsonData['match'] as Map<String, dynamic>;
        } else if (jsonData.containsKey('id')) {
          matchData = jsonData;
        }
      }

      if (matchData != null) {
        final match = LiveMatch.fromJson(matchData);
        if (!_isDisposed) {
          _matches[match.id] = match;
          _safeNotifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching live match: $e');
    }
  }

  // ==================== Match Selection ====================

  /// Select a match to watch
  Future<void> selectMatch(String matchId) async {
    if (_isDisposed) return;

    try {
      if (matchId.isEmpty) {
        _error = 'Invalid match ID';
        _safeNotifyListeners();
        return;
      }

      if (_selectedMatchId == matchId) {
        debugPrint('Match already selected: $matchId');
        return;
      }

      // Disconnect from previous match if any
      if (_selectedMatchId != null) {
        await _webSocketService.disconnect();
      }

      _selectedMatchId = matchId;
      _connectionState = ConnectionState.connecting;
      _safeNotifyListeners();

      // Fetch match data if not in cache
      if (!_matches.containsKey(matchId)) {
        await fetchLiveMatch(matchId);
      }

      // Connect to WebSocket for real-time updates
      try {
        await _webSocketService.connect(matchId);
      } catch (e) {
        debugPrint('WebSocket connection failed, using polling: $e');
        _startPollingFallback();
      }
    } catch (e) {
      debugPrint('Error selecting match: $e');
      if (!_isDisposed) {
        _error = _getErrorMessage(e);
        _safeNotifyListeners();
      }
    }
  }

  /// Clear selected match
  Future<void> clearSelectedMatch() async {
    if (_isDisposed || _selectedMatchId == null) return;

    try {
      await _webSocketService.disconnect();
      _stopPolling();
      _selectedMatchId = null;
      _connectionState = ConnectionState.disconnected;
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('Error clearing selected match: $e');
    }
  }

  // ==================== Polling Fallback ====================

  /// Start polling as fallback when WebSocket fails
  void _startPollingFallback() {
    if (_isDisposed || _pollingTimer != null || _selectedMatchId == null) {
      return;
    }

    debugPrint('Starting polling fallback');
    
    _pollingTimer = Timer.periodic(_pollingInterval, (timer) async {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      if (_selectedMatchId != null) {
        await fetchLiveMatch(_selectedMatchId!);
      }
    });
  }

  /// Stop polling
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // ==================== Reconnection ====================

  /// Schedule reconnection attempt
  void _scheduleReconnection() {
    if (_isDisposed || 
        _reconnectionAttempts >= _maxReconnectionAttempts ||
        _selectedMatchId == null) {
      return;
    }

    // Cancel existing timer
    _reconnectionTimer?.cancel();

    // Exponential backoff: 2, 4, 8, 16, 32 seconds
    final delay = Duration(seconds: 2 << _reconnectionAttempts);
    
    debugPrint('Scheduling reconnection attempt ${_reconnectionAttempts + 1} in ${delay.inSeconds}s');

    _reconnectionTimer = Timer(delay, () async {
      if (_isDisposed) return;

      _reconnectionAttempts++;
      _connectionState = ConnectionState.reconnecting;
      _safeNotifyListeners();

      try {
        await _webSocketService.connect(_selectedMatchId!);
      } catch (e) {
        debugPrint('Reconnection attempt failed: $e');
        if (_reconnectionAttempts < _maxReconnectionAttempts) {
          _scheduleReconnection();
        } else {
          debugPrint('Max reconnection attempts reached, using polling only');
          _startPollingFallback();
        }
      }
    });
  }

  // ==================== Utility Methods ====================

  /// Get match by ID
  LiveMatch? getMatchById(String matchId) {
    return _matches[matchId];
  }

  /// Check if match exists
  bool hasMatch(String matchId) {
    return _matches.containsKey(matchId);
  }

  /// Refresh all data
  Future<void> refresh() async {
    await fetchLiveMatches();
    if (_selectedMatchId != null && hasMatch(_selectedMatchId!)) {
      await fetchLiveMatch(_selectedMatchId!);
    }
  }

  /// Clear error
  void clearError() {
    if (_isDisposed) return;

    if (_error != null) {
      _error = null;
      _safeNotifyListeners();
    }
  }

  /// Clear all data
  void clear() {
    if (_isDisposed) return;

    try {
      _matches.clear();
      _selectedMatchId = null;
      _error = null;
      _connectionState = ConnectionState.disconnected;
      _stopPolling();
      _reconnectionTimer?.cancel();
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('Error clearing data: $e');
    }
  }

  // ==================== Helper Methods ====================

  void _setLoading(bool loading) {
    if (_isDisposed) return;

    if (_isLoading != loading) {
      _isLoading = loading;
      _safeNotifyListeners();
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error == null) return 'Unknown error occurred';
    final message = error.toString();
    return message.replaceAll('Exception:', '').trim();
  }

  int _extractInt(Map<String, dynamic> data, String key, int defaultValue) {
    final value = data[key];
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  double _extractDouble(Map<String, dynamic> data, String key, double defaultValue) {
    final value = data[key];
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // ==================== Disposal ====================

  @override
  void dispose() {
    _isDisposed = true;
    
    try {
      _webSocketService.disconnect();
    } catch (e) {
      debugPrint('Error disconnecting WebSocket: $e');
    }

    try {
      _stopPolling();
      _reconnectionTimer?.cancel();
      _matches.clear();
    } catch (e) {
      debugPrint('Error during disposal: $e');
    }

    super.dispose();
  }
}