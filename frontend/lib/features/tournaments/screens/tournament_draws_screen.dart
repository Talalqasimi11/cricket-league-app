// lib/features/tournaments/screens/tournament_draws_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';

// ✅ Models import
import '../models/tournament_model.dart';

// ✅ Correct detail screens
import 'tournament_details_creator_screen.dart';
import 'tournament_details_viewer_screen.dart';

class TournamentDrawsScreen extends StatefulWidget {
  final String tournamentName;
  final List<String> teams;
  final bool isCreator;

  const TournamentDrawsScreen({
    super.key,
    required this.tournamentName,
    required this.teams,
    this.isCreator = false,
  });

  @override
  State<TournamentDrawsScreen> createState() => _TournamentDrawsScreenState();
}

class _TournamentDrawsScreenState extends State<TournamentDrawsScreen> {
  bool _autoDraw = true;
  List<MatchModel> _matches = [];

  void _generateAutoDraws() {
    final teams = List<String>.from(widget.teams);
    teams.shuffle(Random());
    final List<MatchModel> pairs = [];

    for (int i = 0; i + 1 < teams.length; i += 2) {
      pairs.add(MatchModel(id: 'm${i ~/ 2 + 1}', teamA: teams[i], teamB: teams[i + 1]));
    }

    if (teams.length.isOdd) {
      pairs.add(
        MatchModel(id: 'm${pairs.length + 1}', teamA: teams.last, teamB: 'BYE', status: 'planned'),
      );
    }

    setState(() => _matches = pairs);
  }

  void _addManualMatch() async {
    String? selectedA;
    String? selectedB;

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Create Match"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                hint: const Text("Select Team A"),
                items: widget.teams.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => selectedA = val,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                hint: const Text("Select Team B"),
                items: widget.teams.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => selectedB = val,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (selectedA != null && selectedB != null && selectedA != selectedB) {
                  setState(() {
                    _matches.add(
                      MatchModel(
                        id: 'm${_matches.length + 1}',
                        teamA: selectedA!,
                        teamB: selectedB!,
                        status: 'planned',
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDateForMatch(int idx) async {
    final initial = _matches[idx].scheduledAt ?? DateTime.now().add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null) return;

    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      _matches[idx].scheduledAt = picked;
    });
  }

  Widget _matchTile(MatchModel match, int idx) {
    final scheduledStr = match.scheduledAt == null
        ? 'Not scheduled'
        : match.scheduledAt!.toLocal().toString().substring(0, 16);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(child: Text('${idx + 1}')),
        title: Text('${match.teamA}  vs  ${match.teamB}'),
        subtitle: Text(scheduledStr),
        trailing: widget.isCreator
            ? IconButton(
                tooltip: 'Set date',
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _pickDateForMatch(idx),
              )
            : null,
      ),
    );
  }

  Widget _bottomAction() {
    if (!widget.isCreator) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
          onPressed: _matches.isEmpty
              ? null
              : () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Bracket view coming soon...')));
                },
          child: const Text('View Bracket'),
        ),
      );
    }

    // Creator actions
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _autoDraw ? _generateAutoDraws : _addManualMatch,
              child: Text(
                _autoDraw
                    ? (_matches.isEmpty ? 'Generate Draws' : 'Regenerate Draws')
                    : 'Add Manual Match',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
              onPressed: _matches.isEmpty
                  ? null
                  : () {
                      final updatedTournament = TournamentModel(
                        id: UniqueKey().toString(),
                        name: widget.tournamentName,
                        status: "upcoming",
                        type: "Knockout",
                        dateRange: "TBD",
                        location: "Unknown",
                        overs: 20,
                        teams: widget.teams,
                        matches: _matches,
                      );

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => widget.isCreator
                              ? TournamentDetailsCaptainScreen(tournament: updatedTournament)
                              : TournamentDetailsViewerScreen(tournament: updatedTournament),
                        ),
                      );
                    },
              child: const Text('Save & Publish'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tournamentName} — Draws'),
        backgroundColor: Colors.green[800],
      ),
      body: Column(
        children: [
          if (widget.isCreator)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Auto Draws'),
                      selected: _autoDraw,
                      onSelected: (v) => setState(() => _autoDraw = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Manual Draws'),
                      selected: !_autoDraw,
                      onSelected: (v) => setState(() => _autoDraw = false),
                    ),
                  ),
                ],
              ),
            ),

          // Team list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Text(
                  '${widget.teams.length} teams',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: widget.teams
                          .map(
                            (t) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(t),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Matches list
          Expanded(
            child: _matches.isEmpty
                ? Center(
                    child: Text(
                      widget.isCreator
                          ? (_autoDraw
                                ? 'No draws yet. Tap Generate Draws.'
                                : 'No matches yet. Tap Add Manual Match.')
                          : 'Draws not published yet.',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _matches.length,
                    itemBuilder: (context, i) => _matchTile(_matches[i], i),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomAction(),
    );
  }
}
