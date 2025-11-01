class PlayerMatchStats {
  final int id;
  final int matchId;
  final int playerId;
  final String playerName;
  final int? runs;
  final int? balls;
  final int? fours;
  final int? sixes;
  final int? wickets;
  final int? maidens;
  final double? runsGiven;
  final String role; // batsman, bowler, fielder
  final bool? isOut;
  final String? dismissalMode;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlayerMatchStats({
    required this.id,
    required this.matchId,
    required this.playerId,
    required this.playerName,
    this.runs,
    this.balls,
    this.fours,
    this.sixes,
    this.wickets,
    this.maidens,
    this.runsGiven,
    required this.role,
    this.isOut,
    this.dismissalMode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlayerMatchStats.fromJson(Map<String, dynamic> json) {
    return PlayerMatchStats(
      id: json['id'] as int? ?? 0,
      matchId: json['match_id'] as int? ?? 0,
      playerId: json['player_id'] as int? ?? 0,
      playerName: json['player_name'] as String? ?? '',
      runs: json['runs'] as int?,
      balls: json['balls'] as int?,
      fours: json['fours'] as int?,
      sixes: json['sixes'] as int?,
      wickets: json['wickets'] as int?,
      maidens: json['maidens'] as int?,
      runsGiven: (json['runs_given'] as num?)?.toDouble(),
      role: json['role'] as String? ?? 'fielder',
      isOut: json['is_out'] as bool?,
      dismissalMode: json['dismissal_mode'] as String?,
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
      'match_id': matchId,
      'player_id': playerId,
      'player_name': playerName,
      'runs': runs,
      'balls': balls,
      'fours': fours,
      'sixes': sixes,
      'wickets': wickets,
      'maidens': maidens,
      'runs_given': runsGiven,
      'role': role,
      'is_out': isOut,
      'dismissal_mode': dismissalMode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  double get strikeRate =>
      balls != null && balls! > 0 ? ((runs ?? 0) / balls!) * 100 : 0;

  double get battingAverage =>
      wickets != null && wickets! > 0 ? (runs ?? 0) / wickets! : 0;
}
