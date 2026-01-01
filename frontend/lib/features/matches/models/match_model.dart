import 'package:flutter/foundation.dart';

/// The status of a cricket match in the lifecycle.
enum MatchStatus {
  planned, // Backend calls this 'scheduled'
  live,
  completed,
  cancelled;

  static MatchStatus fromBackendValue(String value) {
    return switch (value.toLowerCase()) {
      'scheduled' => planned,
      'live' => live,
      'completed' => completed,
      'cancelled' => cancelled,
      _ => planned,
    };
  }

  String get backendValue => switch (this) {
    planned => 'scheduled',
    live => 'live',
    completed => 'completed',
    cancelled => 'cancelled',
  };
}

@immutable
class MatchModel {
  final String id;
  final String teamA;
  final String teamB;
  final MatchStatus status;
  final DateTime? scheduledAt;
  final String creatorId;
  final int? tournamentId;
  final String round; // [ADDED] Required for Brackets
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
    this.tournamentId,
    this.round = 'round_1', // [ADDED]
    this.runs = 0,
    this.wickets = 0,
    this.overs = 0.0,
  }) : assert(wickets >= 0 && wickets <= 10, 'Wickets must be 0-10'),
       assert(overs >= 0, 'Overs cannot be negative');

  factory MatchModel.fromMap(Map<String, dynamic> m) {
    try {
      DateTime? scheduled;
      final scheduledValue = m['scheduled_at'];
      if (scheduledValue != null) {
        if (scheduledValue is DateTime) {
          scheduled = scheduledValue;
        } else if (scheduledValue is String) {
          scheduled = DateTime.tryParse(scheduledValue);
        }
      }

      final statusValue = m['status'];
      final MatchStatus status;
      if (statusValue is String) {
        status = MatchStatus.fromBackendValue(statusValue);
      } else if (statusValue is int) {
        status = MatchStatus
            .values[statusValue.clamp(0, MatchStatus.values.length - 1)];
      } else {
        status = MatchStatus.planned;
      }

      return MatchModel(
        id: m['id']?.toString() ?? '',
        teamA: m['team_a']?.toString() ?? 'Team A',
        teamB: m['team_b']?.toString() ?? 'Team B',
        status: status,
        scheduledAt: scheduled,
        creatorId: m['creator_id']?.toString() ?? '',
        tournamentId: m['tournament_id'] != null
            ? _parseInt(m['tournament_id'])
            : null,
        round: m['round']?.toString() ?? 'round_1', // [ADDED]
        runs: _parseInt(m['runs']),
        wickets: _parseInt(m['wickets']),
        overs: _parseDouble(m['overs']),
      );
    } catch (e, stackTrace) {
      throw FormatException(
        'MatchModel.fromMap failed: $e\nMap: $m',
        stackTrace,
      );
    }
  }

  // [ADDED] Factory for tournament matches
  factory MatchModel.fromTournamentMatch(dynamic data) {
    Map<String, dynamic> json;
    if (data is Map<String, dynamic>) {
      json = data;
    } else {
      try {
        json = (data as dynamic).toJson();
      } catch (_) {
        json = {};
      }
    }

    return MatchModel(
      id: json['id']?.toString() ?? '',
      teamA: json['team1_name']?.toString() ?? 'Team 1',
      teamB: json['team2_name']?.toString() ?? 'Team 2',
      status: MatchStatus.fromBackendValue(
        json['status']?.toString() ?? 'scheduled',
      ),
      scheduledAt: json['match_date'] != null
          ? DateTime.tryParse(json['match_date'].toString())
          : (json['scheduled_time'] != null
                ? DateTime.tryParse(json['scheduled_time'].toString())
                : null),
      creatorId: '',
      tournamentId: _parseInt(json['tournament_id']),
      round: json['round']?.toString() ?? 'round_1',
      runs: 0,
      wickets: 0,
      overs: 20.0,
    );
  }

  factory MatchModel.fromLegacyMatch(dynamic legacyMatch) {
    // Handle both Map and Object input safely
    String? getProp(String key) {
      if (legacyMatch is Map) return legacyMatch[key]?.toString();
      try {
        return (legacyMatch as dynamic).toJson()[key]?.toString();
      } catch (_) {
        return null;
      }
    }

    return MatchModel(
      id: getProp('id') ?? '',
      teamA:
          getProp('teamA') ??
          getProp('team1_name') ??
          getProp('team1Name') ??
          '',
      teamB:
          getProp('teamB') ??
          getProp('team2_name') ??
          getProp('team2Name') ??
          '',
      status: MatchStatus.fromBackendValue(getProp('status') ?? 'scheduled'),
      scheduledAt: DateTime.tryParse(
        getProp('scheduledAt') ??
            getProp('scheduled_time') ??
            getProp('scheduled_at') ??
            '',
      ),
      creatorId: getProp('creatorId') ?? getProp('creator_id') ?? '',
      tournamentId: _parseInt(
        getProp('tournamentId') ?? getProp('tournament_id'),
      ),
      round: getProp('round') ?? 'round_1', // [ADDED]
      runs: _parseInt(getProp('runs')),
      wickets: _parseInt(getProp('wickets')),
      overs: _parseDouble(getProp('overs')),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'team_a': teamA,
      'team_b': teamB,
      'status': status.backendValue,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'creator_id': creatorId,
      'tournament_id': tournamentId,
      'round': round, // [ADDED]
      'runs': runs,
      'wickets': wickets,
      'overs': overs,
    };
  }

  MatchModel copyWith({
    String? id,
    String? teamA,
    String? teamB,
    MatchStatus? status,
    DateTime? scheduledAt,
    String? creatorId,
    int? tournamentId,
    String? round, // [ADDED]
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
      tournamentId: tournamentId ?? this.tournamentId,
      round: round ?? this.round, // [ADDED]
      runs: runs ?? this.runs,
      wickets: wickets ?? this.wickets,
      overs: overs ?? this.overs,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MatchModel && id == other.id;

  @override
  int get hashCode => Object.hash(id, teamA, teamB, status);

  @override
  String toString() => 'MatchModel($id: $teamA vs $teamB, Round: $round)';
}
