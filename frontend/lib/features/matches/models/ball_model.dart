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
    switch (value.toLowerCase().trim()) {
      case 'wide':
        return ExtraType.wide;
      case 'no-ball':
        return ExtraType.noBall;
      case 'bye':
        return ExtraType.bye;
      case 'leg-bye':
        return ExtraType.legBye;
      default:
        return null; // Return null gracefully for unknown types
    }
  }

  /// Converts to API-compatible string format.
  String get apiValue => switch (this) {
    ExtraType.wide => 'wide',
    ExtraType.noBall => 'no-ball',
    ExtraType.bye => 'bye',
    ExtraType.legBye => 'leg-bye',
  };
}

/// The method by which a batter is dismissed.
enum WicketType {
  bowled,
  caught,
  lbw,
  runOut,
  stumped,
  hitWicket,
  retiredHurt;

  /// Parses API string value to [WicketType].
  static WicketType? fromApiString(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    switch (value.toLowerCase().trim()) {
      case 'bowled':
        return WicketType.bowled;
      case 'caught':
        return WicketType.caught;
      case 'lbw':
        return WicketType.lbw;
      case 'run-out':
      case 'run out': // Handle potential space variation
        return WicketType.runOut;
      case 'stumped':
        return WicketType.stumped;
      case 'hit-wicket':
      case 'hit wicket': // Handle potential space variation
        return WicketType.hitWicket;
      case 'retired-hurt':
        return WicketType.retiredHurt;
      default:
        return null;
    }
  }

  /// Converts to API-compatible string format.
  String get apiValue => switch (this) {
    WicketType.bowled => 'bowled',
    WicketType.caught => 'caught',
    WicketType.lbw => 'lbw',
    WicketType.runOut => 'run-out',
    WicketType.stumped => 'stumped',
    WicketType.hitWicket => 'hit-wicket',
    WicketType.retiredHurt => 'retired-hurt',
  };
}

/// Represents a single ball delivery in cricket.
///
/// IMPORTANT
/// - ballNumber is NOT constrained to 1–6. After wides/no-balls, ballNumber may
///   exceed 6 (e.g., 6, 7, 8...). Use [BallSequenceService] to compute display
///   over notation based on legal deliveries.
/// - sequenceNumber is the absolute event order within the innings (0-based).
@immutable
class Ball {
  final String id; // UUID for idempotency
  final String matchId;
  final String inningId;

  /// Absolute sequence number (0 = first ball of innings).
  final int sequenceNumber;

  /// Over number (0-based).
  final int overNumber;

  /// Display ball number (1,2,3... may exceed 6 for extra deliveries).
  final int ballNumber;

  final int batsmanId;
  final String? batsmanName;
  final int bowlerId;
  final String? bowlerName;

  /// Runs recorded on this event (batter runs or extra runs depending on [extras]).
  final int runs;

  /// Extra type, if any.
  final ExtraType? extras;

  /// Wicket type, if any.
  final WicketType? wicketType;

  /// Dismissed player's ID and name (required when [wicketType] is non-null).
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
  }) : isLegalBall =
           extras == null ||
           (extras != ExtraType.wide && extras != ExtraType.noBall),
       assert(sequenceNumber >= 0, 'sequenceNumber must be >= 0'),
       assert(overNumber >= 0, 'overNumber must be >= 0'),
       assert(ballNumber >= 1, 'ballNumber must be >= 1'),
       assert(runs >= 0, 'runs cannot be negative');

  /// Approximate display notation "$overNumber.$ballNumber".
  ///
  /// WARNING: This does not account for legal-ball counting. Use
  /// [BallSequenceService] for exact display that handles wides/no-balls correctly.
  String get displayOverNotation => '$overNumber.$ballNumber';

  static const _sentinel = Object();

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
    Object? extras = _sentinel, // ExtraType? or null
    Object? wicketType = _sentinel, // WicketType? or null
    Object? outPlayerId = _sentinel, // int? or null
    Object? outPlayerName = _sentinel, // String? or null
  }) {
    final newExtras = extras == _sentinel ? this.extras : extras as ExtraType?;
    final newWicket = wicketType == _sentinel
        ? this.wicketType
        : wicketType as WicketType?;
    final newOutPlayerId = outPlayerId == _sentinel
        ? this.outPlayerId
        : outPlayerId as int?;
    final newOutPlayerName = outPlayerName == _sentinel
        ? this.outPlayerName
        : outPlayerName as String?;

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
      extras: newExtras,
      wicketType: newWicket,
      outPlayerId: newOutPlayerId,
      outPlayerName: newOutPlayerName,
    );
  }

  /// Deserializes from JSON/Map with strict validation.
  factory Ball.fromJson(Map<String, dynamic> json) {
    int _i(dynamic v, [int def = 0]) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? def;
      return def;
    }

    String? _s(dynamic v) => v?.toString();

    try {
      final extrasValue = ExtraType.fromApiString(_s(json['extras']));
      final wicketValue = WicketType.fromApiString(_s(json['wicket_type']));

      return Ball(
        id: _s(json['id']) ?? '',
        matchId: _s(json['match_id']) ?? '',
        inningId: _s(json['inning_id']) ?? '',
        sequenceNumber: _i(json['sequence_number'] ?? json['sequence']),
        overNumber: _i(json['over_number']),
        ballNumber: _i(json['ball_number'], 1),
        batsmanId: _i(json['batsman_id']),
        batsmanName: _s(json['batsman_name']),
        bowlerId: _i(json['bowler_id']),
        bowlerName: _s(json['bowler_name']),
        runs: _i(json['runs']),
        extras: extrasValue,
        wicketType: wicketValue,
        outPlayerId: json['out_player_id'] == null
            ? null
            : _i(json['out_player_id']),
        outPlayerName: _s(json['out_player_name']),
      );
    } catch (e, stackTrace) {
      final raw = json.toString();
      final safe = raw.length <= 200 ? raw : raw.substring(0, 200);
      throw FormatException(
        'Ball.fromJson failed: $e\nJSON: $safe',
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
    if (sequenceNumber < 0) {
      throw StateError('sequenceNumber must be >= 0');
    }
    if (overNumber < 0) {
      throw StateError('Over number cannot be negative');
    }
    if (ballNumber < 1) {
      throw StateError('Ball number must be >= 1');
    }
    if (batsmanId <= 0) {
      throw StateError('Batsman ID must be positive');
    }
    if (bowlerId <= 0) {
      throw StateError('Bowler ID must be positive');
    }
    if (runs < 0) {
      throw StateError('Runs cannot be negative');
    }

    // Extras validation
    if (extras != null) {
      if ((extras == ExtraType.bye || extras == ExtraType.legBye) && runs < 1) {
        throw StateError('Byes/leg-byes must have at least 1 run');
      }
    } else {
      if (runs > 6) {
        throw StateError('Legal ball cannot exceed 6 runs');
      }
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ball &&
          id == other.id &&
          sequenceNumber == other.sequenceNumber);

  @override
  int get hashCode => Object.hash(id, sequenceNumber);

  @override
  String toString() {
    final sb = StringBuffer(
      'Ball(seq:$sequenceNumber $overNumber.$ballNumber: $runs',
    );
    if (extras != null) sb.write(' ${extras!.apiValue}');
    if (wicketType != null) sb.write(' ${wicketType!.apiValue}');
    sb.write(')');
    return sb.toString();
  }
}
