// lib/features/tournaments/screens/tournament_draws_screen.dart
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/tournament_model.dart';
import 'tournament_details_creator_screen.dart';
import 'tournament_details_viewer_screen.dart';
import '../../../core/api_client.dart';

class TournamentDrawsScreen extends StatefulWidget {
  final String tournamentName;
  final String tournamentId;
  final List<String> teams;
  final bool isCreator;
  final int? overs;

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
  bool _isLoading = false;
  List<MatchModel> _matches = [];
  final Map<String, Map<String, int?>> _teamMappings = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initTeams();
  }

  Future<void> _initTeams() async {
    setState(() => _isLoading = true);
    try {
      await _fetchTournamentTeams();
    } catch (e) {
      debugPrint('Error fetching teams: $e');
      _setError('Failed to load tournament teams');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setError(String message) {
    if (mounted) setState(() => _errorMessage = message);
  }

  void _clearError() {
    if (mounted) setState(() => _errorMessage = null);
  }

  dynamic _safeJsonDecode(String body) {
    try {
      if (body.isEmpty) throw const FormatException('Empty response');
      return jsonDecode(body);
    } catch (e) {
      debugPrint('JSON decode error: $e');
      rethrow;
    }
  }

  int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _safeString(dynamic value, String defaultValue) =>
      value?.toString() ?? defaultValue;

  Future<void> _fetchTournamentTeams() async {
    final resp = await ApiClient.instance.get(
      '/api/tournament-teams/${widget.tournamentId}',
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch teams (${resp.statusCode})');
    }

    final decoded = _safeJsonDecode(resp.body);
    List<dynamic> rows = [];
    if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
      rows = decoded['data'];
    }
    if (decoded is List) rows = decoded;

    _teamMappings.clear();
    for (final r in rows) {
      if (r is Map<String, dynamic>) {
        final name = _safeString(r['team_name'] ?? r['temp_team_name'], '');
        if (name.isNotEmpty) {
          _teamMappings[name] = {
            'teamId': _safeParseInt(r['team_id']),
            'ttId': _safeParseInt(r['id']),
          };
        }
      }
    }
    debugPrint('Loaded ${_teamMappings.length} teams');
  }

  void _generateAutoDraws() {
    final teams = List<String>.from(widget.teams);
    if (teams.isEmpty) return _setError('No teams available');

    teams.shuffle(Random());
    final List<MatchModel> pairs = [];
    for (int i = 0; i + 1 < teams.length; i += 2) {
      pairs.add(
        MatchModel(
          id: 'm${i ~/ 2 + 1}',
          teamA: teams[i],
          teamB: teams[i + 1],
          status: 'planned',
          // Note: IDs are not available here yet, they are mapped during persistence
        ),
      );
    }
    if (mounted) {
      setState(() {
        _matches = pairs;
        _errorMessage = null;
      });
    }
  }

  Future<void> _addManualMatch() async {
    if (widget.teams.length < 2) return _showMessage('Need at least 2 teams');

    String? selectedA;
    String? selectedB;

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Create Match"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                hint: const Text("Select Team A"),
                items: widget.teams
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedA = val),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                hint: const Text("Select Team B"),
                items: widget.teams
                    .where((t) => t != selectedA)
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedB = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed:
                  (selectedA != null &&
                      selectedB != null &&
                      selectedA != selectedB)
                  ? () => Navigator.pop(dialogContext, {
                      'teamA': selectedA!,
                      'teamB': selectedB!,
                    })
                  : null,
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _matches.add(
          MatchModel(
            id: 'm${_matches.length + 1}',
            teamA: result['teamA']!,
            teamB: result['teamB']!,
            status: 'planned',
          ),
        );
        _errorMessage = null;
      });
    }
  }

  Future<void> _pickDateForMatch(int idx) async {
    if (idx < 0 || idx >= _matches.length) return;
    final initial =
        _matches[idx].scheduledAt ??
        DateTime.now().add(const Duration(days: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (mounted) setState(() => _matches[idx].scheduledAt = picked);
  }

  Widget _matchTile(MatchModel match, int idx) {
    final scheduledStr = match.scheduledAt != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(match.scheduledAt!)
        : 'Not scheduled';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(child: Text('${idx + 1}')),
        title: Text(
          '${match.teamA} vs ${match.teamB}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(scheduledStr),
        trailing: widget.isCreator
            ? IconButton(
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
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          onPressed: _matches.isEmpty
              ? null
              : () => _showMessage('Bracket view coming soon...'),
          child: const Text('View Bracket'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: (_isPersisting || _isLoading)
                  ? null
                  : (_autoDraw ? _generateAutoDraws : _addManualMatch),
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
              onPressed: _matches.isEmpty || _isPersisting || _isLoading
                  ? null
                  : _persistMatches,
              child: _isPersisting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _autoDraw ? 'Generate & Publish' : 'Save & Publish',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _persistMatches() async {
    if (_isPersisting || _isLoading) return;
    setState(() => _isPersisting = true);

    try {
      if (_autoDraw) {
        await _persistAutoMatches();
      } else {
        await _persistManualMatches();
      }
    } catch (e) {
      _showMessage('Error: ${e.toString()}', isError: true);
      debugPrint('Persist error: $e');
    } finally {
      if (mounted) setState(() => _isPersisting = false);
    }
  }

  Future<void> _persistAutoMatches() async {
    final resp = await ApiClient.instance.post(
      '/api/tournament-matches/create',
      body: {'tournament_id': widget.tournamentId, 'mode': 'auto'},
    );
    if (!mounted) return;
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      _showMessage('Auto draws generated and published');
      await _fetchGeneratedMatches();
    } else {
      throw Exception('Failed to generate auto draws (${resp.statusCode})');
    }
  }

  Future<void> _persistManualMatches() async {
    if (_teamMappings.isEmpty) await _fetchTournamentTeams();
    if (!mounted) return;

    final matchesPayload = _matches.map((m) {
      final mapA = _teamMappings[m.teamA];
      final mapB = _teamMappings[m.teamB];
      if (mapA == null || mapB == null) {
        throw Exception('Team mapping not found for ${m.teamA} or ${m.teamB}');
      }
      return {
        'team1_id': mapA['teamId'],
        'team2_id': mapB['teamId'],
        'team1_tt_id': mapA['ttId'],
        'team2_tt_id': mapB['ttId'],
        'round': 'round_1',
        'match_date': m.scheduledAt?.toIso8601String(),
      };
    }).toList();

    final resp = await ApiClient.instance.post(
      '/api/tournament-matches/create',
      body: {
        'tournament_id': widget.tournamentId,
        'mode': 'manual',
        'matches': matchesPayload,
      },
    );
    if (!mounted) return;
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      _showMessage('Manual matches published');
      await _fetchGeneratedMatches(); // Fetch real IDs from server
    } else {
      throw Exception('Failed to publish matches (${resp.statusCode})');
    }
  }

  Future<void> _fetchGeneratedMatches() async {
    final resp = await ApiClient.instance.get(
      '/api/tournament-matches/${widget.tournamentId}',
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch matches (${resp.statusCode})');
    }

    final decoded = _safeJsonDecode(resp.body);
    List<dynamic> rows = [];
    if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
      rows = decoded['data'];
    }
    if (decoded is List) rows = decoded;

    final generatedMatches = rows
        .map((r) {
          if (r is! Map<String, dynamic>) return null;
          DateTime? dt;
          if (r['match_date'] != null) {
            dt = DateTime.tryParse(r['match_date'].toString());
          }
          final status = _safeString(r['status'], 'upcoming');

          return MatchModel(
            id: _safeString(r['id'], ''),
            teamA: _safeString(r['team1_name'], 'TBD'),
            teamB: _safeString(r['team2_name'], 'TBD'),
            // CRITICAL FIX: Map the IDs here!
            teamAId: _safeParseInt(r['team1_id']),
            teamBId: _safeParseInt(r['team2_id']),
            scheduledAt: dt,
            status: status,
            parentMatchId: r['parent_match_id']?.toString(),
          );
        })
        .whereType<MatchModel>()
        .toList();

    if (!mounted) return;
    if (generatedMatches.isEmpty) {
      // If auto draw returned success but no matches, maybe refresh later or show info
      _showMessage("No matches returned from server yet.");
      return;
    }

    _navigateToDetails(generatedMatches);
  }

  void _navigateToDetails(List<MatchModel> matches) {
    if (!mounted) return;

    final tournament = TournamentModel(
      id: widget.tournamentId,
      name: widget.tournamentName,
      status: 'upcoming',
      type: 'Knockout',
      dateRange: 'TBD',
      location: 'Unknown',
      overs: widget.overs ?? 20,
      teams: widget.teams.map((t) => TournamentTeam(id: '', name: t)).toList(),
      matches: List<MatchModel>.from(matches),
      // Pass ownership down
      createdBy: widget.isCreator
          ? '1'
          : null, // Simplified logic, real check happens in screen
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => widget.isCreator
            ? TournamentDetailsCreatorScreen(tournament: tournament)
            : TournamentDetailsViewerScreen(tournament: tournament),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_errorMessage != null) _buildErrorBanner(),
                if (widget.isCreator) _buildDrawModeChips(),
                _buildTeamChips(),
                const SizedBox(height: 8),
                Expanded(child: _buildMatchesList()),
              ],
            ),
      bottomNavigationBar: _bottomAction(),
    );
  }

  Widget _buildErrorBanner() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    color: Colors.red.shade100,
    child: Row(
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _errorMessage!,
            style: TextStyle(color: Colors.red.shade700),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: _clearError,
          color: Colors.red.shade700,
        ),
      ],
    ),
  );

  Widget _buildDrawModeChips() => Padding(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Text('Auto Draws'),
            selected: _autoDraw,
            onSelected: _isPersisting
                ? null
                : (_) => setState(() => _autoDraw = true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ChoiceChip(
            label: const Text('Manual Draws'),
            selected: !_autoDraw,
            onSelected: _isPersisting
                ? null
                : (_) => setState(() => _autoDraw = false),
          ),
        ),
      ],
    ),
  );

  Widget _buildTeamChips() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
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
                      child: Text(
                        t,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildMatchesList() {
    if (_matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            widget.isCreator
                ? (_autoDraw
                      ? 'No draws yet. Tap Generate Draws.'
                      : 'No matches yet. Tap Add Manual Match.')
                : 'Draws not published yet.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _matches.length,
      itemBuilder: (context, i) => _matchTile(_matches[i], i),
    );
  }
}
