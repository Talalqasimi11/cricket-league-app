import 'package:flutter/foundation.dart';

/// The type of extra runs conceded on a delivery.
enum ExtraType {
  wide,
  noBall,
  bye,
  legBye;

  /// Parses API string value to [ExtraType].
  static ExtraType? fromApiString(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return switch (value.toLowerCase().trim()) {
      'wide' => ExtraType.wide,
      'no-ball' => ExtraType.noBall,
      'bye' => ExtraType.bye,
      'leg-bye' => ExtraType.legBye,
      _ => throw FormatException('Invalid extra type: $value'),
    };
  }

  /// Converts to API-compatible string format.
  String get apiValue => switch (this) {
        ExtraType.wide => 'wide',
        ExtraType.noBall => 'no-ball',
        ExtraType.bye => 'bye',
        ExtraType.legBye => 'leg-bye',
      };
}

/// The method by which a batsman is dismissed.
enum WicketType {
  bowled,
  caught,
  lbw,
  runOut,
  stumped,
  hitWicket;

  /// Parses API string value to [WicketType].
  static WicketType? fromApiString(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return switch (value.toLowerCase().trim()) {
      'bowled' => WicketType.bowled,
      'caught' => WicketType.caught,
      'lbw' => WicketType.lbw,
      'run-out' => WicketType.runOut,
      'stumped' => WicketType.stumped,
      'hit-wicket' => WicketType.hitWicket,
      _ => throw FormatException('Invalid wicket type: $value'),
    };
  }

  /// Converts to API-compatible string format.
  String get apiValue => switch (this) {
        WicketType.bowled => 'bowled',
        WicketType.caught => 'caught',
        WicketType.lbw => 'lbw',
        WicketType.runOut => 'run-out',
        WicketType.stumped => 'stumped',
        WicketType.hitWicket => 'hit-wicket',
      };
}

/// {@template ball_model}
/// Represents a single ball delivery in cricket.
/// 
/// **CRITICAL FIX**: `ballNumber` is NO LONGER constrained to 1-6.
/// After wides/no-balls, ballNumber increments beyond 6 (e.g., 6, 7, 8...).
/// Use `BallSequenceService` to calculate actual over notation for display.
/// 
/// **New Fields**:
/// - `sequenceNumber`: Absolute order (0,1,2,3...) for event sourcing
/// - `isLegitBall`: Whether this counts toward the 6-ball over
/// {@endtemplate}
@immutable
class Ball {
  final String id; // UUID for idempotency
  final String matchId;
  final String inningId;
  
  /// Absolute sequence number (0 = first ball of innings).
  final int sequenceNumber;
  
  /// Display ball number (1,2,3... increases beyond 6 after wides/no-balls).
  final int ballNumber;
  
  final int overNumber; // 0-based
  
  final int batsmanId;
  final String? batsmanName;
  final int bowlerId;
  final String? bowlerName;
  final int runs;
  final ExtraType? extras;
  final WicketType? wicketType;
  final int? outPlayerId;
  final String? outPlayerName;
  
  /// Whether this ball counts as a legal delivery (false for wides/no-balls).
  final bool isLegalBall;

  const Ball({
    required this.id,
    required this.matchId,
    required this.inningId,
    required this.sequenceNumber,
    required this.overNumber,
    required this.ballNumber,
    required this.batsmanId,
    this.batsmanName,
    required this.bowlerId,
    this.bowlerName,
    required this.runs,
    this.extras,
    this.wicketType,
    this.outPlayerId,
    this.outPlayerName,
  }) : isLegalBall = extras == null || (extras != ExtraType.wide && extras != ExtraType.noBall),
       assert(sequenceNumber >= 0, 'sequenceNumber must be >= 0'),
       assert(overNumber >= 0, 'overNumber must be >= 0'),
       assert(ballNumber >= 1, 'ballNumber must be >= 1'),
       assert(runs >= 0, 'runs cannot be negative');

  /// Gets display notation (e.g., "12.3" for 12 overs, 3 balls).
  /// 
  /// **WARNING**: This is APPROXIMATE. Use `BallSequenceService.getCurrentOverNotation()`
  /// for precise calculation that handles wides/no-balls correctly.
  String get displayOverNotation => '$overNumber.$ballNumber';

