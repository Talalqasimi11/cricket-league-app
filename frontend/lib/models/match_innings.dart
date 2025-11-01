class MatchInnings {
  final int id;
  final int matchId;
  final int inningsNumber;
  final int battingTeamId;
  final String battingTeamName;
  final int bowlingTeamId;
  final String bowlingTeamName;
  final int? totalRuns;
  final int? totalWickets;
  final int? totalBalls;
  final bool? isComplete;
  final DateTime createdAt;
  final DateTime updatedAt;

  MatchInnings({
    required this.id,
    required this.matchId,
    required this.inningsNumber,
    required this.battingTeamId,
    required this.battingTeamName,
    required this.bowlingTeamId,
    required this.bowlingTeamName,
    this.totalRuns,
    this.totalWickets,
    this.totalBalls,
    this.isComplete,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MatchInnings.fromJson(Map<String, dynamic> json) {
    return MatchInnings(
      id: json['id'] as int? ?? 0,
      matchId: json['match_id'] as int? ?? 0,
      inningsNumber: json['innings_number'] as int? ?? 1,
      battingTeamId: json['batting_team_id'] as int? ?? 0,
      battingTeamName: json['batting_team_name'] as String? ?? '',
      bowlingTeamId: json['bowling_team_id'] as int? ?? 0,
      bowlingTeamName: json['bowling_team_name'] as String? ?? '',
      totalRuns: json['total_runs'] as int?,
      totalWickets: json['total_wickets'] as int?,
      totalBalls: json['total_balls'] as int?,
      isComplete: json['is_complete'] as bool?,
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
      'innings_number': inningsNumber,
      'batting_team_id': battingTeamId,
      'batting_team_name': battingTeamName,
      'bowling_team_id': bowlingTeamId,
      'bowling_team_name': bowlingTeamName,
      'total_runs': totalRuns,
      'total_wickets': totalWickets,
      'total_balls': totalBalls,
      'is_complete': isComplete,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  double get runRate => totalBalls != null && totalBalls! > 0
      ? (totalRuns ?? 0) / totalBalls! * 6
      : 0;
}
