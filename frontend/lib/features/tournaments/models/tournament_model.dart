// lib/features/tournaments/models/tournament_model.dart

class MatchModel {
  final String id;
  final String teamA;
  final String teamB;
  DateTime? scheduledAt;
  String status; // planned | completed | live

  MatchModel({
    required this.id,
    required this.teamA,
    required this.teamB,
    this.scheduledAt,
    this.status = 'planned',
  });
}

class TournamentModel {
  final String id;
  final String name;
  final String status; // ongoing | upcoming | finished
  final String type; // knockout | roundrobin etc
  final String dateRange; // e.g. "Mar 15 - Apr 20, 2024"
  final String location; // e.g. "City Stadium"
  final int overs; // number of overs per match
  final List<String> teams;
  final List<MatchModel> matches;

  TournamentModel({
    required this.id,
    required this.name,
    required this.status,
    required this.type,
    required this.dateRange,
    required this.location,
    required this.overs,
    required this.teams,
    List<MatchModel>? matches,
  }) : matches = matches ?? [];
}
