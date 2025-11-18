import 'package:flutter/material.dart';
import '../features/tournaments/models/tournament_model.dart';

class TournamentBracketWidget extends StatelessWidget {
  final List<MatchModel> matches;
  final Function(MatchModel)? onMatchTap;

  const TournamentBracketWidget({
    super.key,
    required this.matches,
    this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const Center(
        child: Text('No matches to display'),
      );
    }

    final rounds = _groupMatchesByRound(matches);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: rounds.entries.map((entry) {
              return _buildRoundColumn(entry.key, entry.value);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Map<String, List<MatchModel>> _groupMatchesByRound(List<MatchModel> matches) {
    final rounds = <String, List<MatchModel>>{};

    for (final match in matches) {
      final round = _getRoundFromMatch(match);
      rounds.putIfAbsent(round, () => []).add(match);
    }

    final sortedRounds = <String, List<MatchModel>>{};
    final roundOrder = ['round_1', 'quarter_final', 'semi_final', 'final'];

    for (final roundName in roundOrder) {
      if (rounds.containsKey(roundName)) {
        sortedRounds[roundName] = rounds[roundName]!;
      }
    }

    rounds.forEach((key, value) {
      if (!sortedRounds.containsKey(key)) {
        sortedRounds[key] = value;
      }
    });

    return sortedRounds;
  }

  String _getRoundFromMatch(MatchModel match) {
    if (match.id.contains('final')) return 'final';
    if (match.id.contains('semi')) return 'semi_final';
    if (match.id.contains('quarter')) return 'quarter_final';
    return 'round_1';
  }

  Widget _buildRoundColumn(String roundName, List<MatchModel> roundMatches) {
    final roundDisplayName = _getRoundDisplayName(roundName);

    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Text(
              roundDisplayName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          ...roundMatches.map((match) => _buildMatchCard(match)),
        ],
      ),
    );
  }

  String _getRoundDisplayName(String roundName) {
    switch (roundName) {
      case 'round_1':
        return 'Round 1';
      case 'quarter_final':
        return 'Quarter Finals';
      case 'semi_final':
        return 'Semi Finals';
      case 'final':
        return 'Final';
      default:
        return roundName.replaceAll('_', ' ').toUpperCase();
    }
  }

  Widget _buildMatchCard(MatchModel match) {
    final status = MatchStatus.fromString(match.status);
    final isCompleted = status == MatchStatus.completed;
    final isLive = status == MatchStatus.live;

    Color cardColor;
    if (isLive) {
      cardColor = Colors.red.shade50;
    } else if (isCompleted) {
      cardColor = Colors.green.shade50;
    } else {
      cardColor = Colors.grey.shade50;
    }

    return GestureDetector(
      onTap: onMatchTap != null ? () => onMatchTap!(match) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isLive
                ? Colors.red.shade300
                : isCompleted
                ? Colors.green.shade300
                : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Match ${match.id}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    match.teamA,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLive
                        ? Colors.red
                        : isCompleted
                        ? Colors.green
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isLive
                        ? 'LIVE'
                        : isCompleted
                        ? 'DONE'
                        : 'UPCOMING',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    match.teamB,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (isCompleted && match.winner != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Winner: ${match.winner}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (match.scheduledAt != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatDateTime(match.scheduledAt!),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month $hour:$minute';
  }
}
