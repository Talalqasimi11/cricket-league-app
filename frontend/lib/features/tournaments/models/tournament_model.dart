// lib/features/tournaments/models/tournament_model.dart

/// Standardized status enum for tournament matches
enum MatchStatus {
  upcoming,
  live,
  completed;

  static MatchStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
      case 'not_started':
      case 'planned':
        return MatchStatus.upcoming;
      case 'live':
      case 'active':
        return MatchStatus.live;
      case 'completed':
      case 'finished':
        return MatchStatus.completed;
      default:
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
}

/// Standardized status enum for tournaments
enum TournamentStatus {
  upcoming,
  active,
  completed;

  static TournamentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
      case 'not_started':
        return TournamentStatus.upcoming;
      case 'active':
      case 'ongoing':
      case 'live':
        return TournamentStatus.active;
      case 'completed':
      case 'finished':
        return TournamentStatus.completed;
      default:
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
}

class MatchModel {
  final String id; // Backend numeric ID as string
  final String teamA;
  final String teamB;
  DateTime? scheduledAt;
  String status; // planned | completed | live
  String? winner; // <-- NEW field
  String? parentMatchId; // <-- NEW field for linking to actual match

  // Computed display ID for UI
  String get displayId {
    // Extract numeric part or use full ID
    final numericMatch = RegExp(r'(\d+)').firstMatch(id);
    return numericMatch?.group(1) ?? id;
  }

  MatchModel({
    required this.id,
    required this.teamA,
    required this.teamB,
    this.scheduledAt,
    this.status = 'planned',
    this.winner, // optional
    this.parentMatchId, // optional
  });

  MatchModel copyWith({
    String? id,
    String? teamA,
    String? teamB,
    DateTime? scheduledAt,
    String? status,
    String? winner,
    String? parentMatchId,
  }) {
    return MatchModel(
      id: id ?? this.id,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      winner: winner ?? this.winner,
      parentMatchId: parentMatchId ?? this.parentMatchId,
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
