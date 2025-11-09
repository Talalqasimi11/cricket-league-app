/// Ball Model - Represents a single ball delivery in cricket
///
/// Scoring Data Model (Single 'runs' field = TOTAL runs):
/// The API uses a single 'runs' field to represent TOTAL runs for the delivery:
///
/// Legal balls (extras=null):
///   - runs: 0-6 (runs off bat)
///   - Example: batsman hits 4 runs = {extras: null, runs: 4}
///
/// Wides/No-balls (extras='wide' or 'no-ball'):
///   - runs: 0+ (penalty/extra runs)
///   - Example: wide ball, batsman runs 1 = {extras: 'wide', runs: 1}
///   - Example: no-ball, 1 run penalty = {extras: 'no-ball', runs: 1}
///
/// Byes/Leg-byes (extras='bye' or 'leg-bye'):
///   - runs: 1+ (unearned runs, must have at least 1)
///   - Example: bye, 2 runs = {extras: 'bye', runs: 2}
///   - Example: leg-bye = {extras: 'leg-bye', runs: 1}
///
/// Over/Ball Numbering:
/// - over_number: 0-based (0 = first over, 1 = second over, etc.)
/// - ball_number: 1-based (1-6, where ball 6 = last ball of over)
/// - First ball in innings: over=0, ball=1
/// - Ball sequences must be contiguous (0.1, 0.2, ..., 0.6, 1.1, ...)
///
/// Validation Rules:
/// - Legal balls: runs must be 0-6
/// - Wides/No-balls: runs must be 0+ (typically 1+ for penalty runs)
/// - Byes/Leg-byes: runs must be 1+ (cannot be 0)
///
/// Usage in Frontend:
/// When submitting a ball, create a Ball instance and call toJson():
/// ```dart
/// final ball = Ball(
///   id: 0, matchId: 1, inningId: 5,
///   overNumber: 0, ballNumber: 1,  // 0-based over, 1-based ball
///   batsmanId: 5, bowlerId: 8,
///   runs: 4,  // Total runs for this delivery
///   extras: null,  // null for legal, 'wide'/'no-ball'/'bye'/'leg-bye' otherwise
///   wicketType: null,
///   outPlayerId: null,
/// );
/// final json = ball.toJson();  // Validated and ready to send to backend
/// ```
/// The backend validates the contract and persists the data.

class Ball {
  final int id;
  final int matchId;
  final int inningId;
  final int overNumber; // 0-based
  final int ballNumber; // 1-based (1-6)
  final int batsmanId;
  final String? batsmanName;
  final int bowlerId;
  final String? bowlerName;
  final int runs; // Total runs for this delivery (including all extra types)
  final String?
  extras; // 'wide', 'no-ball', 'bye', 'leg-bye', or null for legal
  final String?
  wicketType; // 'bowled', 'caught', 'lbw', 'run-out', 'stumped', 'hit-wicket', or null
  final int? outPlayerId;
  final String? outPlayerName;

  Ball({
    required this.id,
    required this.matchId,
    required this.inningId,
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
  });

  /// Get display string for over notation (e.g., "2.3" = 2 overs, 3 balls)
  String get overNotation => '$overNumber.$ballNumber';

  /// Check if this is a legal ball (no wides/no-balls)
  bool get isLegalBall =>
      extras == null || (extras != 'wide' && extras != 'no-ball');

  /// Check if this ball resulted in a wicket
  bool get isWicket => wicketType != null;

  /// Check if this is an extra delivery
  bool get isExtra => extras != null;

  /// Get total runs for this delivery (this IS the total, already includes extras)
  int get totalRuns => runs;

  /// Convert from JSON response
  factory Ball.fromJson(Map<String, dynamic> json) {
    return Ball(
      id: json['id'] ?? 0,
      matchId: json['match_id'] ?? 0,
      inningId: json['inning_id'] ?? 0,
      overNumber: json['over_number'] ?? 0,
      ballNumber: json['ball_number'] ?? 1,
      batsmanId: json['batsman_id'] ?? 0,
      batsmanName: json['batsman_name'],
      bowlerId: json['bowler_id'] ?? 0,
      bowlerName: json['bowler_name'],
      runs: json['runs'] ?? 0,
      extras: json['extras'],
      wicketType: json['wicket_type'],
      outPlayerId: json['out_player_id'],
      outPlayerName: json['out_player_name'],
    );
  }

  /// Convert to JSON for API requests
  /// Enforces API contract:
  ///   - over_number must be 0-based (0 for first over)
  ///   - ball_number must be 1-based (1-6)
  ///   - runs must be non-negative (validated by backend per extras type)
  Map<String, dynamic> toJson() {
    assert(overNumber >= 0, 'over_number must be 0-based (0 for first over)');
    assert(ballNumber >= 1 && ballNumber <= 6, 'ball_number must be 1-6');
    assert(runs >= 0, 'runs must be non-negative');

    return {
      'match_id': matchId,
      'inning_id': inningId,
      'over_number': overNumber,
      'ball_number': ballNumber,
      'batsman_id': batsmanId,
      'bowler_id': bowlerId,
      'runs': runs,
      'extras': extras,
      'wicket_type': wicketType,
      'out_player_id': outPlayerId,
    };
  }
}
