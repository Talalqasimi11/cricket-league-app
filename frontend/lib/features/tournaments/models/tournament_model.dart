// lib/features/tournaments/models/tournament_model.dart
import 'package:flutter/foundation.dart';

/// Standardized status enum for tournament matches
enum MatchStatus {
  upcoming,
  live,
  completed;

  static MatchStatus fromString(String? status) {
    try {
      if (status == null || status.isEmpty) {
        return MatchStatus.upcoming;
      }

      switch (status.toLowerCase().trim()) {
        case 'upcoming':
        case 'not_started':
        case 'planned':
        case 'scheduled':
          return MatchStatus.upcoming;
        case 'live':
        case 'active':
        case 'in_progress':
        case 'ongoing':
          return MatchStatus.live;
        case 'completed':
        case 'finished':
        case 'done':
          return MatchStatus.completed;
        default:
          debugPrint('Unknown match status: $status, defaulting to upcoming');
          return MatchStatus.upcoming;
      }
    } catch (e) {
      debugPrint('Error parsing match status: $e');
      return MatchStatus.upcoming;
    }
  }

  @override
  String toString() {
    switch (this) {
      case MatchStatus.upcoming:
        return 'upcoming';
      case MatchStatus.live:
        return 'live';
      case MatchStatus.completed:
        return 'completed';
    }
  }

  // Display-friendly name
  String get displayName {
    switch (this) {
      case MatchStatus.upcoming:
        return 'Upcoming';
      case MatchStatus.live:
        return 'Live';
      case MatchStatus.completed:
        return 'Completed';
    }
  }
}

/// Standardized status enum for tournaments
enum TournamentStatus {
  upcoming,
  active,
  completed;

  static TournamentStatus fromString(String? status) {
    try {
      if (status == null || status.isEmpty) {
        return TournamentStatus.upcoming;
      }

      switch (status.toLowerCase().trim()) {
        case 'upcoming':
        case 'not_started':
        case 'scheduled':
        case 'planned':
          return TournamentStatus.upcoming;
        case 'active':
        case 'ongoing':
        case 'live':
        case 'in_progress':
          return TournamentStatus.active;
        case 'completed':
        case 'finished':
        case 'done':
          return TournamentStatus.completed;
        default:
          debugPrint('Unknown tournament status: $status, defaulting to upcoming');
          return TournamentStatus.upcoming;
      }
    } catch (e) {
      debugPrint('Error parsing tournament status: $e');
      return TournamentStatus.upcoming;
    }
  }

  @override
  String toString() {
    switch (this) {
      case TournamentStatus.upcoming:
        return 'upcoming';
      case TournamentStatus.active:
        return 'active';
      case TournamentStatus.completed:
        return 'completed';
    }
  }

  // Display-friendly name
  String get displayName {
    switch (this) {
      case TournamentStatus.upcoming:
        return 'Upcoming';
      case TournamentStatus.active:
        return 'Active';
      case TournamentStatus.completed:
        return 'Completed';
    }
  }
}

class MatchModel {
  final String id;
  final String teamA;
  final String teamB;
   DateTime? scheduledAt;
  final String status;
  final String? winner;
  final String? parentMatchId;

  MatchModel({
    required this.id,
    required this.teamA,
    required this.teamB,
    this.scheduledAt,
    this.status = 'planned',
    this.winner,
    this.parentMatchId,
  }) {
    // Validation
    if (id.isEmpty) {
      debugPrint('Warning: MatchModel created with empty id');
    }
    if (teamA.isEmpty) {
      debugPrint('Warning: MatchModel created with empty teamA');
    }
    if (teamB.isEmpty) {
      debugPrint('Warning: MatchModel created with empty teamB');
    }
  }

  // Computed display ID for UI
  String get displayId {
    try {
      if (id.isEmpty) return '0';

      // Try to extract numeric part
      final numericMatch = RegExp(r'(\d+)').firstMatch(id);
      if (numericMatch != null && numericMatch.group(1) != null) {
        return numericMatch.group(1)!;
      }

      // Fallback to full ID
      return id;
    } catch (e) {
      debugPrint('Error extracting displayId from "$id": $e');
      return id.isNotEmpty ? id : '0';
    }
  }

