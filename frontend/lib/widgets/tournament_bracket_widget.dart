import 'package:flutter/material.dart';
// Assuming MatchModel and MatchStatus are defined here:
import '../features/matches/models/match_model.dart';

// --- CONSTANTS FOR BRACKET LAYOUT ---
const double _connectorWidth = 100.0;
const double _cardWidth = 200.0;
const double _cardHeight = 70.0; // Fixed height for consistent spacing
const double _verticalSpacing = 24.0; // Space between match cards
const double _titleHeight = 55.0; // Increased to account for Text + Spacing

class TournamentBracketWidget extends StatelessWidget {
  final List<MatchModel> matches;
  final void Function(MatchModel)? onMatchTap;

  const TournamentBracketWidget({
    super.key,
    required this.matches,
    this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const Center(child: Text('No matches to display'));
    }

    final rounds = _groupMatchesByRound(matches);
    final roundKeys = rounds.keys.toList();

    return Container(
      color: const Color(0xFF064D2B), // Cricket green
      width: double.infinity,
      height: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(28),
          child: Builder(
            builder: (context) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(roundKeys.length, (index) {
                  final roundName = roundKeys[index];
                  final list = rounds[roundName]!;
                  final isLast = index == roundKeys.length - 1;

                  // Calculate the max height needed for the current round to center it
                  final maxMatchesInRound = _calculateMaxMatches(rounds);
                  final roundMaxHeight = _calculateRoundHeight(
                    maxMatchesInRound,
                  );

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _RoundColumn(
                        title: _getRoundDisplayName(roundName),
                        matches: list,
                        onTap: onMatchTap,
                        roundMaxHeight: roundMaxHeight, // Pass max height
                      ),
                      if (!isLast)
                        _BetweenRoundsConnector(
                          leftCount: list.length,
                          roundMaxHeight: roundMaxHeight, // Pass max height
                        ),
                    ],
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }

  // Helper to calculate the height of a round column based on max matches
  double _calculateRoundHeight(int matchCount) {
    if (matchCount == 0) return _titleHeight;
    // Total height = Title height + (Match Card Height + Spacing) * Match Count
    return _titleHeight + (matchCount * (_cardHeight + _verticalSpacing));
  }

  // Helper to find the max number of matches in any round
  int _calculateMaxMatches(Map<String, List<MatchModel>> rounds) {
    if (rounds.isEmpty) return 0;
    return rounds.values
        .map((list) => list.length)
        .reduce((a, b) => a > b ? a : b);
  }

  // --- Utility methods for grouping and sorting matches (unchanged logic) ---
  Map<String, List<MatchModel>> _groupMatchesByRound(List<MatchModel> matches) {
    final map = <String, List<MatchModel>>{};

    for (var m in matches) {
      final r = _normalizeRound(m.round);
      map.putIfAbsent(r, () => []).add(m);
    }

    map.forEach((k, v) {
      v.sort((a, b) => a.id.compareTo(b.id));
    });

    final sortedKeys = map.keys.toList()
      ..sort((a, b) => _getRoundWeight(a).compareTo(_getRoundWeight(b)));

    return {for (var k in sortedKeys) k: map[k]!};
  }

  int _getRoundWeight(String r) {
    if (r.startsWith('round_')) return int.tryParse(r.split('_')[1]) ?? 0;

    switch (r) {
      case 'quarter_final':
        return 90;
      case 'semi_final':
        return 95;
      case 'final':
        return 100;
      default:
        return 999;
    }
  }

  String _normalizeRound(String s) {
    s = s.toLowerCase().replaceAll('-', '_');

    if (s.contains('semi')) return 'semi_final';
    if (s.contains('quarter')) return 'quarter_final';
    if (s.contains('final') && !s.contains('semi')) return 'final';

    return s;
  }

  String _getRoundDisplayName(String n) {
    switch (n) {
      case 'semi_final':
        return 'Semi Finals';
      case 'quarter_final':
        return 'Quarter Finals';
      case 'final':
        return 'Final';
      default:
        return n.replaceAll('_', ' ').toUpperCase();
    }
  }
}

//
// ROUND COLUMN
//
class _RoundColumn extends StatelessWidget {
  final String title;
  final List<MatchModel> matches;
  final void Function(MatchModel)? onTap;
  final double roundMaxHeight;

  const _RoundColumn({
    required this.title,
    required this.matches,
    this.onTap,
    required this.roundMaxHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap in SizedBox to give the Column a constrained height, preventing overflow
    // and allowing matches to be vertically centered within the roundMaxHeight.
    return SizedBox(
      height: roundMaxHeight,
      width: _cardWidth + 28, // Add some horizontal padding space
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center, // Center the matches vertically
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: _verticalSpacing),

          // Use ListView.builder to handle many matches if necessary,
          // but the current structure makes more sense with direct children.
          // Using a Column here is fine, but we need to control the spacing.
          Column(
            children: matches.map((m) {
              return Padding(
                // Use consistent vertical spacing
                padding: const EdgeInsets.only(bottom: _verticalSpacing),
                child: _MatchCard(match: m, onTap: onTap),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

//
// MATCH CARD
//
class _MatchCard extends StatelessWidget {
  final MatchModel match;
  final void Function(MatchModel)? onTap;

  const _MatchCard({required this.match, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLive = match.status == MatchStatus.live;

    return GestureDetector(
      onTap: onTap != null ? () => onTap!(match) : null,
      child: Container(
        width: _cardWidth,
        height: _cardHeight, // Fixed height
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white, width: 1.4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (isLive)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Team A
            Text(
              match.teamA,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),

            const Divider(height: 1, color: Colors.black12),

            // Team B
            Text(
              match.teamB,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

//
// CONNECTOR BETWEEN ROUNDS (white lines)
//
class _BetweenRoundsConnector extends StatelessWidget {
  final int leftCount;
  final double roundMaxHeight;

  const _BetweenRoundsConnector({
    required this.leftCount,
    required this.roundMaxHeight,
  });

  @override
  Widget build(BuildContext context) {
    // The height is the same as the round column it sits next to
    return SizedBox(
      width: _connectorWidth,
      height: roundMaxHeight,
      child: CustomPaint(painter: _ConnectorPainter(matchCount: leftCount)),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final int matchCount;

  _ConnectorPainter({required this.matchCount});

  @override
  void paint(Canvas canvas, Size s) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    // Calculate the total height dedicated to match cards and spacing
    final contentHeight = matchCount * (_cardHeight + _verticalSpacing);
    // Find the starting Y position for the first match's connector line
    final startYOffset =
        (s.height - contentHeight) / 2 + _titleHeight / 2 + _cardHeight / 2;

    // The vertical distance between the center of one match card and the next
    const verticalStep = _cardHeight + _verticalSpacing;

    // 1. Draw the horizontal lines coming from the left match cards
    for (int i = 0; i < matchCount; i++) {
      final y = startYOffset + i * verticalStep;
      // Draw small horizontal line segment coming out of the match card
      canvas.drawLine(Offset(0, y), Offset(s.width / 2 - 10, y), paint);
    }

    // 2. Draw the vertical lines connecting pairs
    for (int i = 0; i < matchCount; i += 2) {
      if (i + 1 < matchCount) {
        final y1 = startYOffset + i * verticalStep;
        final y2 = startYOffset + (i + 1) * verticalStep;
        final midY = (y1 + y2) / 2;
        final midX = s.width / 2;

        // Vertical line connecting two matches
        canvas.drawLine(Offset(midX - 10, y1), Offset(midX - 10, y2), paint);
        // Horizontal line from vertical connector to the right side
        canvas.drawLine(Offset(midX - 10, midY), Offset(s.width, midY), paint);
      } else {
        // This case handles an odd number of matches (e.g., in a 3rd place playoff)
        // It simply extends the line to the right.
        final y = startYOffset + i * verticalStep;
        canvas.drawLine(Offset(s.width / 2 - 10, y), Offset(s.width, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter oldDelegate) =>
      oldDelegate.matchCount != matchCount;
}
