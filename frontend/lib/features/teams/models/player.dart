// lib/features/teams/models/player.dart

class Player {
  final int id;
  final String playerName;
  final String playerRole;
  final int runs;
  final int matchesPlayed;
  final int hundreds;
  final int fifties;
  final double battingAverage;
  final double strikeRate;
  final int wickets;

  Player({
    required this.id,
    required this.playerName,
    required this.playerRole,
    required this.runs,
    required this.matchesPlayed,
    required this.hundreds,
    required this.fifties,
    required this.battingAverage,
    required this.strikeRate,
    required this.wickets,
  });

  // --- Private Static Helpers for Robust JSON Parsing ---
  // These methods are designed to prevent crashes if the API sends data
  // in an unexpected format (e.g., a number as a string).

  /// Safely converts a dynamic value to an integer.
  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  /// Safely converts a dynamic value to a double.
  static double _toDouble(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  /// Safely converts a dynamic value to a string.
  static String _toString(dynamic v, {String fallback = ''}) {
    return v?.toString() ?? fallback;
  }

  /// Creates a Player instance from a JSON map.
  /// This factory handles multiple possible key names from the API (e.g., 'player_name' or 'name')
  /// to make the frontend more resilient to backend inconsistencies.
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: _toInt(json['id'] ?? json['_id']),
      playerName: _toString(json['player_name'] ?? json['name']),
      playerRole: _toString(json['player_role'] ?? json['role']),
      runs: _toInt(json['runs']),
      matchesPlayed: _toInt(json['matches_played'] ?? json['matches']),
      hundreds: _toInt(json['hundreds']),
      fifties: _toInt(json['fifties']),
      battingAverage: _toDouble(json['batting_average'] ?? json['avg']),
      strikeRate: _toDouble(json['strike_rate'] ?? json['sr']),
      wickets: _toInt(json['wickets']),
    );
  }

  /// Converts a Player instance to a JSON map for sending to the API.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player_name': playerName,
      'player_role': playerRole,
      'runs': runs,
      'matches_played': matchesPlayed,
      'hundreds': hundreds,
      'fifties': fifties,
      'batting_average': battingAverage,
      'strike_rate': strikeRate,
      'wickets': wickets,
    };
  }
}