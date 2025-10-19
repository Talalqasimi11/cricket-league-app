// lib/features/tournaments/screens/tournament_details_viewer_screen.dart
import 'package:flutter/material.dart';
import '../models/tournament_model.dart';
import '../../matches/screens/live_match_view_screen.dart';
import '../../matches/screens/scorecard_screen.dart';

class TournamentDetailsViewerScreen extends StatelessWidget {
  final TournamentModel tournament;

  const TournamentDetailsViewerScreen({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tournament.name),
        centerTitle: true,
        backgroundColor: Colors.green.shade600,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (tournament.matches == null || tournament.matches!.isEmpty)
            const Center(child: Text("No matches scheduled yet")),
          if (tournament.matches != null && tournament.matches!.isNotEmpty)
            ..._buildStages(tournament.matches!),
        ],
      ),
    );
  }

  List<Widget> _buildStages(List<MatchModel> matches) {
    final List<Widget> stages = [];

    stages.add(
      _buildStage(
        "All Matches",
        matches.map((m) {
          final matchNo =
              int.tryParse(m.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final result = m.status == "completed"
              ? "Winner: ${m.winner ?? 'TBD'}"
              : null;
          final scheduled = m.scheduledAt?.toLocal().toString().substring(
            0,
            16,
          );

          return MatchCardViewer(
            matchNo: matchNo,
            teamA: m.teamA,
            teamB: m.teamB,
            result: result,
            scheduled: scheduled,
            match: m,
          );
        }).toList(),
      ),
    );

    return stages;
  }

  Widget _buildStage(String stage, List<Widget> matches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stage,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...matches,
      ],
    );
  }
}

class MatchCardViewer extends StatelessWidget {
  final int matchNo;
  final String teamA;
  final String teamB;
  final String? result;
  final String? scheduled;
  final MatchModel match;

  const MatchCardViewer({
    super.key,
    required this.matchNo,
    required this.teamA,
    required this.teamB,
    this.result,
    this.scheduled,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Match $matchNo",
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "$teamA vs $teamB",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            if (result != null)
              Text(
                result!,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            if (scheduled != null)
              Text(
                "Scheduled: $scheduled",
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  _navigateToMatchDetails(context, match);
                },
                child: const Text("View Match Details"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToMatchDetails(BuildContext context, MatchModel match) {
    if (match.status == "live") {
      // Navigate to live match view for ongoing matches
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveMatchViewScreen(matchId: match.id),
        ),
      );
    } else if (match.status == "completed" || match.status == "finished") {
      // Navigate to scorecard for completed matches
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ScorecardScreen(matchId: match.id)),
      );
    } else {
      // For planned/upcoming matches, show a dialog with match info
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Match ${match.id}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${match.teamA} vs ${match.teamB}"),
              const SizedBox(height: 8),
              Text("Status: ${match.status}"),
              if (match.scheduledAt != null)
                Text(
                  "Scheduled: ${match.scheduledAt!.toLocal().toString().substring(0, 16)}",
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        ),
      );
    }
  }
}
