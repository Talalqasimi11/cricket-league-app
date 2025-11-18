// lib/features/tournaments/screens/tournament_details_viewer_screen.dart
import 'package:flutter/material.dart';
import '../models/tournament_model.dart';
import '../../matches/screens/live_match_view_screen.dart';
import '../../matches/screens/scorecard_screen.dart';

class TournamentDetailsViewerScreen extends StatelessWidget {
  final TournamentModel tournament;

  const TournamentDetailsViewerScreen({super.key, required this.tournament});

  // Safe string extraction
  String _safeString(String? value, String defaultValue) {
    if (value == null || value.isEmpty) return defaultValue;
    return value;
  }

  // Safe date formatting
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

  // Safe match number extraction
  int _safeExtractMatchNumber(String? id, String? displayId) {
    try {
      // Try displayId first
      if (displayId != null && displayId.isNotEmpty) {
        final num = int.tryParse(displayId);
        if (num != null && num > 0) return num;
      }

      // Fallback to id
      if (id == null || id.isEmpty) return 0;

      final numbersOnly = id.replaceAll(RegExp(r'[^0-9]'), '');
      if (numbersOnly.isEmpty) return 0;

      return int.tryParse(numbersOnly) ?? 0;
    } catch (e) {
      debugPrint('Error extracting match number: $e');
      return 0;
    }
  }

  // Safe MatchStatus conversion
  MatchStatus _safeGetMatchStatus(String? status) {
    try {
      return MatchStatus.fromString(status ?? 'upcoming');
    } catch (e) {
      debugPrint('Error parsing match status: $e');
      return MatchStatus.upcoming;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournamentName = _safeString(tournament.name, 'Tournament');

    return Scaffold(
      appBar: AppBar(
        title: Text(tournamentName),
        centerTitle: true,
        backgroundColor: Colors.green.shade600,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    try {
      final matches = tournament.matches;

      if (matches == null || matches.isEmpty) {
        return _buildEmptyState();
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: _buildStages(matches),
      );
    } catch (e) {
      debugPrint('Error building tournament body: $e');
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
            const SizedBox(height: 8),
            const Text(
              "Matches will appear here once they're scheduled",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
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
              "Error loading tournament details",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStages(List<MatchModel> matches) {
    try {
      final List<Widget> stages = [];

      // Filter valid matches
      final validMatches = matches.where((m) {
        final hasTeams = (m.teamA.isNotEmpty && m.teamB.isNotEmpty);
        return hasTeams;
      }).toList();

      if (validMatches.isEmpty) {
        return [
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No valid matches found',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ];
      }

      final matchCards = validMatches.map((m) {
        try {
          return _buildMatchCard(m);
        } catch (e) {
          debugPrint('Error building match card: $e');
          return _buildErrorMatchCard(m.id);
        }
      }).toList();

      stages.add(_buildStage("All Matches", matchCards));

      return stages;
    } catch (e) {
      debugPrint('Error building stages: $e');
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Error loading matches',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ),
      ];
    }
  }

  Widget _buildMatchCard(MatchModel m) {
    final matchNo = _safeExtractMatchNumber(m.id, m.displayId);
    final matchStatus = _safeGetMatchStatus(m.status);

    final result = matchStatus == MatchStatus.completed
        ? "Winner: ${_safeString(m.winner, 'TBD')}"
        : null;

    final scheduled = _safeFormatDateTime(m.scheduledAt);

    return MatchCardViewer(
      matchNo: matchNo,
      teamA: _safeString(m.teamA, 'Team A'),
      teamB: _safeString(m.teamB, 'Team B'),
      result: result,
      scheduled: scheduled,
      match: m,
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
      ],
    );
  }
}

class MatchCardViewer extends StatefulWidget {
  final int matchNo;
  final String teamA;
  final String teamB;
  final String? result;
  final String? scheduled;
  final MatchModel match;

  const MatchCardViewer({
    super.key,
    required this.matchNo,
    required this.teamA,
    required this.teamB,
    this.result,
    this.scheduled,
    required this.match,
  });

  @override
  State<MatchCardViewer> createState() => _MatchCardViewerState();
}

class _MatchCardViewerState extends State<MatchCardViewer> {
  bool _isNavigating = false;

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

  MatchStatus _safeGetMatchStatus(String? status) {
    try {
      return MatchStatus.fromString(status ?? 'upcoming');
    } catch (e) {
      debugPrint('Error parsing match status: $e');
      return MatchStatus.upcoming;
    }
  }

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
              "Match ${widget.matchNo > 0 ? widget.matchNo : 'N/A'}",
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "${widget.teamA} vs ${widget.teamB}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (widget.result != null)
              Text(
                widget.result!,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (widget.scheduled != null)
              Text(
                "Scheduled: ${widget.scheduled}",
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isNavigating
                    ? null
                    : () => _navigateToMatchDetails(context),
                child: _isNavigating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("View Match Details"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToMatchDetails(BuildContext context) async {
    if (_isNavigating || !mounted) return;

    setState(() => _isNavigating = true);

    try {
      final matchStatus = _safeGetMatchStatus(widget.match.status);
      final matchId = _safeString(
        widget.match.parentMatchId ?? widget.match.id,
        '',
      );

      if (matchId.isEmpty) {
        _showErrorDialog(context, 'Invalid match ID');
        return;
      }

      if (matchStatus == MatchStatus.live) {
        await _navigateToLiveMatch(context, matchId);
      } else if (matchStatus == MatchStatus.completed) {
        await _navigateToScorecard(context, matchId);
      } else {
        await _showUpcomingMatchDialog(context);
      }
    } catch (e) {
      debugPrint('Error navigating to match details: $e');
      if (mounted) {
        _showErrorDialog(context, 'Error opening match: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    }
  }

  Future<void> _navigateToLiveMatch(
    BuildContext context,
    String matchId,
  ) async {
    if (!mounted) return;

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveMatchViewScreen(matchId: matchId),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to live match: $e');
      if (mounted) {
        _showErrorDialog(context, 'Failed to open live match');
      }
    }
  }

  Future<void> _navigateToScorecard(
    BuildContext context,
    String matchId,
  ) async {
    if (!mounted) return;

    if (widget.match.parentMatchId != null) {
      try {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ScorecardScreen(matchId: matchId)),
        );
      } catch (e) {
        debugPrint('Error navigating to scorecard: $e');
        if (mounted) {
          _showErrorDialog(context, 'Failed to open scorecard');
        }
      }
    } else {
      await _showScorecardNotAvailableDialog(context);
    }
  }

  Future<void> _showUpcomingMatchDialog(BuildContext context) async {
    if (!mounted) return;

    final scheduled = _safeFormatDateTime(widget.match.scheduledAt);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Match ${widget.matchNo > 0 ? widget.matchNo : 'Details'}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${widget.teamA} vs ${widget.teamB}"),
            const SizedBox(height: 8),
            Text("Status: ${_safeString(widget.match.status, 'Unknown')}"),
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

  Future<void> _showScorecardNotAvailableDialog(BuildContext context) async {
    if (!mounted) return;

    await showDialog(
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

  void _showErrorDialog(BuildContext context, String message) {
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
