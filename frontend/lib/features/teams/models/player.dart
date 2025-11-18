// lib/features/teams/models/player.dart

import 'package:flutter/foundation.dart';

class Player {
  final String id; // Changed to String for better API compatibility
  final String playerName;
  final String playerRole;
  final String? playerImageUrl;
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
    this.playerImageUrl,
    required this.runs,
    required this.matchesPlayed,
    required this.hundreds,
    required this.fifties,
    required this.battingAverage,
    required this.strikeRate,
    required this.wickets,
  }) {
    // Validation in constructor
    if (id.isEmpty) {
      debugPrint('Warning: Player created with empty id');
    }
    if (playerName.isEmpty) {
      debugPrint('Warning: Player created with empty playerName');
    }
    if (playerRole.isEmpty) {
      debugPrint('Warning: Player created with empty playerRole');
    }
    if (runs < 0 || matchesPlayed < 0 || hundreds < 0 || 
        fifties < 0 || wickets < 0) {
      debugPrint('Warning: Player created with negative values');
    }
    if (battingAverage < 0 || strikeRate < 0) {
      debugPrint('Warning: Player created with negative average/rate');
    }
  }

  // --- Private Static Helpers for Robust JSON Parsing ---

  /// Safely converts a dynamic value to a string (for ID).
  static String _toIdString(dynamic v, {String fallback = '0'}) {
    if (v == null) return fallback;
    return v.toString().trim();
  }

  /// Safely converts a dynamic value to an integer.
  static int _toInt(dynamic v, {int fallback = 0}) {
    try {
      if (v == null) return fallback;
      if (v is int) return v.clamp(0, 2147483647);
      if (v is double) return v.toInt().clamp(0, 2147483647);
      if (v is String) {
        final parsed = int.tryParse(v.trim());
        return parsed?.clamp(0, 2147483647) ?? fallback;
      }
      return fallback;
    } catch (e) {
      debugPrint('Error converting to int: $e, value: $v');
      return fallback;
    }
  }

  /// Safely converts a dynamic value to a double.
  static double _toDouble(dynamic v, {double fallback = 0.0}) {
    try {
      if (v == null) return fallback;
      if (v is double) return v.clamp(0.0, double.maxFinite);
      if (v is num) return v.toDouble().clamp(0.0, double.maxFinite);
      if (v is String) {
        final parsed = double.tryParse(v.trim());
        return parsed?.clamp(0.0, double.maxFinite) ?? fallback;
      }
      return fallback;
    } catch (e) {
      debugPrint('Error converting to double: $e, value: $v');
      return fallback;
    }
  }

  /// Safely converts a dynamic value to a string.
  static String _toString(dynamic v, {String fallback = ''}) {
    try {
      if (v == null) return fallback;
      final str = v.toString().trim();
      return str.isNotEmpty ? str : fallback;
    } catch (e) {
      debugPrint('Error converting to string: $e, value: $v');
      return fallback;
    }
  }

  /// Safely gets a nullable string value.
  static String? _toNullableString(dynamic v) {
    try {
      if (v == null) return null;
      final str = v.toString().trim();
      return str.isNotEmpty ? str : null;
    } catch (e) {
      debugPrint('Error converting to nullable string: $e, value: $v');
      return null;
    }
  }

  /// Creates a Player instance from a JSON map.
  factory Player.fromJson(Map<String, dynamic> json) {
    try {
      // Validate that we have at minimum required data
      if (json.isEmpty) {
        throw const FormatException('Empty JSON object for Player');
      }

      return Player(
        id: _toIdString(json['id'] ?? json['player_id']),
        playerName: _toString(
          json['player_name'] ?? json['name'] ?? json['playerName'],
          fallback: 'Unknown Player',
        ),
        playerRole: _toString(
          json['player_role'] ?? json['role'] ?? json['playerRole'],
          fallback: 'Unknown Role',
        ),
        playerImageUrl: _toNullableString(
          json['player_image_url'] ?? 
          json['image_url'] ?? 
          json['playerImageUrl'],
        ),
        runs: _toInt(json['runs']),
        matchesPlayed: _toInt(
          json['matches_played'] ?? json['matchesPlayed'],
        ),
        hundreds: _toInt(json['hundreds']),
        fifties: _toInt(json['fifties']),
        battingAverage: _toDouble(
          json['batting_average'] ?? json['battingAverage'],
        ),
        strikeRate: _toDouble(
          json['strike_rate'] ?? json['strikeRate'],
        ),
        wickets: _toInt(json['wickets']),
      );
    } catch (e, stackTrace) {
      debugPrint('Error parsing Player from JSON: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('JSON data: $json');
      
      // Return a fallback player instead of crashing
      return Player(
        id: json['id']?.toString() ?? '0',
        playerName: 'Error Loading Player',
        playerRole: 'Unknown',
        runs: 0,
        matchesPlayed: 0,
        hundreds: 0,
        fifties: 0,
        battingAverage: 0.0,
        strikeRate: 0.0,
        wickets: 0,
      );
    }
  }

  /// Converts a Player instance to a JSON map for sending to the API.
  Map<String, dynamic> toJson() {
    try {
      return {
        'id': id,
        'player_name': playerName,
        'player_role': playerRole,
        if (playerImageUrl != null && playerImageUrl!.isNotEmpty)
          'player_image_url': playerImageUrl,
        'runs': runs,
        'matches_played': matchesPlayed,
        'hundreds': hundreds,
        'fifties': fifties,
        'batting_average': battingAverage,
        'strike_rate': strikeRate,
        'wickets': wickets,
      };
    } catch (e) {
      debugPrint('Error serializing Player to JSON: $e');
      rethrow;
    }
  }

  /// Creates a copy of this Player with the given fields replaced with new values.
  Player copyWith({
    String? id,
    String? playerName,
    String? playerRole,
    String? playerImageUrl,
    bool clearPlayerImageUrl = false,
    int? runs,
    int? matchesPlayed,
    int? hundreds,
    int? fifties,
    double? battingAverage,
    double? strikeRate,
    int? wickets,
  }) {
    return Player(
      id: id ?? this.id,
      playerName: playerName ?? this.playerName,
      playerRole: playerRole ?? this.playerRole,
      playerImageUrl: clearPlayerImageUrl
          ? null
          : (playerImageUrl ?? this.playerImageUrl),
      runs: runs ?? this.runs,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      hundreds: hundreds ?? this.hundreds,
      fifties: fifties ?? this.fifties,
      battingAverage: battingAverage ?? this.battingAverage,
      strikeRate: strikeRate ?? this.strikeRate,
      wickets: wickets ?? this.wickets,
    );
  }

  /// Check if this player is valid
  bool get isValid {
    return id.isNotEmpty && 
           playerName.isNotEmpty && 
           playerRole.isNotEmpty;
  }

  /// Get player's display name (safe to use in UI)
  String get displayName {
    return playerName.isNotEmpty ? playerName : 'Unknown Player';
  }

  /// Get player's display role (safe to use in UI)
  String get displayRole {
    return playerRole.isNotEmpty ? playerRole : 'Unknown Role';
  }

  /// Check if player has a profile image
  bool get hasProfileImage {
    return playerImageUrl != null && playerImageUrl!.isNotEmpty;
  }

  /// Get initials from player name
  String get initials {
    try {
      if (playerName.isEmpty) return '?';
      
      final parts = playerName.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return playerName[0].toUpperCase();
    } catch (e) {
      debugPrint('Error getting initials: $e');
      return '?';
    }
  }

  /// Calculate total boundaries (4s + 6s equivalent)
  int get totalBoundaries => hundreds * 100 + fifties * 50;

  /// Check if player is a bowler
  bool get isBowler => playerRole.toLowerCase().contains('bowler');

  /// Check if player is a batsman
  bool get isBatsman => playerRole.toLowerCase().contains('batsman');

  /// Check if player is an all-rounder
  bool get isAllRounder => playerRole.toLowerCase().contains('all-rounder');

  /// Check if player is a wicket-keeper
  bool get isWicketKeeper => playerRole.toLowerCase().contains('wicket-keeper');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Player && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Player(id: $id, name: $playerName, role: $playerRole, '
           'runs: $runs, wickets: $wickets, avg: ${battingAverage.toStringAsFixed(2)}, '
           'sr: ${strikeRate.toStringAsFixed(2)})';
  }

  /// Create a formatted summary string for display
  String get summary {
    return '$displayName - $displayRole\n'
           'Runs: $runs | Avg: ${battingAverage.toStringAsFixed(2)} | '
           'SR: ${strikeRate.toStringAsFixed(2)} | Wickets: $wickets';
  }

  /// Validate player data and return list of issues
  List<String> validate() {
    final issues = <String>[];
    
    if (id.isEmpty) {
      issues.add('Player ID is empty');
    }
    if (playerName.isEmpty || playerName.length < 2) {
      issues.add('Player name is invalid');
    }
    if (playerRole.isEmpty) {
      issues.add('Player role is empty');
    }
    if (runs < 0) {
      issues.add('Runs cannot be negative');
    }
    if (matchesPlayed < 0) {
      issues.add('Matches played cannot be negative');
    }
    if (hundreds < 0) {
      issues.add('Hundreds cannot be negative');
    }
    if (fifties < 0) {
      issues.add('Fifties cannot be negative');
    }
    if (battingAverage < 0) {
      issues.add('Batting average cannot be negative');
    }
    if (strikeRate < 0) {
      issues.add('Strike rate cannot be negative');
    }
    if (wickets < 0) {
      issues.add('Wickets cannot be negative');
    }
    
    // Logical validations
    if (hundreds > matchesPlayed) {
      issues.add('Hundreds cannot exceed matches played');
    }
    if (fifties > matchesPlayed) {
      issues.add('Fifties cannot exceed matches played');
    }
    
    return issues;
  }
}