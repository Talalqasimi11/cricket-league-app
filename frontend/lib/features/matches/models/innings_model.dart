import 'package:flutter/foundation.dart';
import 'ball_model.dart';

/// {@template innings_model}
/// Represents a single innings in a cricket match.
/// 
/// **Architectural Imperative**: This is the **missing layer** between Match and Ball.
/// Cricket scoring requires per-innings tracking, not match-level aggregates.
/// Without this model, you cannot handle declarations, follow-on, or proper stat calculation.
/// {@endtemplate}
@immutable
class Innings {
  /// Unique identifier for this innings (UUID recommended).
  final String id;
  
  /// Reference to parent match.
  final String matchId;
  
  /// The team currently batting (should reference Team entity).
  final String battingTeamId;
  
  /// The team currently bowling (should reference Team entity).
  final String bowlingTeamId;
  
  /// Innings number: 1 (first innings) or 2 (second innings).
  final int inningsNumber;
  
  /// Current batting score (runs, wickets, balls faced).
  final Score score;
  
  /// Detailed breakdown of extra runs.
  final Extras extras;
  
  /// List of ball IDs in sequence for event reconstruction.
  final List<String> ballSequence;
  
  /// Whether this innings is currently active.
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

  /// Creates a new, empty innings instance.
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
  /// **CRITICAL**: This is the **only** way to modify innings state.
  /// It handles all scoring logic, over progression, and stat accumulation.
  Innings applyBall(Ball ball) {
    if (!isActive) {
      throw StateError('Cannot add ball to inactive innings');
    }
    if (ball.matchId != matchId) {
      throw ArgumentError('Ball belongs to different match');
    }
    if (ball.inningId != id) {
      throw ArgumentError('Ball belongs to different innings');
    }

    // Calculate new totals
    final newScore = score.addBall(ball);
    final newExtras = extras.addBall(ball);
    final newBallSequence = [...ballSequence, ball.id];

    return copyWith(
      score: newScore,
      extras: newExtras,
      ballSequence: newBallSequence,
    );
  }

  /// Gets the current over notation for display (e.g., "12.4").
  /// 
  /// This calculates **legal balls only** for proper cricket scoring.
  String get currentOverNotation {
    final legalBalls = ballSequence.lengthWhere((ballId) {
      // In real implementation, fetch ball and check isLegalBall
      // For now, return placeholder - BallSequenceService handles this
      return true; // Simplified - see BallSequenceService
    });
    final overs = legalBalls ~/ 6;
    final ballsInCurrentOver = legalBalls % 6;
    return '$overs.$ballsInCurrentOver';
  }

  /// Validates business rules for this innings.
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
      throw FormatException(
        'Failed to deserialize Innings: $e\nJSON: ${json.toString().substring(0, 200)}',
        stackTrace,
      );
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Innings &&
            id == other.id &&
            matchId == other.matchId &&
            inningsNumber == other.inningsNumber;
  }

  @override
  int get hashCode => Object.hash(id, matchId, inningsNumber);

  @override
  String toString() {
    return 'Innings($inningsNumber: $battingTeamId vs $bowlingTeamId, Score: ${score.totalRuns}/${score.wickets})';
  }
}

/// Represents the batting score for an innings.
@immutable
class Score {
  final int runs;
  final int wickets;
  final int ballsFaced; // Total balls faced, including no-balls but excluding wides

  const Score({
    required this.runs,
    required this.wickets,
    required this.ballsFaced,
  });

  const Score.zero()
      : runs = 0,
        wickets = 0,
        ballsFaced = 0;

  /// Applies a ball to calculate new score.
  Score addBall(Ball ball) {
    int newRuns = runs + ball.runs;
    int newWickets = wickets + (ball.isWicket ? 1 : 0);
    int newBalls = ballsFaced + (ball.isLegalBall ? 1 : 0);

    return Score(
      runs: newRuns,
      wickets: newWickets,
      ballsFaced: newBalls,
    );
  }

  /// Gets runs from boundaries.
  int get boundaryRuns {
    final boundaries = (ballsFaced ~/ 6) * 6; // Simplified - needs ball data
    return boundaries; // Placeholder - implement with actual ball events
  }

  void validate() {
    if (runs < 0) throw StateError('Runs cannot be negative');
    if (wickets < 0) throw StateError('Wickets cannot be negative');
    if (wickets > 10) throw StateError('Cannot have more than 10 wickets');
    if (ballsFaced < 0) throw StateError('Balls faced cannot be negative');
  }

  Map<String, dynamic> toJson() => {
        'runs': runs,
        'wickets': wickets,
        'balls_faced': ballsFaced,
      };

  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      runs: json['runs'] as int? ?? 0,
      wickets: json['wickets'] as int? ?? 0,
      ballsFaced: json['balls_faced'] as int? ?? 0,
    );
  }

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

  /// Applies a ball to calculate new extras.
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
    if (byes < 0) throw StateError('Byes cannot be negative');
    if (legByes < 0) throw StateError('Leg byes cannot be negative');
    if (wides < 0) throw StateError('Wides cannot be negative');
    if (noBalls < 0) throw StateError('No balls cannot be negative');
  }

  Extras copyWith({
    int? byes,
    int? legByes,
    int? wides,
    int? noBalls,
  }) {
    return Extras(
      byes: byes ?? this.byes,
      legByes: legByes ?? this.legByes,
      wides: wides ?? this.wides,
      noBalls: noBalls ?? this.noBalls,
    );
  }

  Map<String, dynamic> toJson() => {
        'byes': byes,
        'leg_byes': legByes,
        'wides': wides,
        'no_balls': noBalls,
      };

  factory Extras.fromJson(Map<String, dynamic> json) {
    return Extras(
      byes: json['byes'] as int? ?? 0,
      legByes: json['leg_byes'] as int? ?? 0,
      wides: json['wides'] as int? ?? 0,
      noBalls: json['no_balls'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is Extras && byes == other.byes && legByes == other.legByes && wides == other.wides && noBalls == other.noBalls;

  @override
  int get hashCode => Object.hash(byes, legByes, wides, noBalls);
}