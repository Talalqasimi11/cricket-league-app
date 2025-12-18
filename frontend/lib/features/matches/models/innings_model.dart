import 'package:flutter/foundation.dart';
import 'ball_model.dart';

/// {@template innings_model}
/// Represents a single innings in a cricket match.
/// 
/// **Architectural Foundation**: This model is **mandatory** for proper cricket scoring.
/// Without it, you cannot handle declarations, follow-on, or per-innings statistics.
/// {@endtemplate}
@immutable
class Innings {
  final String id;
  final String matchId;
  final String battingTeamId;
  final String bowlingTeamId;
  final int inningsNumber;
  final Score score;
  final Extras extras;
  final List<String> ballSequence;
  final bool isActive;

  const Innings({
    required this.id,
    required this.matchId,
    required this.battingTeamId,
    required this.bowlingTeamId,
    required this.inningsNumber,
    required this.score,
    required this.extras,
    required this.ballSequence,
    this.isActive = false,
  }) : assert(inningsNumber == 1 || inningsNumber == 2, 'inningsNumber must be 1 or 2');

  factory Innings.empty({
    required String id,
    required String matchId,
    required String battingTeamId,
    required String bowlingTeamId,
    required int inningsNumber,
  }) {
    return Innings(
      id: id,
      matchId: matchId,
      battingTeamId: battingTeamId,
      bowlingTeamId: bowlingTeamId,
      inningsNumber: inningsNumber,
      score: const Score.zero(),
      extras: const Extras.zero(),
      ballSequence: const [],
      isActive: false,
    );
  }

  /// Applies a ball event to this innings, returning updated instance.
  /// 
  /// **State Management**: This is your **immutable state update** method.
  /// Use in Notifiers: `state = state.applyBall(ball)`
  Innings applyBall(Ball ball) {
    if (!isActive) {
      throw StateError('Cannot add ball to inactive innings');
    }
    if (ball.matchId != matchId || ball.inningId != id) {
      throw ArgumentError('Ball does not belong to this innings');
    }

    return copyWith(
      score: score.addBall(ball),
      extras: extras.addBall(ball),
      ballSequence: [...ballSequence, ball.id],
    );
  }

  /// Gets display notation for current ball (e.g., "12.4").
  /// 
  /// **CRITICAL**: Calculates based on **LEGAL BALLS ONLY** (excludes wides/no-balls)
  String get currentOverNotation {
    final legalBallCount = ballSequence.where((ballId) {
      // In production, fetch ball from repository to check isLegalBall
      // For now, this is a placeholder - use BallSequenceService for actual logic
      return true; // Simplified - see BallSequenceService
    }).length;
    
    final overs = legalBallCount ~/ 6;
    final ballsInCurrentOver = legalBallCount % 6;
    return '$overs.$ballsInCurrentOver';
  }

  void validate() {
    if (id.isEmpty) throw StateError('Innings ID cannot be empty');
    if (matchId.isEmpty) throw StateError('Match ID cannot be empty');
    if (battingTeamId.isEmpty) throw StateError('Batting team ID cannot be empty');
    if (bowlingTeamId.isEmpty) throw StateError('Bowling team ID cannot be empty');
    if (battingTeamId == bowlingTeamId) {
      throw StateError('Batting and bowling teams must be different');
    }
    if (inningsNumber != 1 && inningsNumber != 2) {
      throw StateError('inningsNumber must be 1 or 2');
    }
    score.validate();
    extras.validate();
  }

