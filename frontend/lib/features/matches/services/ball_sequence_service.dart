// lib/features/matches/services/ball_sequence_service.dart

// FIX: Hide the legacy BallSequenceService from the model file to avoid collision
import '../models/ball_model.dart';
import 'package:flutter/foundation.dart';

/// {@template ball_sequence_service}
/// Manages ball sequencing and over notation calculation for cricket scoring.
///
/// **CRITICAL**: This service solves the fundamental problem where wides/no-balls
/// cause ball numbers to exceed 6. It maintains a running sequence of balls
/// and calculates true over notation based on **legal deliveries only**.
/// {@endtemplate}
class BallSequenceService {
  final List<Ball> _balls = [];

  /// All balls in chronological order.
  List<Ball> get balls => List.unmodifiable(_balls);

  /// Total number of balls (including wides/no-balls).
  int get totalBallsDelivered => _balls.length;

  /// Number of legal balls in the current over.
  int get legalBallsInCurrentOver {
    final currentOver = getCurrentOverNumber();
    final ballsInOver = _balls.where((ball) => ball.overNumber == currentOver);
    return ballsInOver.where((ball) => ball.isLegalBall).length;
  }

  /// Gets the current over number (0-based).
  int getCurrentOverNumber() {
    if (_balls.isEmpty) return 0;
    return _balls.last.overNumber;
  }

  /// Gets display notation for current ball (e.g., "12.4").
  String getCurrentOverNotation() {
    final legalBalls = _balls.where((ball) => ball.isLegalBall).length;
    final overs = legalBalls ~/ 6;
    final ballsInCurrentOver = legalBalls % 6;
    return '$overs.$ballsInCurrentOver';
  }

  /// Gets notation for a specific ball in sequence.
  String getNotationForBall(int sequenceIndex) {
    if (sequenceIndex < 0 || sequenceIndex >= _balls.length) {
      throw RangeError('Sequence index out of range');
    }

    final legalBallsToThisPoint = _balls
        .take(sequenceIndex + 1)
        .where((ball) => ball.isLegalBall)
        .length;

    final overs = legalBallsToThisPoint ~/ 6;
    final balls = legalBallsToThisPoint % 6;
    return '$overs.$balls';
  }

  /// Adds a ball to the sequence.
  Ball addBall(Ball ball) {
    final expectedSeq = _balls.length;
    if (ball.sequenceNumber != expectedSeq) {
      debugPrint(
        'Warning: Ball sequence mismatch. Expected: $expectedSeq, Got: ${ball.sequenceNumber}',
      );
    }

    int computedOverNumber = _calculateOverNumberForNextBall();

    final ballToAdd = ball.copyWith(overNumber: computedOverNumber);
    _balls.add(ballToAdd);
    return ballToAdd;
  }

  /// Calculates the over and ball number for the next delivery
  Map<String, int> getNextDeliveryIndices() {
    final overNum = _calculateOverNumberForNextBall();
    final ballsInThisOver = _balls.where((b) => b.overNumber == overNum).length;
    // Simple verification: This is just 1-based index of the ball within the over container
    // The backend might reset this for legal balls, but for specific ball identity,
    // a simple counter is usually sufficient or 1-based index (including extras)
    return {'over_number': overNum, 'ball_number': ballsInThisOver + 1};
  }

  /// Calculates what the over number should be for the next ball.
  int _calculateOverNumberForNextBall() {
    if (_balls.isEmpty) return 0;

    final lastBall = _balls.last;
    final legalBallsInInnings = _balls.where((b) => b.isLegalBall).length;

    if (lastBall.isLegalBall &&
        legalBallsInInnings % 6 == 0 &&
        legalBallsInInnings > 0) {
      return lastBall.overNumber + 1;
    }

    return lastBall.overNumber;
  }

  /// Removes the last ball (for undo functionality).
  Ball? removeLastBall() {
    if (_balls.isEmpty) return null;
    return _balls.removeLast();
  }

  /// Calculates strike rotation for the next ball.
  bool shouldRotateStrike() {
    final legalBallsInInnings = _balls.where((ball) => ball.isLegalBall).length;
    return legalBallsInInnings % 2 == 1;
  }

  /// Checks if over is complete (6 legal balls delivered).
  bool isOverComplete() => legalBallsInCurrentOver >= 6;

  /// Gets summary of current innings state.
  InningsState getState() {
    return InningsState(
      currentOverNotation: getCurrentOverNotation(),
      legalBallsDelivered: _balls.where((ball) => ball.isLegalBall).length,
      totalBallsDelivered: _balls.length,
      isOverComplete: isOverComplete(),
      shouldRotateStrike: shouldRotateStrike(),
    );
  }

  void clear() => _balls.clear();
}

@immutable
class InningsState {
  final String currentOverNotation;
  final int legalBallsDelivered;
  final int totalBallsDelivered;
  final bool isOverComplete;
  final bool shouldRotateStrike;

  const InningsState({
    required this.currentOverNotation,
    required this.legalBallsDelivered,
    required this.totalBallsDelivered,
    required this.isOverComplete,
    required this.shouldRotateStrike,
  });
}