  /// Creates a copy with optional field overrides.
  Ball copyWith({
    String? id,
    String? matchId,
    String? inningId,
    int? sequenceNumber,
    int? overNumber,
    int? ballNumber,
    int? batsmanId,
    String? batsmanName,
    int? bowlerId,
    String? bowlerName,
    int? runs,
    ExtraType? extras,
    WicketType? wicketType,
    int? outPlayerId,
    String? outPlayerName,
  }) {
    return Ball(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      inningId: inningId ?? this.inningId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      overNumber: overNumber ?? this.overNumber,
      ballNumber: ballNumber ?? this.ballNumber,
      batsmanId: batsmanId ?? this.batsmanId,
      batsmanName: batsmanName ?? this.batsmanName,
      bowlerId: bowlerId ?? this.bowlerId,
      bowlerName: bowlerName ?? this.bowlerName,
      runs: runs ?? this.runs,
      extras: extras ?? this.extras,
      wicketType: wicketType ?? this.wicketType,
      outPlayerId: outPlayerId ?? this.outPlayerId,
      outPlayerName: outPlayerName ?? this.outPlayerName,
    );
  }

  /// Deserializes from JSON/Map with strict validation.
  factory Ball.fromJson(Map<String, dynamic> json) {
    try {
      final extrasValue = ExtraType.fromApiString(json['extras'] as String?);
      final wicketValue = WicketType.fromApiString(json['wicket_type'] as String?);
      
      return Ball(
        id: json['id'] as String? ?? '',
        matchId: json['match_id'] as String? ?? '',
        inningId: json['inning_id'] as String? ?? '',
        sequenceNumber: json['sequence_number'] as int? ?? 0,
        overNumber: json['over_number'] as int? ?? 0,
        ballNumber: json['ball_number'] as int? ?? 1,
        batsmanId: json['batsman_id'] as int? ?? 0,
        batsmanName: json['batsman_name'] as String?,
        bowlerId: json['bowler_id'] as int? ?? 0,
        bowlerName: json['bowler_name'] as String?,
        runs: json['runs'] as int? ?? 0,
        extras: extrasValue,
        wicketType: wicketValue,
        outPlayerId: json['out_player_id'] as int?,
        outPlayerName: json['out_player_name'] as String?,
      );
    } catch (e, stackTrace) {
      throw FormatException(
        'Ball.fromJson failed: $e\nJSON: ${json.toString().substring(0, 200)}',
        stackTrace,
      );
    }
  }

  /// Serializes to JSON for API submission with validation.
  Map<String, dynamic> toJson() {
    validate();
    
    return {
      'id': id,
      'match_id': matchId,
      'inning_id': inningId,
      'sequence_number': sequenceNumber,
      'over_number': overNumber,
      'ball_number': ballNumber,
      'batsman_id': batsmanId,
      'bowler_id': bowlerId,
      'runs': runs,
      'extras': extras?.apiValue,
      'wicket_type': wicketType?.apiValue,
      'out_player_id': outPlayerId,
      'out_player_name': outPlayerName,
    };
  }

  /// Validates all business rules for this ball.
  void validate() {
    // Core requirements
    if (id.isEmpty) throw StateError('Ball ID cannot be empty');
    if (matchId.isEmpty) throw StateError('Match ID cannot be empty');
    if (inningId.isEmpty) throw StateError('Inning ID cannot be empty');
    if (sequenceNumber < 0) throw StateError('sequenceNumber must be >= 0');
    if (overNumber < 0) throw StateError('Over number cannot be negative');
    if (ballNumber < 1) throw StateError('Ball number must be >= 1');
    if (batsmanId <= 0) throw StateError('Batsman ID must be positive');
    if (bowlerId <= 0) throw StateError('Bowler ID must be positive');

    // Scoring rules
    if (runs < 0) throw StateError('Runs cannot be negative');
    
    // Extras validation (enforces API contract)
    if (extras != null) {
      if ((extras == ExtraType.bye || extras == ExtraType.legBye) && runs < 1) {
        throw StateError('Byes/leg-byes must have at least 1 run');
      }
      // No-ball/wide CAN be 0 (penalty runs only) or positive
    } else {
      // Legal ball must be 0-6 runs
      if (runs > 6) throw StateError('Legal ball cannot exceed 6 runs');
    }

    // Wicket validation
    if (wicketType != null) {
      if (outPlayerId == null || outPlayerId! <= 0) {
        throw StateError('Wicket requires valid outPlayerId');
      }
      if (outPlayerName == null || outPlayerName!.trim().isEmpty) {
        throw StateError('Wicket requires outPlayerName');
      }
    } else {
      if (outPlayerId != null || outPlayerName != null) {
        throw StateError('Cannot have out player details without wicket type');
      }
    }
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is Ball && id == other.id && sequenceNumber == other.sequenceNumber;

  @override
  int get hashCode => Object.hash(id, sequenceNumber);

  @override
  String toString() {
    final sb = StringBuffer('Ball(seq:$sequenceNumber $overNumber.$ballNumber: $runs');
    if (extras != null) sb.write(' $extras');
    if (wicketType != null) sb.write(' $wicketType');
    sb.write(')');
    return sb.toString();
  }
}