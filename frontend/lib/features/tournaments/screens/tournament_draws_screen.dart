// lib/features/tournaments/screens/tournament_draws_screen.dart

import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';

// ✅ Models import
import '../models/tournament_model.dart';

// ✅ Correct detail screens
import 'tournament_details_creator_screen.dart';
import 'tournament_details_viewer_screen.dart';

import '../../../core/api_client.dart';

class TournamentDrawsScreen extends StatefulWidget {
  final String tournamentName;
  final String tournamentId; // ✅ NEW: required to persist to backend
  final List<String> teams;
  final bool isCreator;
  final int? overs; // Add overs parameter

  const TournamentDrawsScreen({
    super.key,
    required this.tournamentName,
    required this.tournamentId,
    required this.teams,
    this.isCreator = false,
    this.overs,
  });

  @override
  State<TournamentDrawsScreen> createState() => _TournamentDrawsScreenState();
}

class _TournamentDrawsScreenState extends State<TournamentDrawsScreen> {
  bool _autoDraw = true;
  bool _isPersisting = false;
  List<MatchModel> _matches = [];
  final Map<String, Map<String, int?>> _nameToIds =
      {}; // ✅ name -> { teamId, ttId }

  @override
  void initState() {
    super.initState();
    _fetchTournamentTeams();
  }

  Future<void> _fetchTournamentTeams() async {
    try {
      final resp = await ApiClient.instance.get(
        '/api/tournament-teams/${widget.tournamentId}',
      );
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final List<dynamic> rows =
            decoded is Map<String, dynamic> && decoded.containsKey('data')
            ? List<dynamic>.from(decoded['data'] as List)
            : List<dynamic>.from(decoded as List);
        // Map registered team names -> team_id; temp teams get null id
        for (final r in rows) {
          final m = r as Map<String, dynamic>;
          final name = (m['team_name'] ?? m['temp_team_name'] ?? '').toString();
          if (name.isEmpty) continue;
          _nameToIds[name] = {
            'teamId': m['team_id'] == null
                ? null
                : int.tryParse(m['team_id'].toString()),
            'ttId': int.tryParse(m['id']?.toString() ?? ''),
          };
        }
      }
    } catch (_) {}
  }

  void _generateAutoDraws() {
    final teams = List<String>.from(widget.teams);
    teams.shuffle(Random());
    final List<MatchModel> pairs = [];

    for (int i = 0; i + 1 < teams.length; i += 2) {
      pairs.add(
        MatchModel(id: 'm${i ~/ 2 + 1}', teamA: teams[i], teamB: teams[i + 1]),
      );
    }

    // For odd teams, don't create a match against 'BYE'
    // The backend will handle bye logic in auto mode

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
                items: widget.teams
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => selectedA = val,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                hint: const Text("Select Team B"),
                items: widget.teams
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => selectedB = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedA != null &&
                    selectedB != null &&
                    selectedA != selectedB) {
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
    final initial =
        _matches[idx].scheduledAt ??
        DateTime.now().add(const Duration(days: 1));
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

    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bracket view coming soon...'),
                    ),
                  );
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
              ),
              onPressed: _matches.isEmpty || _isPersisting
                  ? null
                  : _persistMatches,
              child: _isPersisting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_autoDraw ? 'Generate & Publish Auto Draws' : 'Save & Publish Manual Draws'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _persistMatches() async {
    if (_isPersisting) return; // Prevent multiple submissions

    setState(() {
      _isPersisting = true;
    });

    try {
      if (_autoDraw) {
        // Call backend for auto draw generation
        final resp = await ApiClient.instance.post(
          '/api/tournament-matches/create',
          body: {
            'tournament_id': widget.tournamentId,
            'mode': 'auto',
          },
        );

        if (!mounted) return;
        if (resp.statusCode == 200 || resp.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Auto draws generated and published')),
          );

          // Fetch the generated matches from backend
          await _fetchGeneratedMatches();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to generate auto draws (${resp.statusCode})')),
          );
          return;
        }
      } else {
        // Manual mode - build payload for manual creation
        // Ensure team mapping is complete before persisting
        if (_nameToIds.isEmpty) {
          await _fetchTournamentTeams();
        }

        final List<Map<String, dynamic>> matches = _matches.map((m) {
          final map1 = _nameToIds[m.teamA];
          final map2 = _nameToIds[m.teamB];

          // Validate that team mappings exist
          if (map1 == null || map2 == null) {
            throw Exception(
              'Team mapping not found for ${m.teamA} or ${m.teamB}',
            );
          }

          final t1 = map1['teamId'];
          final t2 = map2['teamId'];
          final tt1 = map1['ttId'];
          final tt2 = map2['ttId'];

          return {
            'team1_id': t1, // may be null for temp teams
            'team2_id': t2, // may be null for temp teams
            'team1_tt_id': tt1,
            'team2_tt_id': tt2,
            'round': 'round_1',
            'match_date': m.scheduledAt?.toIso8601String(),
            'location': null,
          };
        }).toList();

        final resp = await ApiClient.instance.post(
          '/api/tournament-matches/create',
          body: {
            'tournament_id': widget.tournamentId,
            'mode': 'manual',
            'matches': matches,
          },
        );

        if (!mounted) return;
        if (resp.statusCode == 200 || resp.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Manual matches published')),
          );

          // For manual mode, use the local matches
          _navigateToDetails(_matches);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to publish matches (${resp.statusCode})')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPersisting = false;
        });
      }
    }
  }

  Future<void> _fetchGeneratedMatches() async {
    try {
      final resp = await ApiClient.instance.get(
        '/api/tournament-matches/${widget.tournamentId}',
      );

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        List<dynamic> rows = [];
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          rows = decoded['data'] as List<dynamic>;
        } else if (decoded is List<dynamic>) {
          rows = decoded;
        }

        final List<MatchModel> generatedMatches = rows.map((r) {
          final m = r as Map<String, dynamic>;
          final dt = m['match_date'] != null ? DateTime.parse(m['match_date']) : null;
          final backendStatus = m['status']?.toString() ?? 'upcoming';

          return MatchModel(
            id: m['id']?.toString() ?? '',
            teamA: m['team1_name']?.toString() ?? 'TBD',
            teamB: m['team2_name']?.toString() ?? 'TBD',
            scheduledAt: dt,
            status: MatchStatus.fromString(backendStatus).toString(),
            parentMatchId: m['parent_match_id']?.toString(),
          );
        }).toList();

        _navigateToDetails(generatedMatches);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch generated matches')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching matches: $e')),
      );
    }
  }

  void _navigateToDetails(List<MatchModel> matches) {
    final updatedTournament = TournamentModel(
      id: widget.tournamentId,
      name: widget.tournamentName,
      status: 'upcoming',
      type: 'Knockout',
      dateRange: 'TBD',
      location: 'Unknown',
      overs: widget.overs ?? 20,
      teams: widget.teams,
      matches: matches,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => widget.isCreator
            ? TournamentDetailsCaptainScreen(tournament: updatedTournament)
            : TournamentDetailsViewerScreen(tournament: updatedTournament),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
