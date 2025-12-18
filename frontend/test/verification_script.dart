import 'package:test/test.dart';
import 'package:frontend/features/matches/services/ball_sequence_service.dart';
import 'package:frontend/features/matches/models/ball_model.dart';

void main() {
  group('BallSequenceService Logic Verification', () {
    late BallSequenceService service;

    setUp(() {
      service = BallSequenceService();
    });

    test('verifies over calculation with mixed legal and illegal balls', () {
      // 1. Add 6 balls: [1, W, 4, Wide, 2, 0]
      // Legal balls: 1, W, 4, 2, 0 (Total 5)
      // Illegal balls: Wide (Total 1)

      final ballsToAdd = [
        _createBall(1, runs: 1), // Legal
        _createBall(2, wicketType: WicketType.bowled), // Legal (Wicket)
        _createBall(3, runs: 4), // Legal
        _createBall(4, extras: ExtraType.wide, runs: 1), // Illegal (Wide)
        _createBall(5, runs: 2), // Legal
        _createBall(6, runs: 0), // Legal
      ];

      for (var ball in ballsToAdd) {
        service.addBall(ball);
      }

      // 2. Assert legalBalls == 5
      expect(
        service.legalBallsInCurrentOver,
        equals(5),
        reason: 'Should have 5 legal balls',
      );
      expect(
        service.isOverComplete(),
        isFalse,
        reason: 'Over should NOT be complete yet',
      );

      // 3. Add 1 more legal ball
      service.addBall(_createBall(7, runs: 1));

      // 4. Assert isOverComplete == true
      expect(
        service.legalBallsInCurrentOver,
        equals(6),
        reason: 'Should have 6 legal balls',
      );
      expect(
        service.isOverComplete(),
        isTrue,
        reason: 'Over SHOULD be complete now',
      );
    });
  });
}

Ball _createBall(
  int seq, {
  int runs = 0,
  ExtraType? extras,
  WicketType? wicketType,
}) {
  return Ball(
    id: 'ball_$seq',
    matchId: 'match_1',
    inningId: 'inning_1',
    sequenceNumber: seq,
    overNumber: 0, // Service calculates this, but model requires it.
    ballNumber: seq,
    batsmanId: 1,
    bowlerId: 2,
    runs: runs,
    extras: extras,
    wicketType: wicketType,
    outPlayerId: wicketType != null ? 1 : null,
    outPlayerName: wicketType != null ? 'Player 1' : null,
  );
}
