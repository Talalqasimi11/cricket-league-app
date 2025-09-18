// lib/features/tournaments/screens/tournament_details_viewer_screen.dart
import 'package:flutter/material.dart';
import '../models/tournament_model.dart';

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
          final matchNo = int.tryParse(m.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final result = m.status == "completed" ? "Winner: ${m.winner ?? 'TBD'}" : null;
          final scheduled = m.scheduledAt?.toLocal().toString().substring(0, 16);

          return MatchCardViewer(
            matchNo: matchNo,
            teamA: m.teamA,
            teamB: m.teamB,
            result: result,
            scheduled: scheduled,
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
        Text(stage, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  const MatchCardViewer({
    super.key,
    required this.matchNo,
    required this.teamA,
    required this.teamB,
    this.result,
    this.scheduled,
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
              style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              "$teamA vs $teamB",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            if (result != null)
              Text(result!, style: const TextStyle(color: Colors.grey, fontSize: 14)),
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
                  // TODO: Navigate to match details
                },
                child: const Text("View Match Details"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
