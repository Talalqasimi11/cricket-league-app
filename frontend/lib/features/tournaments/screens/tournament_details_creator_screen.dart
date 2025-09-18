// lib/features/tournaments/screens/tournament_details_creator_screen.dart
import 'package:flutter/material.dart';
import '../models/tournament_model.dart';
import '../../matches/screens/create_match_screen.dart'; // ✅ scoring screen (replace with your matches page)

class TournamentDetailsCaptainScreen extends StatefulWidget {
  final TournamentModel tournament;

  const TournamentDetailsCaptainScreen({super.key, required this.tournament});

  @override
  State<TournamentDetailsCaptainScreen> createState() => _TournamentDetailsCaptainScreenState();
}

class _TournamentDetailsCaptainScreenState extends State<TournamentDetailsCaptainScreen> {
  late List<MatchModel> _matches;

  @override
  void initState() {
    super.initState();
    _matches = List.from(widget.tournament.matches ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tournament.name),
        centerTitle: true,
        backgroundColor: Colors.green.shade600,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_matches.isEmpty) const Center(child: Text("No matches scheduled yet")),
          if (_matches.isNotEmpty) ..._buildStages(context, _matches),
        ],
      ),
    );
  }

  List<Widget> _buildStages(BuildContext context, List<MatchModel> matches) {
    final List<Widget> stages = [];

    stages.add(
      _buildStage(
        "All Matches",
        matches.asMap().entries.map((entry) {
          final idx = entry.key;
          final m = entry.value;

          final matchNo = int.tryParse(m.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? idx + 1;
          final scheduled = m.scheduledAt?.toLocal().toString().substring(0, 16);

          return MatchCard(
            matchNo: matchNo,
            teamA: m.teamA,
            teamB: m.teamB,
            result: m.status == "completed" ? "Winner: ${m.winner ?? 'TBD'}" : null,
            scheduled: scheduled,
            editable: m.status == "planned",
            onEdit: () async {
              final newDate = await _pickDate(context, m.scheduledAt);
              if (newDate != null) {
                setState(() {
                  _matches[idx] = m.copyWith(scheduledAt: newDate);
                });

                // ✅ TODO: Save updated match date to backend
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Match ${m.id} rescheduled to $newDate")));
              }
            },
            onStart: () {
              // ✅ Update status to "live"
              setState(() {
                _matches[idx] = m.copyWith(status: "live");
              });

              // ✅ Navigate to scoring page (replace with MatchesScreen if you like)
              Navigator.push(context, MaterialPageRoute(builder: (_) => CreateMatchScreen()));
            },
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
        const SizedBox(height: 20),
      ],
    );
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime? initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}

class MatchCard extends StatelessWidget {
  final int matchNo;
  final String teamA;
  final String teamB;
  final String? result;
  final String? scheduled;
  final bool editable;
  final VoidCallback? onEdit;
  final VoidCallback? onStart;

  const MatchCard({
    super.key,
    required this.matchNo,
    required this.teamA,
    required this.teamB,
    this.result,
    this.scheduled,
    this.editable = false,
    this.onEdit,
    this.onStart,
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

            if (result != null) Text(result!, style: const TextStyle(color: Colors.grey)),
            if (scheduled != null)
              Row(
                children: [
                  Text(
                    "Scheduled: $scheduled",
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  if (editable)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.green),
                      onPressed: onEdit,
                    ),
                ],
              )
            else if (editable)
              TextButton.icon(
                icon: const Icon(Icons.add, color: Colors.green),
                label: const Text("Set Date"),
                onPressed: onEdit,
              ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Navigate to Match Details screen
                    },
                    child: const Text("View Details"),
                  ),
                ),
                if (editable) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Start Match"),
                      onPressed: onStart,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
