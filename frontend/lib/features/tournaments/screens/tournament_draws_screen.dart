// lib/features/tournaments/screens/tournament_draws_screen.dart

import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';

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
  final Map<String, Map<String, int?>> _nameToIds = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _safeInit();
  }

  Future<void> _safeInit() async {
    setState(() => _isLoading = true);
    try {
      await _fetchTournamentTeams();
    } catch (e) {
      debugPrint('Error in init: $e');
      _setError('Failed to load tournament teams');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setError(String message) {
    if (mounted) {
      setState(() => _errorMessage = message);
    }
  }

  void _clearError() {
    if (mounted) {
      setState(() => _errorMessage = null);
    }
  }

  // Safe JSON decode with validation
  dynamic _safeJsonDecode(String body) {
    try {
      if (body.isEmpty) {
        throw const FormatException('Empty response body');
      }
      return jsonDecode(body);
    } on FormatException catch (e) {
      debugPrint('JSON decode error: $e');
      debugPrint('Response body: $body');
      throw FormatException('Invalid JSON response: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected decode error: $e');
      rethrow;
    }
  }

  // Safe type conversion helpers
  T? _safeCast<T>(dynamic value) {
    try {
      if (value == null) return null;
      if (value is T) return value;
      return null;
    } catch (e) {
      debugPrint('Cast error: $e');
      return null;
    }
  }

  int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _safeString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  Future<void> _fetchTournamentTeams() async {
    try {
      final resp = await ApiClient.instance.get(
        '/api/tournament-teams/${widget.tournamentId}',
      );

      if (resp.statusCode != 200) {
        debugPrint('Failed to fetch teams: ${resp.statusCode}');
        debugPrint('Response: ${resp.body}');
        throw Exception('Failed to fetch teams (${resp.statusCode})');
      }

      final decoded = _safeJsonDecode(resp.body);
      if (decoded == null) {
        throw const FormatException('Null response body');
      }

      List<dynamic> rows = [];
      
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('data')) {
          final data = decoded['data'];
          if (data is List) {
            rows = data;
          } else {
            debugPrint('Expected List in "data" but got: ${data.runtimeType}');
          }
        }
      } else if (decoded is List) {
        rows = decoded;
      } else {
        debugPrint('Unexpected response format: ${decoded.runtimeType}');
      }

      if (!mounted) return;

      // Clear existing mappings
      _nameToIds.clear();

      // Process team data
      for (final r in rows) {
        try {
          if (r is! Map<String, dynamic>) {
            debugPrint('Invalid team data: ${r.runtimeType}');
            continue;
          }

          final m = r as Map<String, dynamic>;
          final name = _safeString(
            m['team_name'] ?? m['temp_team_name'] ?? '',
            '',
          );

          if (name.isEmpty) continue;

          _nameToIds[name] = {
            'teamId': _safeParseInt(m['team_id']),
            'ttId': _safeParseInt(m['id']),
          };
        } catch (e) {
          debugPrint('Error processing team: $e');
          continue;
        }
      }

      debugPrint('Loaded ${_nameToIds.length} team mappings');
    } catch (e, stackTrace) {
      debugPrint('Error fetching tournament teams: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  void _generateAutoDraws() {
    try {
      final teams = List<String>.from(widget.teams);
      if (teams.isEmpty) {
        _setError('No teams available for draws');
        return;
      }

      teams.shuffle(Random());
      final List<MatchModel> pairs = [];

      for (int i = 0; i + 1 < teams.length; i += 2) {
        pairs.add(
          MatchModel(
            id: 'm${i ~/ 2 + 1}',
            teamA: teams[i],
            teamB: teams[i + 1],
            status: 'planned',
          ),
        );
      }

      setState(() {
        _matches = pairs;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('Error generating auto draws: $e');
      _setError('Failed to generate draws');
    }
  }

  void _addManualMatch() async {
    if (widget.teams.length < 2) {
      _showMessage('Need at least 2 teams to create a match');
      return;
    }

    String? selectedA;
    String? selectedB;

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Create Match"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    hint: const Text("Select Team A"),
                    value: selectedA,
                    items: widget.teams
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) {
                      setDialogState(() => selectedA = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    hint: const Text("Select Team B"),
                    value: selectedB,
                    items: widget.teams
                        .where((t) => t != selectedA) // Prevent same team
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) {
                      setDialogState(() => selectedB = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: (selectedA != null && 
                              selectedB != null && 
                              selectedA != selectedB)
                      ? () {
                          Navigator.pop(dialogContext, {
                            'teamA': selectedA!,
                            'teamB': selectedB!,
                          });
                        }
                      : null,
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;

    try {
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
    } catch (e) {
      debugPrint('Error adding manual match: $e');
      _setError('Failed to add match');
    }
  }

  Future<void> _pickDateForMatch(int idx) async {
    try {
      if (idx < 0 || idx >= _matches.length) {
        debugPrint('Invalid match index: $idx');
        return;
      }

      final initial =
          _matches[idx].scheduledAt ?? DateTime.now().add(const Duration(days: 1));
      
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

      if (mounted && idx < _matches.length) {
        setState(() {
          _matches[idx].scheduledAt = picked;
        });
      }
    } catch (e) {
      debugPrint('Error picking date: $e');
      _showMessage('Failed to set date');
    }
  }

  Widget _matchTile(MatchModel match, int idx) {
    try {
      final scheduledStr = match.scheduledAt == null
          ? 'Not scheduled'
          : _formatDateTime(match.scheduledAt!);

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: CircleAvatar(
            child: Text('${idx + 1}'),
          ),
          title: Text(
            '${match.teamA}  vs  ${match.teamB}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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
    } catch (e) {
      debugPrint('Error building match tile: $e');
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          title: Text('Error loading match #${idx + 1}'),
        ),
      );
    }
  }

  String _formatDateTime(DateTime dt) {
    try {
      return dt.toLocal().toString().substring(0, 16);
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return 'Invalid date';
    }
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

  Widget _bottomAction() {
    if (!widget.isCreator) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
          onPressed: _matches.isEmpty
              ? null
              : () {
                  _showMessage('Bracket view coming soon...');
                },
          child: const Text('View Bracket'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
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
                      _autoDraw
                          ? 'Generate & Publish Auto Draws'
                          : 'Save & Publish Manual Draws',
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

    setState(() {
      _isPersisting = true;
      _errorMessage = null;
    });

    try {
      if (_autoDraw) {
        await _persistAutoMatches();
      } else {
        await _persistManualMatches();
      }
    } catch (e, stackTrace) {
      debugPrint('Error persisting matches: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        _showMessage('Error: ${_getErrorMessage(e)}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isPersisting = false);
      }
    }
  }

  Future<void> _persistAutoMatches() async {
    final resp = await ApiClient.instance.post(
      '/api/tournament-matches/create',
      body: {
        'tournament_id': widget.tournamentId,
        'mode': 'auto',
      },
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
    // Ensure team mapping is complete
    if (_nameToIds.isEmpty) {
      await _fetchTournamentTeams();
    }

    if (!mounted) return;

    final List<Map<String, dynamic>> matchesPayload = [];

    for (final m in _matches) {
      try {
        final map1 = _nameToIds[m.teamA];
        final map2 = _nameToIds[m.teamB];

        if (map1 == null || map2 == null) {
          throw Exception(
            'Team mapping not found for ${m.teamA} or ${m.teamB}',
          );
        }

        matchesPayload.add({
          'team1_id': map1['teamId'],
          'team2_id': map2['teamId'],
          'team1_tt_id': map1['ttId'],
          'team2_tt_id': map2['ttId'],
          'round': 'round_1',
          'match_date': m.scheduledAt?.toIso8601String(),
          'location': null,
        });
      } catch (e) {
        debugPrint('Error building match payload: $e');
        throw Exception('Failed to prepare match data: ${m.teamA} vs ${m.teamB}');
      }
    }

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
      _navigateToDetails(_matches);
    } else {
      throw Exception('Failed to publish matches (${resp.statusCode})');
    }
  }

  Future<void> _fetchGeneratedMatches() async {
    try {
      final resp = await ApiClient.instance.get(
        '/api/tournament-matches/${widget.tournamentId}',
      );

      if (resp.statusCode != 200) {
        throw Exception('Failed to fetch matches (${resp.statusCode})');
      }

      final decoded = _safeJsonDecode(resp.body);
      if (decoded == null) {
        throw const FormatException('Null response body');
      }

      List<dynamic> rows = [];
      
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        final data = decoded['data'];
        if (data is List) {
          rows = data;
        }
      } else if (decoded is List) {
        rows = decoded;
      }

      final List<MatchModel> generatedMatches = [];

      for (final r in rows) {
        try {
          if (r is! Map<String, dynamic>) continue;

          final m = r as Map<String, dynamic>;
          
          DateTime? dt;
          if (m['match_date'] != null) {
            try {
              dt = DateTime.parse(m['match_date'].toString());
            } catch (e) {
              debugPrint('Error parsing date: $e');
            }
          }

          final backendStatus = _safeString(m['status'], 'upcoming');

          generatedMatches.add(
            MatchModel(
              id: _safeString(m['id'], ''),
              teamA: _safeString(m['team1_name'], 'TBD'),
              teamB: _safeString(m['team2_name'], 'TBD'),
              scheduledAt: dt,
              status: MatchStatus.fromString(backendStatus).toString(),
              parentMatchId: m['parent_match_id']?.toString(),
            ),
          );
        } catch (e) {
          debugPrint('Error parsing match: $e');
          continue;
        }
      }

      if (!mounted) return;

      if (generatedMatches.isEmpty) {
        throw Exception('No matches were generated');
      }

      _navigateToDetails(generatedMatches);
    } catch (e, stackTrace) {
      debugPrint('Error fetching generated matches: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        _showMessage('Failed to fetch generated matches', isError: true);
      }
      rethrow;
    }
  }

  void _navigateToDetails(List<MatchModel> matches) {
    if (!mounted) return;

    try {
      final updatedTournament = TournamentModel(
        id: widget.tournamentId,
        name: widget.tournamentName,
        status: 'upcoming',
        type: 'Knockout',
        dateRange: 'TBD',
        location: 'Unknown',
        overs: widget.overs ?? 20,
        teams: List<String>.from(widget.teams),
        matches: List<MatchModel>.from(matches),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => widget.isCreator
              ? TournamentDetailsCaptainScreen(tournament: updatedTournament)
              : TournamentDetailsViewerScreen(tournament: updatedTournament),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to details: $e');
      _showMessage('Failed to navigate to tournament details', isError: true);
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error == null) return 'Unknown error';
    final message = error.toString();
    return message.replaceAll('Exception:', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isPersisting) {
          _showMessage('Please wait for the current operation to complete');
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.tournamentName} — Draws'),
          backgroundColor: Colors.green[800],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                children: [
                  if (_errorMessage != null)
                    Container(
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
                    ),

                  if (widget.isCreator)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Auto Draws'),
                              selected: _autoDraw,
                              onSelected: _isPersisting
                                  ? null
                                  : (v) => setState(() => _autoDraw = true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Manual Draws'),
                              selected: !_autoDraw,
                              onSelected: _isPersisting
                                  ? null
                                  : (v) => setState(() => _autoDraw = false),
                            ),
                          ),
                        ],
                      ),
                    ),

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
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
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
                  ),

                  const SizedBox(height: 8),

                  Expanded(
                    child: _buildMatchesList(),
                  ),
                ],
              ),
        bottomNavigationBar: _bottomAction(),
      ),
    );
  }

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
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      itemCount: _matches.length,
      itemBuilder: (context, i) {
        try {
          if (i < 0 || i >= _matches.length) {
            return const SizedBox.shrink();
          }
          return _matchTile(_matches[i], i);
        } catch (e) {
          debugPrint('Error building match at index $i: $e');
          return const SizedBox.shrink();
        }
      },
    );
  }
}