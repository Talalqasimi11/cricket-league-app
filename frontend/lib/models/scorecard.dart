class Scorecard {
  final int id;
  final int matchId;
  final String team1Name;
  final int team1Score;
  final int team1Wickets;
  final int team1Overs;
  final String team2Name;
  final int team2Score;
  final int team2Wickets;
  final int team2Overs;
  final String result;
  final String? manOfTheMatch;
  final int? manOfTheMatchId;
  final List<String>? highlights;
  final DateTime createdAt;
  final DateTime updatedAt;

  Scorecard({
    required this.id,
    required this.matchId,
    required this.team1Name,
    required this.team1Score,
    required this.team1Wickets,
    required this.team1Overs,
    required this.team2Name,
    required this.team2Score,
    required this.team2Wickets,
    required this.team2Overs,
    required this.result,
    this.manOfTheMatch,
    this.manOfTheMatchId,
    this.highlights,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Scorecard.fromJson(Map<String, dynamic> json) {
    return Scorecard(
      id: json['id'] as int? ?? 0,
      matchId: json['match_id'] as int? ?? 0,
      team1Name: json['team1_name'] as String? ?? '',
      team1Score: json['team1_score'] as int? ?? 0,
      team1Wickets: json['team1_wickets'] as int? ?? 0,
      team1Overs: json['team1_overs'] as int? ?? 0,
      team2Name: json['team2_name'] as String? ?? '',
      team2Score: json['team2_score'] as int? ?? 0,
      team2Wickets: json['team2_wickets'] as int? ?? 0,
      team2Overs: json['team2_overs'] as int? ?? 0,
      result: json['result'] as String? ?? '',
      manOfTheMatch: json['man_of_the_match'] as String?,
      manOfTheMatchId: json['man_of_the_match_id'] as int?,
      highlights: (json['highlights'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
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
      'team1_name': team1Name,
      'team1_score': team1Score,
      'team1_wickets': team1Wickets,
      'team1_overs': team1Overs,
      'team2_name': team2Name,
      'team2_score': team2Score,
      'team2_wickets': team2Wickets,
      'team2_overs': team2Overs,
      'result': result,
      'man_of_the_match': manOfTheMatch,
      'man_of_the_match_id': manOfTheMatchId,
      'highlights': highlights,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
