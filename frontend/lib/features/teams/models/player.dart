// lib/features/teams/models/player.dart

import 'package:flutter/foundation.dart';

class Player {
  final String id;
  final String? teamId; // ✅ Added to maintain team relationship
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
  final bool isTemporary; // ✅ Added isTemporary field

  Player({
    required this.id,
    this.teamId,
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
    this.isTemporary = false, // Default to false
  }) {
    // --- Validation in Constructor (Restored from your original code) ---
    if (id.isEmpty) debugPrint('Warning: Player created with empty id');
    if (playerName.isEmpty) {
      debugPrint('Warning: Player created with empty playerName');
    }
    if (playerRole.isEmpty) {
      debugPrint('Warning: Player created with empty playerRole');
    }
    if (runs < 0 ||
        matchesPlayed < 0 ||
        hundreds < 0 ||
        fifties < 0 ||
        wickets < 0) {
      debugPrint('Warning: Player created with negative values');
    }
  }

  // --- Static Helpers for List Parsing ---

  static List<Player> fromList(dynamic list) {
    if (list == null || list is! List) return [];
    return list
        .map((item) {
          if (item is Map<String, dynamic>) {
            try {
              return Player.fromJson(item);
            } catch (e) {
              debugPrint('Error parsing player in list: $e');
              return null;
            }
          }
          return null;
        })
        .whereType<Player>()
        .toList();
  }

  // --- Private Static Helpers ---

  static String _toString(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    return v.toString().trim();
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is int) return v == 1;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    return false;
  }

  // --- JSON Serialization ---

  /// Creates a Player instance from a JSON map (Robust: handles snake_case & camelCase)
  factory Player.fromJson(Map<String, dynamic> json) {
    try {
      return Player(
        id: _toString(json['id'] ?? json['player_id'], fallback: '0'),
        teamId: _toString(json['team_id'] ?? json['teamId']),
        playerName: _toString(
          json['player_name'] ?? json['name'] ?? json['playerName'],
          fallback: 'Unknown Player',
        ),
        playerRole: _toString(
          json['player_role'] ?? json['role'] ?? json['playerRole'],
          fallback: 'Unknown Role',
        ),
        playerImageUrl:
            json['player_image_url'] ??
            json['image_url'] ??
            json['playerImageUrl'],
        runs: _toInt(json['runs']),
        matchesPlayed: _toInt(json['matches_played'] ?? json['matchesPlayed']),
        hundreds: _toInt(json['hundreds']),
        fifties: _toInt(json['fifties']),
        battingAverage: _toDouble(
          json['batting_average'] ?? json['battingAverage'],
        ),
        strikeRate: _toDouble(json['strike_rate'] ?? json['strikeRate']),
        wickets: _toInt(json['wickets']),
        isTemporary: _toBool(json['is_temporary'] ?? json['isTemporary']),
      );
    } catch (e) {
      debugPrint('Error parsing Player: $e');
      // Return safe fallback
      return Player(
        id: '0',
        playerName: 'Error Player',
        playerRole: 'Unknown',
        runs: 0,
        matchesPlayed: 0,
        hundreds: 0,
        fifties: 0,
        battingAverage: 0,
        strikeRate: 0,
        wickets: 0,
      );
    }
  }

  /// ✅ THE FIX: Uses snake_case keys to match Node.js Backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (teamId != null && teamId!.isNotEmpty) 'team_id': teamId,
      'player_name': playerName, // Fixes 400 Bad Request
      'player_role': playerRole,
      'runs': runs,
      'matches_played': matchesPlayed,
      'hundreds': hundreds,
      'fifties': fifties,
      'batting_average': battingAverage,
      'strike_rate': strikeRate,
      'wickets': wickets,
      'is_temporary': isTemporary,
      if (playerImageUrl != null) 'player_image_url': playerImageUrl,
    };
  }

  /// CopyWith for updating fields
  Player copyWith({
    String? id,
    String? teamId,
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
    bool? isTemporary,
  }) {
    return Player(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
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
      isTemporary: isTemporary ?? this.isTemporary,
    );
  }

  // --- UI Helpers & Getters (Restored) ---

  String get initials {
    if (playerName.isEmpty) return '?';
    final parts = playerName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return playerName[0].toUpperCase();
  }

  bool get isValid => id.isNotEmpty && id != '0';
  String get displayName =>
      playerName.isNotEmpty ? playerName : 'Unknown Player';
  String get displayRole => playerRole.isNotEmpty ? playerRole : 'Unknown Role';
  bool get hasProfileImage =>
      playerImageUrl != null && playerImageUrl!.isNotEmpty;

  // Stats helpers
  int get totalBoundaries =>
      hundreds * 100 + fifties * 50; // Approximation logic you had

  // Role Checks
  bool get isBowler => playerRole.toLowerCase().contains('bowler');
  bool get isBatsman => playerRole.toLowerCase().contains('batsman');
  bool get isAllRounder => playerRole.toLowerCase().contains('all-rounder');
  bool get isWicketKeeper => playerRole.toLowerCase().contains('wicket-keeper');

  /// Summary String
  String get summary {
    return '$displayName - $displayRole\n'
        'Runs: $runs | Avg: ${battingAverage.toStringAsFixed(2)} | '
        'SR: ${strikeRate.toStringAsFixed(2)} | Wickets: $wickets';
  }

  /// Validation Logic (Restored)
  List<String> validate() {
    final issues = <String>[];
    if (id.isEmpty) issues.add('Player ID is empty');
    if (playerName.isEmpty || playerName.length < 2) {
      issues.add('Player name is invalid');
    }
    if (playerRole.isEmpty) issues.add('Player role is empty');
    if (runs < 0) issues.add('Runs cannot be negative');
    if (matchesPlayed < 0) issues.add('Matches played cannot be negative');
    if (hundreds < 0) issues.add('Hundreds cannot be negative');
    if (fifties < 0) issues.add('Fifties cannot be negative');
    if (battingAverage < 0) issues.add('Batting average cannot be negative');
    if (strikeRate < 0) issues.add('Strike rate cannot be negative');
    if (wickets < 0) issues.add('Wickets cannot be negative');
    if (hundreds > matchesPlayed) {
      issues.add('Hundreds cannot exceed matches played');
    }
    if (fifties > matchesPlayed) {
      issues.add('Fifties cannot exceed matches played');
    }
    return issues;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Player && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Player(id: $id, name: $playerName, role: $playerRole)';
}
