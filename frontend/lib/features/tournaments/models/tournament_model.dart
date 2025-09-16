// lib/features/tournaments/models/tournament_model.dart

class MatchModel {
  final String id;
  final String teamA;
  final String teamB;
  DateTime? scheduledAt;
  String status; // planned | completed | live
  String? winner; // <-- NEW field

  MatchModel({
    required this.id,
    required this.teamA,
    required this.teamB,
    this.scheduledAt,
    this.status = 'planned',
    this.winner, // optional
  });

  MatchModel copyWith({
    String? id,
    String? teamA,
    String? teamB,
    DateTime? scheduledAt,
    String? status,
    String? winner,
  }) {
    return MatchModel(
      id: id ?? this.id,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      winner: winner ?? this.winner,
    );
  }
}

class TournamentModel {
  final String id;
  final String name;
  final String status; // ongoing | upcoming | finished
  final String type; // knockout | roundrobin etc
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
  });

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
  }) {
    return TournamentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      type: type ?? this.type,
      dateRange: dateRange ?? this.dateRange,
      location: location ?? this.location,
      overs: overs ?? this.overs,
      teams: teams ?? this.teams,
      matches: matches ?? this.matches,
    );
  }
}
