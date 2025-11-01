class BallByBall {
  final int id;
  final int matchId;
  final int inningsId;
  final int overNumber;
  final int ballNumber;
  final String batsmanName;
  final int batsmanId;
  final String bowlerName;
  final int bowlerId;
  final int runs;
  final bool isWicket;
  final String? wicketType; // bowled, lbw, caught, run out, etc.
  final String? extras; // wide, no-ball, bye, leg-bye
  final String? commentary;
  final DateTime createdAt;
  final DateTime updatedAt;

  BallByBall({
    required this.id,
    required this.matchId,
    required this.inningsId,
    required this.overNumber,
    required this.ballNumber,
    required this.batsmanName,
    required this.batsmanId,
    required this.bowlerName,
    required this.bowlerId,
    required this.runs,
    required this.isWicket,
    this.wicketType,
    this.extras,
    this.commentary,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BallByBall.fromJson(Map<String, dynamic> json) {
    return BallByBall(
      id: json['id'] as int? ?? 0,
      matchId: json['match_id'] as int? ?? 0,
      inningsId: json['innings_id'] as int? ?? 0,
      overNumber: json['over_number'] as int? ?? 0,
      ballNumber: json['ball_number'] as int? ?? 0,
      batsmanName: json['batsman_name'] as String? ?? '',
      batsmanId: json['batsman_id'] as int? ?? 0,
      bowlerName: json['bowler_name'] as String? ?? '',
      bowlerId: json['bowler_id'] as int? ?? 0,
      runs: json['runs'] as int? ?? 0,
      isWicket: json['is_wicket'] as bool? ?? false,
      wicketType: json['wicket_type'] as String?,
      extras: json['extras'] as String?,
      commentary: json['commentary'] as String?,
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
      'innings_id': inningsId,
      'over_number': overNumber,
      'ball_number': ballNumber,
      'batsman_name': batsmanName,
      'batsman_id': batsmanId,
      'bowler_name': bowlerName,
      'bowler_id': bowlerId,
      'runs': runs,
      'is_wicket': isWicket,
      'wicket_type': wicketType,
      'extras': extras,
      'commentary': commentary,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get ballDisplay => '$overNumber.${ballNumber + 1}';
}
