import 'dart:math';

import 'package:flutter/material.dart';
import '../models/tournament_model.dart';

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

  @override
  void initState() {
    super.initState();
    // if somebody navigated with precomputed matches we would load them.
    // For now we start empty until user generates
  }

  void _generateAutoDraws() {
    final teams = List<String>.from(widget.teams);
    teams.shuffle(Random());
    final List<MatchModel> pairs = [];

    for (int i = 0; i + 1 < teams.length; i += 2) {
      pairs.add(MatchModel(id: 'm${i ~/ 2 + 1}', teamA: teams[i], teamB: teams[i + 1]));
    }

    // if odd number — give a bye (create a match with teamB = 'BYE')
    if (teams.length.isOdd) {
      final last = teams.last;
      pairs.add(
        MatchModel(id: 'm${pairs.length + 1}', teamA: last, teamB: 'BYE', status: 'planned'),
      );
    }

    setState(() => _matches = pairs);
  }

  Future<void> _pickDateForMatch(int idx) async {
    final initial = _matches[idx].scheduledAt ?? DateTime.now().add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 10, minute: 0),
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
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Set date',
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _pickDateForMatch(idx),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: () {
                      // placeholder: start match navigation
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Start match (${match.teamA} vs ${match.teamB}) — implement routing.',
                          ),
                        ),
                      );
                    },
                    child: const Text('Start'),
                  ),
                ],
              )
            : null,
        onTap: () {
          // open match detail / summary — for MVP show simple dialog
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('Match ${idx + 1}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Teams: ${match.teamA} vs ${match.teamB}'),
                  const SizedBox(height: 8),
                  Text('Scheduled: $scheduledStr'),
                  const SizedBox(height: 8),
                  Text('Status: ${match.status}'),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              ],
            ),
          );
        },
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
                  /* view bracket or show printable */
                },
          child: const Text('View Bracket'),
        ),
      );
    }

    // creator actions
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _matches.isEmpty
                  ? _generateAutoDraws
                  : () {
                      // regenerate confirmation
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Regenerate draws?'),
                          content: const Text(
                            'This will discard current draws and create new pairings.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _generateAutoDraws();
                              },
                              child: const Text('Regenerate'),
                            ),
                          ],
                        ),
                      );
                    },
              child: Text(_matches.isEmpty ? 'Generate Draws' : 'Regenerate Draws'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
              onPressed: _matches.isEmpty
                  ? null
                  : () {
                      // publish/save draws (MVP: just show message)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Draws saved / published (implement backend save).'),
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
          // toggles
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

          // info & team summary
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

          // matches list
          Expanded(
            child: _matches.isEmpty
                ? Center(
                    child: Text(
                      widget.isCreator
                          ? 'No draws generated yet. Tap Generate Draws.'
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