  // Get match status enum
  MatchStatus get matchStatus {
    return MatchStatus.fromString(status);
  }

  // Check if match is upcoming
  bool get isUpcoming => matchStatus == MatchStatus.upcoming;

  // Check if match is live
  bool get isLive => matchStatus == MatchStatus.live;

  // Check if match is completed
  bool get isCompleted => matchStatus == MatchStatus.completed;

  // Safe team names
  String get safeTeamA => teamA.isNotEmpty ? teamA : 'Team A';
  String get safeTeamB => teamB.isNotEmpty ? teamB : 'Team B';

  // Match display string
  String get matchupDisplay => '$safeTeamA vs $safeTeamB';

  MatchModel copyWith({
    String? id,
    String? teamA,
    String? teamB,
    DateTime? scheduledAt,
    bool clearScheduledAt = false,
    String? status,
    String? winner,
    bool clearWinner = false,
    String? parentMatchId,
    bool clearParentMatchId = false,
  }) {
    return MatchModel(
      id: id ?? this.id,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      scheduledAt: clearScheduledAt ? null : (scheduledAt ?? this.scheduledAt),
      status: status ?? this.status,
      winner: clearWinner ? null : (winner ?? this.winner),
      parentMatchId: clearParentMatchId
          ? null
          : (parentMatchId ?? this.parentMatchId),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatchModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MatchModel(id: $id, teamA: $teamA, teamB: $teamB, status: $status)';
  }

  // Create from JSON (safe parsing)
  factory MatchModel.fromJson(Map<String, dynamic> json) {
    try {
      return MatchModel(
        id: json['id']?.toString() ?? '',
        teamA: json['teamA']?.toString() ??
            json['team_a']?.toString() ??
            json['team1_name']?.toString() ??
            'TBD',
        teamB: json['teamB']?.toString() ??
            json['team_b']?.toString() ??
            json['team2_name']?.toString() ??
            'TBD',
        scheduledAt: json['scheduledAt'] != null
            ? DateTime.tryParse(json['scheduledAt'].toString())
            : (json['scheduled_at'] != null
                ? DateTime.tryParse(json['scheduled_at'].toString())
                : null),
        status: json['status']?.toString() ?? 'planned',
        winner: json['winner']?.toString(),
        parentMatchId: json['parentMatchId']?.toString() ??
            json['parent_match_id']?.toString(),
      );
    } catch (e) {
      debugPrint('Error creating MatchModel from JSON: $e');
      debugPrint('JSON: $json');
      // Return a fallback match
      return MatchModel(
        id: json['id']?.toString() ?? '0',
        teamA: 'Error',
        teamB: 'Error',
        status: 'planned',
      );
    }
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teamA': teamA,
      'teamB': teamB,
      'scheduledAt': scheduledAt?.toIso8601String(),
      'status': status,
      'winner': winner,
      'parentMatchId': parentMatchId,
    };
  }
}

class TournamentModel {
  final String id;
  final String name;
  final String status;
  final String type;
  final String dateRange;
  final String location;
  final int overs;
  final List<String> teams;
  final List<MatchModel>? matches;

  TournamentModel({
    required this.id,
    required this.name,
    required this.status,
    required this.type,
    required this.dateRange,
    required this.location,
    required this.overs,
    required this.teams,
    this.matches,
  }) {
    // Validation
    if (id.isEmpty) {
      debugPrint('Warning: TournamentModel created with empty id');
    }
    if (name.isEmpty) {
      debugPrint('Warning: TournamentModel created with empty name');
    }
    if (overs <= 0) {
      debugPrint('Warning: TournamentModel created with invalid overs: $overs');
    }
  }

  // Get tournament status enum
  TournamentStatus get tournamentStatus {
    return TournamentStatus.fromString(status);
  }

  // Check if tournament is upcoming
  bool get isUpcoming => tournamentStatus == TournamentStatus.upcoming;