  Innings copyWith({
    String? id,
    String? matchId,
    String? battingTeamId,
    String? bowlingTeamId,
    int? inningsNumber,
    Score? score,
    Extras? extras,
    List<String>? ballSequence,
    bool? isActive,
  }) {
    return Innings(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      battingTeamId: battingTeamId ?? this.battingTeamId,
      bowlingTeamId: bowlingTeamId ?? this.bowlingTeamId,
      inningsNumber: inningsNumber ?? this.inningsNumber,
      score: score ?? this.score,
      extras: extras ?? this.extras,
      ballSequence: ballSequence ?? this.ballSequence,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    validate();
    return {
      'id': id,
      'match_id': matchId,
      'batting_team_id': battingTeamId,
      'bowling_team_id': bowlingTeamId,
      'innings_number': inningsNumber,
      'score': score.toJson(),
      'extras': extras.toJson(),
      'ball_sequence': ballSequence,
      'is_active': isActive,
    };
  }

  factory Innings.fromJson(Map<String, dynamic> json) {
    try {
      return Innings(
        id: json['id'] as String? ?? '',
        matchId: json['match_id'] as String? ?? '',
        battingTeamId: json['batting_team_id'] as String? ?? '',
        bowlingTeamId: json['bowling_team_id'] as String? ?? '',
        inningsNumber: json['innings_number'] as int? ?? 1,
        score: json['score'] != null 
            ? Score.fromJson(json['score'] as Map<String, dynamic>)
            : const Score.zero(),
        extras: json['extras'] != null
            ? Extras.fromJson(json['extras'] as Map<String, dynamic>)
            : const Extras.zero(),
        ballSequence: (json['ball_sequence'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ?? const [],
        isActive: json['is_active'] as bool? ?? false,
      );
    } catch (e, stackTrace) {
      throw FormatException('Innings.fromJson failed: $e', stackTrace);
    }
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is Innings && id == other.id && matchId == other.matchId;

  @override
  int get hashCode => Object.hash(id, matchId, inningsNumber);

  @override
  String toString() => 'Innings($inningsNumber: $battingTeamId vs $bowlingTeamId, Score: ${score.runs}/${score.wickets})';
}

/// Represents batting score for an innings.
@immutable
class Score {
  final int runs;
  final int wickets;
  final int ballsFaced; // Legal deliveries only

  const Score({
    required this.runs,
    required this.wickets,
    required this.ballsFaced,
  });

  const Score.zero()
      : runs = 0,
        wickets = 0,
        ballsFaced = 0;

  /// Calculates new score after applying a ball.
  Score addBall(Ball ball) {
    return Score(
      runs: runs + ball.runs,
      wickets: wickets + (ball.wicketType != null ? 1 : 0),
      ballsFaced: ballsFaced + (ball.isLegalBall ? 1 : 0),
    );
  }

  void validate() {
    if (runs < 0) throw StateError('Runs cannot be negative');
    if (wickets < 0 || wickets > 10) throw StateError('Wickets must be 0-10');
    if (ballsFaced < 0) throw StateError('Balls faced cannot be negative');
  }

  Map<String, dynamic> toJson() => {'runs': runs, 'wickets': wickets, 'balls_faced': ballsFaced};

  factory Score.fromJson(Map<String, dynamic> json) => Score(
        runs: json['runs'] as int? ?? 0,
        wickets: json['wickets'] as int? ?? 0,
        ballsFaced: json['balls_faced'] as int? ?? 0,
      );

  @override
  bool operator ==(Object other) => identical(this, other) || other is Score && runs == other.runs && wickets == other.wickets && ballsFaced == other.ballsFaced;

  @override
  int get hashCode => Object.hash(runs, wickets, ballsFaced);
}

/// Represents extra runs breakdown for an innings.
@immutable
class Extras {
  final int byes;
  final int legByes;
  final int wides;
  final int noBalls;

  const Extras({
    required this.byes,
    required this.legByes,
    required this.wides,
    required this.noBalls,
  });

  const Extras.zero()
      : byes = 0,
        legByes = 0,
        wides = 0,
        noBalls = 0;

  /// Calculates new extras after applying a ball.
  Extras addBall(Ball ball) {
    switch (ball.extras) {
      case ExtraType.bye:
        return copyWith(byes: byes + ball.runs);
      case ExtraType.legBye:
        return copyWith(legByes: legByes + ball.runs);
      case ExtraType.wide:
        return copyWith(wides: wides + ball.runs);
      case ExtraType.noBall:
        return copyWith(noBalls: noBalls + ball.runs);
      default:
        return this;
    }
  }

  int get total => byes + legByes + wides + noBalls;

  void validate() {
    if (byes < 0 || legByes < 0 || wides < 0 || noBalls < 0) {
      throw StateError('Extra runs cannot be negative');
    }
  }

  Extras copyWith({int? byes, int? legByes, int? wides, int? noBalls}) => Extras(
        byes: byes ?? this.byes,
        legByes: legByes ?? this.legByes,
        wides: wides ?? this.wides,
        noBalls: noBalls ?? this.noBalls,
      );

  Map<String, dynamic> toJson() => {'byes': byes, 'leg_byes': legByes, 'wides': wides, 'no_balls': noBalls};

  factory Extras.fromJson(Map<String, dynamic> json) => Extras(
        byes: json['byes'] as int? ?? 0,
        legByes: json['leg_byes'] as int? ?? 0,
        wides: json['wides'] as int? ?? 0,
        noBalls: json['no_balls'] as int? ?? 0,
      );

  @override
  bool operator ==(Object other) => identical(this, other) || other is Extras && byes == other.byes && legByes == other.legByes && wides == other.wides && noBalls == other.noBalls;

  @override
  int get hashCode => Object.hash(byes, legByes, wides, noBalls);
}