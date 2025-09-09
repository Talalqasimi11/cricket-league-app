import 'package:flutter/material.dart';

class TournamentDetailsViewerScreen extends StatelessWidget {
  final String tournamentName;

  const TournamentDetailsViewerScreen({super.key, required this.tournamentName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tournamentName),
        centerTitle: true,
        backgroundColor: Colors.green.shade600,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quarter Finals
          _buildStage("Quarter-Finals", [
            MatchCardViewer(
              matchNo: 1,
              teamA: "Team A",
              teamB: "Team B",
              result: "Team A won by 5 wickets",
            ),
            MatchCardViewer(
              matchNo: 2,
              teamA: "Team C",
              teamB: "Team D",
              result: "Team C won by 3 wickets",
            ),
            MatchCardViewer(
              matchNo: 3,
              teamA: "Team E",
              teamB: "Team F",
              result: "Team E won by 7 wickets",
            ),
            MatchCardViewer(
              matchNo: 4,
              teamA: "Team G",
              teamB: "Team H",
              result: "Team G won by 2 wickets",
            ),
          ]),

          const SizedBox(height: 24),

          // Semi Finals
          _buildStage("Semi-Finals", [
            MatchCardViewer(
              matchNo: 5,
              teamA: "Team A",
              teamB: "Team C",
              scheduled: "2024-07-20 14:00",
            ),
            MatchCardViewer(
              matchNo: 6,
              teamA: "Team E",
              teamB: "Team G",
              scheduled: "2024-07-20 18:00",
            ),
          ]),

          const SizedBox(height: 24),

          // Final
          _buildStage("Final", [
            MatchCardViewer(matchNo: 7, teamA: "TBD", teamB: "TBD", scheduled: "2024-07-22 16:00"),
          ]),
        ],
      ),
    );
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
            // Match No
            Text(
              "Match $matchNo",
              style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 6),

            // Teams
            Text(
              "$teamA vs $teamB",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            // Result OR Scheduled Date
            if (result != null)
              Text(result!, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            if (scheduled != null)
              Text(scheduled!, style: const TextStyle(color: Colors.grey, fontSize: 14)),

            const SizedBox(height: 8),

            // View Match Details Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Navigate to Match Details
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
