class TeamTournamentSummary {
  final int id;
  final int tournamentId;
  final String tournamentName;
  final int teamId;
  final String teamName;
  final int matchesPlayed;
  final int matchesWon;
  final int matchesLost;
  final int? matchesDraw;
  final int points;
  final int netRunRate;
  final int position;
  final bool registered;
  final DateTime registeredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  TeamTournamentSummary({
    required this.id,
    required this.tournamentId,
    required this.tournamentName,
    required this.teamId,
    required this.teamName,
    required this.matchesPlayed,
    required this.matchesWon,
    required this.matchesLost,
    this.matchesDraw,
    required this.points,
    required this.netRunRate,
    required this.position,
    required this.registered,
    required this.registeredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeamTournamentSummary.fromJson(Map<String, dynamic> json) {
    return TeamTournamentSummary(
      id: json['id'] as int? ?? 0,
      tournamentId: json['tournament_id'] as int? ?? 0,
      tournamentName: json['tournament_name'] as String? ?? '',
      teamId: json['team_id'] as int? ?? 0,
      teamName: json['team_name'] as String? ?? '',
      matchesPlayed: json['matches_played'] as int? ?? 0,
      matchesWon: json['matches_won'] as int? ?? 0,
      matchesLost: json['matches_lost'] as int? ?? 0,
      matchesDraw: json['matches_draw'] as int?,
      points: json['points'] as int? ?? 0,
      netRunRate: json['net_run_rate'] as int? ?? 0,
      position: json['position'] as int? ?? 0,
      registered: json['registered'] as bool? ?? false,
      registeredAt:
          DateTime.tryParse(json['registered_at'] as String? ?? '') ??
          DateTime.now(),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'tournament_name': tournamentName,
      'team_id': teamId,
      'team_name': teamName,
      'matches_played': matchesPlayed,
      'matches_won': matchesWon,
      'matches_lost': matchesLost,
      'matches_draw': matchesDraw,
      'points': points,
      'net_run_rate': netRunRate,
      'position': position,
      'registered': registered,
      'registered_at': registeredAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  double get winPercentage =>
      matchesPlayed > 0 ? (matchesWon / matchesPlayed) * 100 : 0;
}
