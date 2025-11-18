import 'package:flutter/foundation.dart';

/// The status of a cricket match in the lifecycle.
/// 
/// **Note**: This enum is backward-compatible with string storage.
/// Use `MatchStatus.fromString()` when deserializing from Firestore/JSON.
enum MatchStatus {
  planned,
  live,
  completed,
  cancelled;

  /// Converts a string value to [MatchStatus], defaulting to [planned].
  static MatchStatus fromString(String value) {
    return MatchStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => MatchStatus.planned,
    );
  }
}

/// {@template match_model}
/// Represents a cricket match in the scoring system.
/// 
/// **⚠️ ARCHITECTURAL LIMITATION**: This model stores scoring data (runs, wickets, overs)
/// at the match level, which is insufficient for proper cricket scoring where each team
/// has separate scores per innings. This is a critical limitation for the live scoring
/// feature and should be refactored to include an [Innings] model.
/// {@endtemplate}
@immutable
class MatchModel {
  final String id;
  final String teamA;
  final String teamB;
  final MatchStatus status;
  final DateTime? scheduledAt;
  final String creatorId;
  final int runs;
  final int wickets;
  final double overs;

  const MatchModel({
    required this.id,
    required this.teamA,
    required this.teamB,
    required this.status,
    this.scheduledAt,
    required this.creatorId,
    this.runs = 0,
    this.wickets = 0,
    this.overs = 0.0,
  }) : assert(wickets >= 0 && wickets <= 10, 'Wickets must be 0-10'),
       assert(overs >= 0, 'Overs cannot be negative');

  /// Creates a [MatchModel] from a map (Firestore, JSON, etc.).
  /// 
  /// **Error Handling**: If critical fields are missing or invalid, throws
  /// [FormatException] with detailed context instead of silent failures.
  factory MatchModel.fromMap(Map<String, dynamic> m) {
    try {
      // Parse scheduled time with fallback chain
      DateTime? scheduled;
      final scheduledValue = m['scheduled_at'];
      if (scheduledValue != null) {
        if (scheduledValue is DateTime) {
          scheduled = scheduledValue;
        } else if (scheduledValue is String) {
          scheduled = DateTime.tryParse(scheduledValue);
        }
      }

      // Parse status with backward compatibility
      final statusValue = m['status'];
      final MatchStatus status;
      if (statusValue is String) {
        status = MatchStatus.fromString(statusValue);
      } else if (statusValue is int && statusValue >= 0 && statusValue < MatchStatus.values.length) {
        status = MatchStatus.values[statusValue];
      } else {
        status = MatchStatus.planned;
      }

      return MatchModel(
        id: (m['id'] as String?)?.trim() ?? '',
        teamA: (m['team_a'] as String?)?.trim() ?? 'Team A',
        teamB: (m['team_b'] as String?)?.trim() ?? 'Team B',
        status: status,
        scheduledAt: scheduled,
        creatorId: (m['creator_id'] as String?)?.trim() ?? '',
        runs: _parseInt(m['runs']),
        wickets: _parseInt(m['wickets']),
        overs: _parseDouble(m['overs']),
      );
    } catch (e, stackTrace) {
      throw FormatException(
        'Failed to deserialize MatchModel from map. \n'
        'Error: $e \n'
        'Input map: ${m.toString().substring(0, m.toString().length.clamp(0, 200))}',
        stackTrace,
      );
    }
  }

  /// Parses a value to int safely.
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? 0;
    }
    return 0;
  }

  /// Parses a value to double safely.
  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return 0.0;
  }

  /// Creates a copy with optional field overrides.
  /// 
  /// **Performance**: This is allocation-heavy. For frequent updates in live scoring,
  /// consider using a state management solution with mutable state for the scoring
  /// fields only, while keeping the match metadata immutable.
  MatchModel copyWith({
    String? id,
    String? teamA,
    String? teamB,
    MatchStatus? status,
    DateTime? scheduledAt,
    String? creatorId,
    int? runs,
    int? wickets,
    double? overs,
  }) {
    return MatchModel(
      id: id ?? this.id,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      creatorId: creatorId ?? this.creatorId,
      runs: runs ?? this.runs,
      wickets: wickets ?? this.wickets,
      overs: overs ?? this.overs,
    );
  }

  /// Converts to a map suitable for Firestore/JSON storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'team_a': teamA,
      'team_b': teamB,
      'status': status.name, // Store as string for readability
      'scheduled_at': scheduledAt?.toIso8601String(),
      'creator_id': creatorId,
      'runs': runs,
      'wickets': wickets,
      'overs': overs,
    };
  }

  /// Validates business rules for this match.
  /// 
  /// Call this before saving to ensure data integrity.
  void validate() {
    if (id.isEmpty) throw StateError('Match ID cannot be empty');
    if (teamA.isEmpty) throw StateError('Team A ID cannot be empty');
    if (teamB.isEmpty) throw StateError('Team B ID cannot be empty');
    if (teamA == teamB) throw StateError('Team A and Team B must be different');
    if (creatorId.isEmpty) throw StateError('Creator ID cannot be empty');
    if (wickets < 0 || wickets > 10) throw StateError('Wickets must be between 0-10');
    if (overs < 0) throw StateError('Overs cannot be negative');
    if (overs > 0 && overs < 0.1) throw StateError('Overs precision too low (minimum 0.1)');
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MatchModel &&
            id == other.id &&
            teamA == other.teamA &&
            teamB == other.teamB &&
            status == other.status &&
            scheduledAt == other.scheduledAt;
  }

  @override
  int get hashCode => Object.hash(id, teamA, teamB, status, scheduledAt);

  @override
  String toString() {
    return 'MatchModel(id: $id, teamA: $teamA, teamB: $teamB, status: $status, runs: $runs/$wickets, overs: $overs)';
  }
}