  // Check if tournament is active
  bool get isActive => tournamentStatus == TournamentStatus.active;

  // Check if tournament is completed
  bool get isCompleted => tournamentStatus == TournamentStatus.completed;

  // Safe property getters
  String get safeName => name.isNotEmpty ? name : 'Unnamed Tournament';
  String get safeLocation => location.isNotEmpty ? location : 'Unknown Location';
  String get safeDateRange => dateRange.isNotEmpty ? dateRange : 'Date TBD';
  String get safeType => type.isNotEmpty ? type : 'Knockout';
  int get safeOvers => overs > 0 ? overs : 20;

  // Get team count
  int get teamCount => teams.length;

  // Get match count
  int get matchCount => matches?.length ?? 0;

  // Get completed matches count
  int get completedMatchesCount {
    if (matches == null) return 0;
    return matches!.where((m) => m.isCompleted).length;
  }

  // Get upcoming matches count
  int get upcomingMatchesCount {
    if (matches == null) return 0;
    return matches!.where((m) => m.isUpcoming).length;
  }

  // Get live matches count
  int get liveMatchesCount {
    if (matches == null) return 0;
    return matches!.where((m) => m.isLive).length;
  }

  TournamentModel copyWith({
    String? id,
    String? name,
    String? status,
    String? type,
    String? dateRange,
    String? location,
    int? overs,
    List<String>? teams,
    List<MatchModel>? matches,
    bool clearMatches = false,
  }) {
    return TournamentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      type: type ?? this.type,
      dateRange: dateRange ?? this.dateRange,
      location: location ?? this.location,
      overs: overs ?? this.overs,
      teams: teams != null ? List.from(teams) : List.from(this.teams),
      matches: clearMatches
          ? null
          : (matches != null ? List.from(matches) : this.matches),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TournamentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TournamentModel(id: $id, name: $name, status: $status, teams: ${teams.length}, matches: ${matches?.length ?? 0})';
  }

  // Create from JSON (safe parsing)
  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    try {
      // Parse teams
      final teamsList = <String>[];
      if (json['teams'] is List) {
        for (final team in json['teams']) {
          if (team is String && team.isNotEmpty) {
            teamsList.add(team);
          } else if (team is Map) {
            final teamName = team['name']?.toString() ??
                team['team_name']?.toString();
            if (teamName != null && teamName.isNotEmpty) {
              teamsList.add(teamName);
            }
          }
        }
      }

      // Parse matches
      List<MatchModel>? matchesList;
      if (json['matches'] is List) {
        matchesList = [];
        for (final match in json['matches']) {
          try {
            if (match is Map<String, dynamic>) {
              matchesList.add(MatchModel.fromJson(match));
            }
          } catch (e) {
            debugPrint('Error parsing individual match: $e');
          }
        }
      }

      return TournamentModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ??
            json['tournament_name']?.toString() ??
            'Unnamed Tournament',
        status: json['status']?.toString() ?? 'upcoming',
        type: json['type']?.toString() ??
            json['tournament_type']?.toString() ??
            'Knockout',
        dateRange: json['dateRange']?.toString() ??
            json['date_range']?.toString() ??
            'TBD',
        location: json['location']?.toString() ?? 'Unknown',
        overs: int.tryParse(json['overs']?.toString() ?? '') ?? 20,
        teams: teamsList,
        matches: matchesList,
      );
    } catch (e) {
      debugPrint('Error creating TournamentModel from JSON: $e');
      debugPrint('JSON: $json');
      // Return a fallback tournament
      return TournamentModel(
        id: json['id']?.toString() ?? '0',
        name: 'Error Loading Tournament',
        status: 'upcoming',
        type: 'Knockout',
        dateRange: 'TBD',
        location: 'Unknown',
        overs: 20,
        teams: [],
      );
    }
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'type': type,
      'dateRange': dateRange,
      'location': location,
      'overs': overs,
      'teams': teams,
      'matches': matches?.map((m) => m.toJson()).toList(),
    };
  }
}