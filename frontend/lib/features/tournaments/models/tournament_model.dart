/// Enum for match status
enum MatchStatus {
  upcoming,
  live,
  completed;

  static MatchStatus fromString(String? status) {
    if (status == null || status.isEmpty) return MatchStatus.upcoming;
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
        return MatchStatus.upcoming;
    }
  }

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

/// Enum for tournament status
enum TournamentStatus {
  upcoming,
  active,
  completed;

  static TournamentStatus fromString(String? status) {
    if (status == null || status.isEmpty) return TournamentStatus.upcoming;
    switch (status.toLowerCase().trim()) {
      case 'upcoming':
      case 'not_started':
      case 'planned':
      case 'scheduled':
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
        return TournamentStatus.upcoming;
    }
  }
}

class MatchModel {
  final String id;
  final String teamA;
  final String teamB;
  final int? teamAId;
  final int? teamBId;
  final String status;
  final String? round; // [ADDED] Required for Brackets
  DateTime? scheduledAt;
  final String? winner;
  final String? parentMatchId;

  MatchModel({
    required this.id,
    required this.teamA,
    required this.teamB,
    this.teamAId,
    this.teamBId,
    this.status = 'planned',
    this.round, // [ADDED]
    this.scheduledAt,
    this.winner,
    this.parentMatchId,
  });

  MatchStatus get matchStatus => MatchStatus.fromString(status);
  bool get isUpcoming => matchStatus == MatchStatus.upcoming;
  bool get isLive => matchStatus == MatchStatus.live;
  bool get isCompleted => matchStatus == MatchStatus.completed;

  MatchModel copyWith({
    String? id,
    String? teamA,
    String? teamB,
    int? teamAId,
    int? teamBId,
    String? status,
    String? round,
    DateTime? scheduledAt,
    String? winner,
    String? parentMatchId,
  }) {
    return MatchModel(
      id: id ?? this.id,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      teamAId: teamAId ?? this.teamAId,
      teamBId: teamBId ?? this.teamBId,
      status: status ?? this.status,
      round: round ?? this.round,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      winner: winner ?? this.winner,
      parentMatchId: parentMatchId ?? this.parentMatchId,
    );
  }

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return MatchModel(
      id: json['id']?.toString() ?? '',
      teamA:
          json['teamA']?.toString() ??
          json['team_a']?.toString() ??
          json['team1_name']?.toString() ??
          'TBD',
      teamB:
          json['teamB']?.toString() ??
          json['team_b']?.toString() ??
          json['team2_name']?.toString() ??
          'TBD',
      teamAId: parseInt(json['team1_id'] ?? json['teamAId']),
      teamBId: parseInt(json['team2_id'] ?? json['teamBId']),
      status: json['status']?.toString() ?? 'planned',
      round: json['round']?.toString(), // [ADDED]
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.tryParse(json['scheduledAt'].toString())
          : (json['scheduled_at'] != null
                ? DateTime.tryParse(json['scheduled_at'].toString())
                : null),
      winner: json['winner']?.toString(),
      parentMatchId:
          json['parentMatchId']?.toString() ??
          json['parent_match_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teamA': teamA,
      'teamB': teamB,
      'teamAId': teamAId,
      'teamBId': teamBId,
      'status': status,
      'round': round, // [ADDED]
      'scheduledAt': scheduledAt?.toIso8601String(),
      'winner': winner,
      'parentMatchId': parentMatchId,
    };
  }
}

class TournamentTeam {
  final String id;
  final String name;
  final String? location;
  final String? logo;

  TournamentTeam({
    required this.id,
    required this.name,
    this.location,
    this.logo,
  });

  factory TournamentTeam.fromJson(Map<String, dynamic> json) {
    return TournamentTeam(
      id: json['id']?.toString() ?? '',
      name:
          json['name']?.toString() ??
          json['team_name']?.toString() ??
          'Unknown',
      location: json['location']?.toString(),
      logo: json['logo']?.toString() ?? json['team_logo_url']?.toString(),
    );
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
  final List<TournamentTeam> teams;
  final List<MatchModel>? matches;
  final String? createdBy;
  final String? winnerName; // [ADDED]

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
    this.createdBy,
    this.winnerName,
  });

  TournamentStatus get tournamentStatus => TournamentStatus.fromString(status);
  bool get isUpcoming => tournamentStatus == TournamentStatus.upcoming;
  bool get isActive => tournamentStatus == TournamentStatus.active;
  bool get isCompleted => tournamentStatus == TournamentStatus.completed;

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    final teamsList = <TournamentTeam>[];
    if (json['teams'] is List) {
      for (var team in json['teams']) {
        if (team is Map<String, dynamic>) {
          teamsList.add(TournamentTeam.fromJson(team));
        } else if (team is String) {
          // Handle legacy string array if necessary, though backend sends objects now
          teamsList.add(TournamentTeam(id: '', name: team));
        }
      }
    }

    final matchesList = <MatchModel>[];
    if (json['matches'] is List) {
      for (var match in json['matches']) {
        if (match is Map<String, dynamic>) {
          matchesList.add(MatchModel.fromJson(match));
        }
      }
    }

    return TournamentModel(
      id: json['id']?.toString() ?? '',
      name:
          json['name']?.toString() ??
          json['tournament_name']?.toString() ??
          'Unnamed',
      status: json['status']?.toString() ?? 'upcoming',
      type:
          json['type']?.toString() ??
          json['tournament_type']?.toString() ??
          'Knockout',
      dateRange:
          json['dateRange']?.toString() ??
          json['date_range']?.toString() ??
          'TBD',
      location: json['location']?.toString() ?? 'Unknown',
      overs: int.tryParse(json['overs']?.toString() ?? '') ?? 20,
      teams: teamsList,
      matches: matchesList.isNotEmpty ? matchesList : null,
      createdBy:
          json['created_by']?.toString() ?? json['creator_id']?.toString(),
      winnerName: json['winner_name']?.toString(), // [ADDED]
    );
  }
}
