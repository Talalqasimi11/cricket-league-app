class BallByBall {
  final int id;
  final int matchId;
  final int inningsId;
  final int overNumber;
  final int ballNumber;
  final int sequence; // NEW: sequence for multiple events per delivery
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
    required this.sequence,
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
      inningsId: json['innings_id'] as int? ?? json['inning_id'] as int? ?? 0,
      overNumber: json['over_number'] as int? ?? 0,
      ballNumber: json['ball_number'] as int? ?? 0,
      sequence: json['sequence'] as int? ?? 0,
      batsmanName: json['batsman_name'] as String? ?? '',
      batsmanId: json['batsman_id'] as int? ?? 0,
      bowlerName: json['bowler_name'] as String? ?? '',
      bowlerId: json['bowler_id'] as int? ?? 0,
      runs: json['runs'] as int? ?? 0,
      isWicket: json['is_wicket'] as bool? ?? (json['wicket_type'] != null),
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
      'sequence': sequence,
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

  /// Display over.ball with extras suffix
  /// Examples: "3.2", "3.2wd", "3.2nb"
  String get ballDisplay {
    String base = '$overNumber.$ballNumber';
    if (extras == 'wide') return '${base}wd';
    if (extras == 'no-ball') return '${base}nb';
    if (extras == 'bye') return '${base}b';
    if (extras == 'leg-bye') return '${base}lb';
    return base;
  }

  /// Check if this is a legal delivery (counts toward over progression)
  bool get isLegalDelivery => extras != 'wide' && extras != 'no-ball';
}
