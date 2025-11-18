// lib/features/tournaments/screens/tournament_details_creator_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/tournament_model.dart';
import '../../matches/screens/live_match_view_screen.dart';
import '../../matches/screens/scorecard_screen.dart';
import '../../../core/api_client.dart';
import '../../../widgets/tournament_bracket_widget.dart';

class TournamentDetailsCaptainScreen extends StatefulWidget {
  final TournamentModel tournament;

  const TournamentDetailsCaptainScreen({super.key, required this.tournament});

  @override
  State<TournamentDetailsCaptainScreen> createState() =>
      _TournamentDetailsCaptainScreenState();
}

class _TournamentDetailsCaptainScreenState
    extends State<TournamentDetailsCaptainScreen> {
  late List<MatchModel> _matches;
  String? _reschedulingMatchId;

  // Safe helpers
  String _safeString(String? value, String defaultValue) {
    if (value == null || value.isEmpty) return defaultValue;
    return value;
  }

  String? _safeFormatDateTime(DateTime? dateTime) {
    if (dateTime == null) return null;
    try {
      final str = dateTime.toLocal().toString();
      if (str.length >= 16) {
        return str.substring(0, 16);
      }
      return str;
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return 'Invalid date';
    }
  }

  String _safeFormatDateOnly(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    try {
      final str = dateTime.toString();
      if (str.contains(' ')) {
        return str.split(' ')[0];
      }
      return str;
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return 'Unknown';
    }
  }

  int _safeExtractMatchNumber(String? id, String? displayId, int fallback) {
    try {
      if (displayId != null && displayId.isNotEmpty) {
        final num = int.tryParse(displayId);
        if (num != null && num > 0) return num;
      }

      if (id == null || id.isEmpty) return fallback;

      final numbersOnly = id.replaceAll(RegExp(r'[^0-9]'), '');
      if (numbersOnly.isEmpty) return fallback;

      return int.tryParse(numbersOnly) ?? fallback;
    } catch (e) {
      debugPrint('Error extracting match number: $e');
      return fallback;
    }
  }

  MatchStatus _safeGetMatchStatus(String? status) {
    try {
      return MatchStatus.fromString(status ?? 'upcoming');
    } catch (e) {
      debugPrint('Error parsing match status: $e');
      return MatchStatus.upcoming;
    }
  }

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
  void initState() {
    super.initState();
    try {
      _matches = List.from(widget.tournament.matches ?? []);
    } catch (e) {
      debugPrint('Error initializing matches: $e');
      _matches = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournamentName = _safeString(widget.tournament.name, 'Tournament');

    return Scaffold(
      appBar: AppBar(
        title: Text(tournamentName),
        centerTitle: true,
        backgroundColor: Colors.green.shade600,
        actions: [
          if (_matches.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.account_tree),
              tooltip: 'View Bracket',
              onPressed: () => _showBracketView(context),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    try {
      if (_matches.isEmpty) {
        return _buildEmptyState();
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: _buildStages(context, _matches),
      );
    } catch (e) {
      debugPrint('Error building body: $e');
      return _buildErrorState(e.toString());
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_cricket, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              "No matches scheduled yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            const Text(
              "Error loading matches",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStages(BuildContext context, List<MatchModel> matches) {
    try {
      final List<Widget> stages = [];

      final matchCards = matches.asMap().entries.map((entry) {
        try {
          return _buildMatchCard(entry.key, entry.value);
        } catch (e) {
          debugPrint('Error building match card: $e');
          return _buildErrorMatchCard(entry.value.id);
        }
      }).toList();

      stages.add(_buildStage("All Matches", matchCards));

      return stages;
    } catch (e) {
      debugPrint('Error building stages: $e');
      return [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Error loading matches: $e',
            style: TextStyle(color: Colors.red.shade700),
          ),
        ),
      ];
    }
  }

  Widget _buildMatchCard(int idx, MatchModel m) {
    final matchNo = _safeExtractMatchNumber(m.id, m.displayId, idx + 1);
    final scheduled = _safeFormatDateTime(m.scheduledAt);
    final matchStatus = _safeGetMatchStatus(m.status);
    final isCompleted = matchStatus == MatchStatus.completed;
    final isUpcoming = matchStatus == MatchStatus.upcoming;

    return MatchCard(
      matchNo: matchNo,
      teamA: _safeString(m.teamA, 'Team A'),
      teamB: _safeString(m.teamB, 'Team B'),
      result: isCompleted ? "Winner: ${_safeString(m.winner, 'TBD')}" : null,
      scheduled: scheduled,
      editable: isUpcoming,
      isRescheduling: _reschedulingMatchId == m.id,
      match: m,
      onEdit: _reschedulingMatchId == null && isUpcoming
          ? () => _handleEditMatch(idx, m)
          : null,
      onStart: isUpcoming ? () => _handleStartMatch(idx, m) : null,
      onViewDetails: () => _navigateToMatchDetails(m),
    );
  }

  Widget _buildErrorMatchCard(String matchId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Error loading match: ${_safeString(matchId, 'Unknown')}',
          style: TextStyle(color: Colors.red.shade700),
        ),
      ),
    );
  }

  Future<void> _handleEditMatch(int idx, MatchModel m) async {
    if (!mounted) return;

    try {
      final newDate = await _pickDate(context, m.scheduledAt);

      if (!mounted || newDate == null) return;

      // Validate index
      if (idx < 0 || idx >= _matches.length) {
        debugPrint('Invalid match index: $idx');
        return;
      }

      setState(() {
        _matches[idx] = m.copyWith(scheduledAt: newDate);
      });

      await _rescheduleMatch(m.id, newDate, idx);
    } catch (e) {
      debugPrint('Error handling edit match: $e');
      _showMessage('Failed to edit match', isError: true);
    }
  }

  Future<void> _handleStartMatch(int idx, MatchModel m) async {
    if (!mounted) return;

    try {
      final response = await ApiClient.instance.put(
        '/api/tournament-matches/start/${m.id}',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);

        if (data is! Map<String, dynamic>) {
          throw const FormatException('Invalid response format');
        }

        final matchId = data['match_id']?.toString();

        if (matchId == null || matchId.isEmpty) {
          _showMessage('Failed to get match ID from response', isError: true);
          return;
        }

        // Validate index before updating
        if (idx >= 0 && idx < _matches.length && mounted) {
          setState(() {
            _matches[idx] = m.copyWith(status: "live", parentMatchId: matchId);
          });
        }

        if (!mounted) return;

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveMatchViewScreen(matchId: matchId),
          ),
        );
      } else {
        final data = _safeJsonDecode(response.body);
        final errorMsg = data is Map<String, dynamic>
            ? (data['error']?.toString() ?? 'Failed to start match')
            : 'Failed to start match';

        _showMessage(errorMsg, isError: true);
      }
    } catch (e) {
      debugPrint('Error starting match: $e');
      if (mounted) {
        _showMessage('Error starting match: $e', isError: true);
      }
    }
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
        const SizedBox(height: 20),
      ],
    );
  }

  Future<void> _rescheduleMatch(
    String matchId,
    DateTime newDate,
    int matchIndex,
  ) async {
    if (matchIndex < 0 || matchIndex >= _matches.length) {
      debugPrint('Invalid match index for rescheduling: $matchIndex');
      return;
    }

    final oldDate = _matches[matchIndex].scheduledAt;

    setState(() {
      _reschedulingMatchId = matchId;
    });

    try {
      final response = await ApiClient.instance.put(
        '/api/tournament-matches/update/$matchId',
        body: {'match_date': newDate.toIso8601String()},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showMessage(
          "Match $matchId rescheduled to ${_safeFormatDateOnly(newDate)}",
        );
      } else {
        // Revert on failure
        if (matchIndex >= 0 && matchIndex < _matches.length) {
          setState(() {
            _matches[matchIndex] = _matches[matchIndex].copyWith(
              scheduledAt: oldDate,
            );
          });
        }
        _showMessage(
          "Failed to reschedule match: ${response.statusCode}",
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('Error rescheduling match: $e');

      if (mounted) {
        // Revert on exception
        if (matchIndex >= 0 && matchIndex < _matches.length) {
          setState(() {
            _matches[matchIndex] = _matches[matchIndex].copyWith(
              scheduledAt: oldDate,
            );
          });
        }
        _showMessage("Error rescheduling match: $e", isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _reschedulingMatchId = null;
        });
      }
    }
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime? initial) async {
    if (!mounted) return null;

    try {
      final date = await showDatePicker(
        context: context,
        initialDate: initial ?? DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );

      if (!mounted || date == null) return null;

      final time = await showTimePicker(
        context: context,
        initialTime: initial != null
            ? TimeOfDay.fromDateTime(initial)
            : const TimeOfDay(hour: 10, minute: 0),
      );

      if (!mounted || time == null) return null;

      return DateTime(date.year, date.month, date.day, time.hour, time.minute);
    } catch (e) {
      debugPrint('Error picking date: $e');
      return null;
    }
  }

  void _showBracketView(BuildContext context) {
    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_safeString(widget.tournament.name, 'Tournament')} - Tournament Bracket',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        if (Navigator.canPop(sheetContext)) {
                          Navigator.pop(sheetContext);
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TournamentBracketWidget(
                  matches: _matches,
                  onMatchTap: (match) => _navigateToMatchDetails(match),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error showing bracket view: $e');
      _showMessage('Failed to show bracket view', isError: true);
    }
  }

  Future<void> _navigateToMatchDetails(MatchModel match) async {
    if (!mounted) return;

    try {
      final matchStatus = _safeGetMatchStatus(match.status);
      final matchId = _safeString(match.parentMatchId ?? match.id, '');

      if (matchId.isEmpty) {
        _showErrorDialog('Invalid match ID');
        return;
      }

      if (matchStatus == MatchStatus.live) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveMatchViewScreen(matchId: matchId),
          ),
        );
      } else if (matchStatus == MatchStatus.completed) {
        if (match.parentMatchId != null) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScorecardScreen(matchId: matchId),
            ),
          );
        } else {
          _showScorecardNotAvailableDialog();
        }
      } else {
        _showUpcomingMatchDialog(match);
      }
    } catch (e) {
      debugPrint('Error navigating to match details: $e');
      _showErrorDialog('Failed to open match details');
    }
  }

  void _showUpcomingMatchDialog(MatchModel match) {
    if (!mounted) return;

    final scheduled = _safeFormatDateTime(match.scheduledAt);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          "Match ${_safeString(match.displayId ?? match.id, 'Details')}",
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${_safeString(match.teamA, 'Team A')} vs ${_safeString(match.teamB, 'Team B')}",
            ),
            const SizedBox(height: 8),
            Text("Status: ${_safeString(match.status, 'Unknown')}"),
            if (scheduled != null) ...[
              const SizedBox(height: 4),
              Text("Scheduled: $scheduled"),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.canPop(dialogContext)) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showScorecardNotAvailableDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Scorecard Not Available"),
        content: const Text(
          "The scorecard for this completed match is not yet available.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.canPop(dialogContext)) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.canPop(dialogContext)) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text("Close"),
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
  final MatchModel match;
  final VoidCallback? onEdit;
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
            Text(
              "Match ${matchNo > 0 ? matchNo : 'N/A'}",
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "$teamA vs $teamB",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            if (result != null)
              Text(
                result!,
                style: const TextStyle(color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

            if (scheduled != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Scheduled: $scheduled",
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (editable && onEdit != null && !isRescheduling)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.green),
                      onPressed: onEdit,
                    ),
                  if (isRescheduling)
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              )
            else if (editable && onEdit != null && !isRescheduling)
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
                    onPressed: onViewDetails,
                    child: const Text("View Details"),
                  ),
                ),
                if (editable && onStart != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                      ),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text(
                        "Start Match",
                        style: TextStyle(fontSize: 13),
                      ),
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
