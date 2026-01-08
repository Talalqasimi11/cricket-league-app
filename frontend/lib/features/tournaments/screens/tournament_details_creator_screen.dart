import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/api_service.dart';
import '../models/tournament_model.dart' as local;

import '../../matches/screens/live_match_scoring_screen.dart';
import '../../matches/screens/scorecard_screen.dart';
import '../screens/tournament_team_registration_screen.dart';
import '../../../core/api_client.dart';
import '../../../core/auth_provider.dart';
import '../../../widgets/tournament_bracket_widget.dart';
import 'package:provider/provider.dart';
import '../../tournaments/widgets/tournament_stats_view.dart';

class TournamentDetailsCreatorScreen extends StatefulWidget {
  final local.TournamentModel tournament;

  const TournamentDetailsCreatorScreen({super.key, required this.tournament});

  @override
  State<TournamentDetailsCreatorScreen> createState() =>
      _TournamentDetailsCreatorScreenState();
}

class _TournamentDetailsCreatorScreenState
    extends State<TournamentDetailsCreatorScreen> {
  late local.TournamentModel _tournament;
  late List<local.MatchModel> _matches;
  String? _reschedulingMatchId;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tournament = widget.tournament;
    _matches = List.from(widget.tournament.matches ?? []);
  }

  // --- Helpers ---

  String _safeString(String? value, String defaultValue) =>
      value == null || value.isEmpty ? defaultValue : value;

  String _safeFormatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'TBD';
    try {
      return dateTime.toLocal().toString().substring(0, 16);
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return 'Invalid date';
    }
  }

  int _safeExtractMatchNumber(String? id, int fallback) {
    if (id == null || id.isEmpty) return fallback;
    final numbersOnly = id.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(numbersOnly) ?? fallback;
  }

  bool _isCompleted(String? status) => status?.toLowerCase() == 'completed';
  bool _isUpcoming(String? status) =>
      status?.toLowerCase() == 'scheduled' ||
      status?.toLowerCase() == 'upcoming' ||
      status?.toLowerCase() == 'planned';
  bool _isLive(String? status) => status?.toLowerCase() == 'live';

  dynamic _safeJsonDecode(String body) {
    try {
      if (body.isEmpty) throw const FormatException('Empty response body');
      return jsonDecode(body);
    } catch (e) {
      debugPrint('JSON decode error: $e');
      throw const FormatException('Invalid JSON response');
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _refreshTournamentData() async {
    setState(() => _isRefreshing = true);
    try {
      final response = await ApiClient.instance.get(
        '/api/tournaments/${_tournament.id}',
        forceRefresh: true,
      );
      if (response.statusCode == 200) {
        final decoded = _safeJsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final tournamentData = decoded.containsKey('data')
              ? decoded['data']
              : decoded;
          final updated = local.TournamentModel.fromJson(tournamentData);
          if (mounted) {
            setState(() {
              _tournament = updated;
              _matches = List.from(updated.matches ?? []);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error refreshing tournament: $e');
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  // --- Actions ---

  // --- Delete Actions ---

  Future<void> _deleteTournament() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tournament?'),
        content: const Text(
          'Are you sure you want to delete this tournament? This action cannot be undone and will delete all matches and data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await ApiClient.instance.delete(
        '/api/tournaments/${_tournament.id}',
      );
      if (response.statusCode == 200) {
        _showMessage('Tournament deleted');
        if (mounted) Navigator.pop(context); // Go back to list
      } else {
        _showMessage('Failed to delete tournament', isError: true);
      }
    } catch (e) {
      _showMessage('Error deleting tournament: $e', isError: true);
    }
  }

  Future<void> _removeTeam(String teamTournamentId, String teamName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove $teamName?'),
        content: const Text(
          'Are you sure you want to remove this team from the tournament?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Endpoint expects body with id and tournament_id
      final response = await ApiClient.instance.delete(
        '/api/tournament-teams',
        body: {'id': teamTournamentId, 'tournament_id': _tournament.id},
      );

      if (response.statusCode == 200) {
        _showMessage('Team removed');
        _refreshTournamentData();
      } else {
        String msg = 'Failed to remove team';
        try {
          final body = jsonDecode(response.body);
          if (body['error'] != null) msg = body['error'];
        } catch (_) {}
        _showMessage(msg, isError: true);
      }
    } catch (e) {
      _showMessage('Error removing team: $e', isError: true);
    }
  }

  Future<void> _deleteMatch(local.MatchModel m) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Match?'),
        content: Text('Delete match ${m.teamA} vs ${m.teamB}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await ApiClient.instance.delete(
        '/api/tournament-matches/delete/${m.id}',
      );
      if (response.statusCode == 200) {
        _showMessage('Match deleted');
        _refreshTournamentData();
      } else {
        _showMessage('Failed to delete match', isError: true);
      }
    } catch (e) {
      _showMessage('Error deleting match: $e', isError: true);
    }
  }

  Future<void> _editTournamentDetails() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      _showMessage('Please login to edit tournament', isError: true);
      return;
    }

    final nameCtrl = TextEditingController(text: _tournament.name);
    final locationCtrl = TextEditingController(text: _tournament.location);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Tournament'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Tournament Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locationCtrl,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                // Optimistic update
                setState(() {
                  // Just trigger rebuild for now, real update happens on refresh
                });

                final response = await ApiClient.instance.put(
                  '/api/tournaments/${_tournament.id}',
                  body: {
                    'tournament_name': nameCtrl.text.trim(),
                    'location': locationCtrl.text.trim(),
                  },
                );

                if (response.statusCode == 200) {
                  _showMessage('Tournament updated');
                  _refreshTournamentData();
                } else {
                  _showMessage('Failed to update', isError: true);
                }
              } catch (e) {
                _showMessage('Update error: $e', isError: true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _manageTeams() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      _showMessage('Please login to manage teams', isError: true);
      // Optional: Navigate to login screen
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TournamentTeamRegistrationScreen(
          tournamentName: _tournament.name,
          tournamentId: _tournament.id,
        ),
      ),
    );
    _refreshTournamentData();
  }

  void _showAddMatchDialog() {
    if (_tournament.teams.length < 2) {
      _showMessage('Need at least 2 teams to create a match', isError: true);
      return;
    }

    // [Added] Filter out teams that already have a scheduled/live match
    // We check against _matches list.
    final teamsWithMatches = <String>{};
    for (final m in _matches) {
      if (m.status.toLowerCase() != 'cancelled') {
        if (m.teamA.isNotEmpty) teamsWithMatches.add(m.teamA);
        if (m.teamB.isNotEmpty) teamsWithMatches.add(m.teamB);
      }
    }

    final availableTeams = _tournament.teams
        .where((t) => !teamsWithMatches.contains(t.name))
        .toList();

    if (availableTeams.length < 2) {
      _showMessage(
        'Not enough available teams to schedule a match',
        isError: true,
      );
      return;
    }

    String? selectedTeamA;
    String? selectedTeamB;
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Schedule Match'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Team A'),
                  initialValue: selectedTeamA,
                  items: availableTeams
                      .map(
                        (t) => DropdownMenuItem(
                          value: t.name,
                          child: Text(t.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setDialogState(() {
                      selectedTeamA = v;
                      // Reset Team B if it matches the new Team A
                      if (selectedTeamB == v) selectedTeamB = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Team B'),
                  initialValue: selectedTeamB,
                  items: availableTeams.map((t) {
                    final isDisabled = t.name == selectedTeamA;
                    return DropdownMenuItem(
                      value: t.name,
                      enabled: !isDisabled,
                      child: Text(
                        t.name,
                        style: TextStyle(
                          color: isDisabled ? Colors.grey : null,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedTeamB = v),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          "${selectedDate.day}/${selectedDate.month}",
                        ),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (d != null) setDialogState(() => selectedDate = d);
                        },
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text(selectedTime.format(context)),
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (t != null) setDialogState(() => selectedTime = t);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedTeamA == null || selectedTeamB == null) return;
                if (selectedTeamA == selectedTeamB) {
                  _showMessage('Teams must be different', isError: true);
                  return;
                }

                Navigator.pop(ctx);

                final matchDt = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                try {
                  final response = await ApiClient.instance.post(
                    '/api/tournament-matches/manual',
                    body: {
                      'tournament_id': _tournament.id,
                      'team1_name': selectedTeamA,
                      'team2_name': selectedTeamB,
                      'match_date': matchDt.toIso8601String(),
                      'round': 'group_stage',
                    },
                  );

                  if (response.statusCode == 200 ||
                      response.statusCode == 201) {
                    _showMessage('Match scheduled');
                    _refreshTournamentData();
                  } else {
                    String errorMessage = 'Failed to schedule';
                    try {
                      final body = jsonDecode(response.body);
                      if (body is Map && body.containsKey('error')) {
                        errorMessage = body['error'];
                      }
                    } catch (_) {}

                    if (errorMessage.toLowerCase().contains(
                      'match scheduled',
                    )) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Scheduling Conflict"),
                          content: const Text(
                            "One or both teams already have a match scheduled for this time. Please select a different team or time.",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );
                    } else {
                      _showMessage(errorMessage, isError: true);
                    }
                  }
                } catch (e) {
                  _showMessage('Error: $e', isError: true);
                }
              },
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tournamentName = _safeString(_tournament.name, 'Tournament');

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tournamentName),
          centerTitle: true,
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _editTournamentDetails();
                if (value == 'delete') _deleteTournament();
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Edit Details'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Tournament'),
                      ],
                    ),
                  ),
                ];
              },
            ),
            IconButton(
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _isRefreshing ? null : _refreshTournamentData,
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Info'),
              Tab(text: 'Matches'),
              Tab(text: 'Bracket'),
              Tab(text: 'Stats'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInfoTab(),
            _buildMatchesTab(context),
            _buildBracketTab(),
            TournamentStatsView(tournamentId: _tournament.id),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddMatchDialog,
          backgroundColor: Colors.green.shade600,
          tooltip: 'Add Match',
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return RefreshIndicator(
      onRefresh: _refreshTournamentData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tournament Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _infoRow('Name', _safeString(_tournament.name, 'N/A')),
                  _infoRow('Type', _safeString(_tournament.type, 'N/A')),
                  _infoRow(
                    'Location',
                    _safeString(_tournament.location, 'N/A'),
                  ),
                  _infoRow('Overs', _tournament.overs.toString()),
                  _infoRow(
                    'Date Range',
                    _safeString(_tournament.dateRange, 'N/A'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Teams (${_tournament.teams.length})',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _manageTeams,
                icon: const Icon(Icons.settings),
                label: const Text('Manage'),
              ),
            ],
          ),
          if (_tournament.teams.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'No teams added yet. Click "Manage" to add teams.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._tournament.teams.map((t) {
              final logoUrl = ApiService().getImageUrl(t.logo);
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: logoUrl.isNotEmpty
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: logoUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                              errorWidget: (context, url, error) =>
                                  CircleAvatar(
                                    backgroundColor: Colors.blue.shade100,
                                    child: Text(
                                      t.name.isNotEmpty
                                          ? t.name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                            ),
                          )
                        : CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              t.name.isNotEmpty ? t.name[0].toUpperCase() : '?',
                              style: TextStyle(color: Colors.blue.shade800),
                            ),
                          ),
                  ),
                  title: Text(
                    t.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: t.location != null ? Text(t.location!) : null,
                  dense: true,
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                    onPressed: () => _removeTeam(t.id, t.name),
                  ),
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildMatchesTab(BuildContext context) {
    if (_matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports_cricket, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                "No matches scheduled",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Use the + button to add a match",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshTournamentData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _matches.length + 1,
        itemBuilder: (context, index) {
          if (index == _matches.length) return const SizedBox(height: 80);

          final m = _matches[index];
          final matchNo = _safeExtractMatchNumber(m.id, index + 1);

          final isCompleted = _isCompleted(m.status);
          final isUpcoming = _isUpcoming(m.status);

          return MatchCard(
            matchNo: matchNo,
            teamA: _safeString(m.teamA, 'Team A'),
            teamB: _safeString(m.teamB, 'Team B'),
            result: isCompleted
                ? "Winner: ${_safeString(m.winner, 'TBD')}"
                : null,
            scheduled: _safeFormatDateTime(m.scheduledAt),
            editable: isUpcoming,
            isRescheduling: _reschedulingMatchId == m.id,
            match: m,
            onEdit: isUpcoming ? () => _handleEditMatch(index, m) : null,
            onDelete: isUpcoming ? () => _deleteMatch(m) : null,
            // [CHANGED] Re-enabled Start button for upcoming matches
            onStart: isUpcoming ? () => _handleStartMatch(m) : null,
            onViewDetails: () => _navigateToMatchDetails(m),
          );
        },
      ),
    );
  }

  Widget _buildBracketTab() {
    if (_matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No matches found.'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _handleGenerateBracket,
              icon: const Icon(Icons.account_tree),
              label: const Text('Auto-Generate Bracket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return TournamentBracketWidget(
      matches: _matches,
      onMatchTap: (m) => _showMatchOptions(m),
      tournamentWinner: _tournament.winnerName,
    );
  }

  Future<void> _handleEditMatch(int idx, local.MatchModel m) async {
    final newDate = await _pickDate(m.scheduledAt);
    if (!mounted || newDate == null) return;

    setState(() => _reschedulingMatchId = m.id);

    final updatedMatch = m.copyWith(scheduledAt: newDate);
    setState(() => _matches[idx] = updatedMatch);

    try {
      final response = await ApiClient.instance.put(
        '/api/tournament-matches/update/${m.id}',
        body: {'match_date': newDate.toIso8601String()},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showMessage("Match rescheduled to ${_safeFormatDateTime(newDate)}");
      } else {
        setState(() => _matches[idx] = m);
        String errorMessage = 'Failed to reschedule match';
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body.containsKey('error')) {
            errorMessage = body['error'];
          }
        } catch (_) {}
        _showMessage(errorMessage, isError: true);
      }
    } catch (e) {
      setState(() => _matches[idx] = m);
      _showMessage('Error rescheduling match: $e', isError: true);
    } finally {
      if (mounted) setState(() => _reschedulingMatchId = null);
    }
  }

  Future<void> _handleStartMatch(local.MatchModel m) async {
    try {
      final response = await ApiClient.instance.put(
        '/api/tournament-matches/start/${m.id}',
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        final matchId = data['match_id']?.toString();
        if (matchId != null && matchId.isNotEmpty) {
          // Navigate to live scoring
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LiveMatchScoringScreen(
                matchId: matchId,
                teamA: m.teamA,
                teamB: m.teamB,
                teamAId: m.teamAId,
                teamBId: m.teamBId,
              ),
            ),
          );
          if (mounted) _refreshTournamentData();
        } else {
          _showMessage('Invalid match ID returned', isError: true);
        }
      } else {
        String errorMessage = 'Failed to start match';
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body.containsKey('error')) {
            errorMessage = body['error'];
          }
        } catch (_) {}
        _showMessage(errorMessage, isError: true);
      }
    } catch (e) {
      _showMessage('Error starting match: $e', isError: true);
    }
  }

  Future<DateTime?> _pickDate(DateTime? initial) async {
    if (!mounted) return null;
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: initial != null
          ? TimeOfDay.fromDateTime(initial)
          : const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _navigateToMatchDetails(local.MatchModel match) async {
    final matchId = match.parentMatchId ?? match.id;
    if (matchId.isEmpty) return;

    if (_isLive(match.status)) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LiveMatchScoringScreen(
            matchId: matchId,
            teamA: match.teamA,
            teamB: match.teamB,
            teamAId: match.teamAId,
            teamBId: match.teamBId,
          ),
        ),
      );
      if (mounted) _refreshTournamentData();
    } else if (_isCompleted(match.status)) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ScorecardScreen(matchId: matchId)),
      );
    } else {
      _showUpcomingMatchDialog(match);
    }
  }

  Future<void> _handleGenerateBracket() async {
    try {
      final response = await ApiClient.instance.post(
        '/api/tournament-matches/generate-bracket/${_tournament.id}',
        body: {},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showMessage("Bracket generated successfully!");
        _refreshTournamentData();
      } else {
        String errorMessage = 'Failed to generate bracket';
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body.containsKey('error')) {
            errorMessage = body['error'];
          }
        } catch (_) {}
        _showMessage(errorMessage, isError: true);
      }
    } catch (e) {
      _showMessage('Error generating bracket: $e', isError: true);
    }
  }

  void _showMatchOptions(local.MatchModel match) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final isUpcoming = match.isUpcoming;

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToMatchDetails(match);
                },
              ),
              if (isUpcoming && match.teamAId != null && match.teamBId != null)
                ListTile(
                  leading: const Icon(Icons.play_arrow, color: Colors.green),
                  title: const Text('Start Match'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleStartMatch(match);
                  },
                ),
              if (isUpcoming) ...[
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('Edit Match'),
                  onTap: () {
                    Navigator.pop(context);
                    // Find index if needed, or just pass match
                    final idx = _matches.indexWhere((m) => m.id == match.id);
                    if (idx != -1) _handleEditMatch(idx, match);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete Match'),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMatch(match);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showUpcomingMatchDialog(local.MatchModel match) {
    final scheduled = _safeFormatDateTime(match.scheduledAt);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Match ${_safeString(match.id, 'Details')}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${_safeString(match.teamA, 'Team A')} vs ${_safeString(match.teamB, 'Team B')}",
            ),
            const SizedBox(height: 8),
            Text("Status: ${_safeString(match.status, 'Unknown')}"),
            if (scheduled.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text("Scheduled: $scheduled"),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
          // [ADDED] Start Match button in Dialog
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleStartMatch(match);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              "Start Match",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class MatchCard extends StatelessWidget {
  final int matchNo;
  final String teamA;
  final String teamB;
  final String? result;
  final String? scheduled;
  final bool editable;
  final bool isRescheduling;
  final local.MatchModel match;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onStart;
  final VoidCallback? onViewDetails;

  const MatchCard({
    super.key,
    required this.matchNo,
    required this.teamA,
    required this.teamB,
    this.result,
    this.scheduled,
    this.editable = false,
    this.isRescheduling = false,
    required this.match,
    this.onEdit,
    this.onDelete,
    this.onStart,
    this.onViewDetails,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Match ${matchNo > 0 ? matchNo : 'N/A'}",
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    if (editable && onEdit != null && !isRescheduling)
                      IconButton(
                        icon: const Icon(
                          Icons.edit_calendar,
                          size: 20,
                          color: Colors.green,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onEdit,
                      ),
                    if (editable && onDelete != null && !isRescheduling)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.red,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onDelete,
                      ),
                    if (isRescheduling)
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "$teamA vs $teamB",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            if (result != null)
              Text(result!, style: const TextStyle(color: Colors.grey)),
            if (scheduled != null)
              Text(
                "Scheduled: $scheduled",
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onViewDetails,
                    child: const Text("Details"),
                  ),
                ),
                if (onStart != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Start"),
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
