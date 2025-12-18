import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Alias the Local Tournament Model
import '../models/tournament_model.dart' as local;

// Alias the Detailed Match Model used by Bracket & Scoring
import '../../matches/models/match_model.dart' as detailed_matches;

import '../../../widgets/tournament_bracket_widget.dart';
import '../widgets/tournament_stats_view.dart'; // [ADDED] Stats View

class TournamentDetailsViewerScreen extends StatelessWidget {
  final local.TournamentModel tournament;

  const TournamentDetailsViewerScreen({super.key, required this.tournament});

  String _safeString(String? value, String defaultValue) {
    if (value == null || value.isEmpty) return defaultValue;
    return value;
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'TBD';
    try {
      return DateFormat('yyyy-MM-dd HH:mm').format(dateTime.toLocal());
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return 'Invalid date';
    }
  }

  int _extractMatchNumber(String? id) {
    if (id == null || id.isEmpty) return 0;
    final numbersOnly = id.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(numbersOnly) ?? 0;
  }

  // Helper to check status safely
  bool _isCompleted(String? status) => status?.toLowerCase() == 'completed';

  @override
  Widget build(BuildContext context) {
    final tournamentName = _safeString(tournament.name, 'Tournament');

    return DefaultTabController(
      length: 4, // [CHANGED] 3 -> 4
      child: Scaffold(
        appBar: AppBar(
          title: Text(tournamentName),
          centerTitle: true,
          backgroundColor: Colors.green.shade600,
          bottom: const TabBar(
            isScrollable: true, // Allow scrolling for 4 tabs
            tabs: [
              Tab(text: 'Info'),
              Tab(text: 'Matches'),
              Tab(text: 'Bracket'),
              Tab(text: 'Stats'), // [ADDED]
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInfoTab(),
            _buildMatchesTab(),
            _buildBracketTab(),
            TournamentStatsView(tournamentId: tournament.id), // [ADDED]
          ],
        ),
      ),
    );
  }

  // ---------------- Tabs ----------------

  Widget _buildInfoTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          _infoRow('Name', _safeString(tournament.name, 'N/A')),
          _infoRow('Type', _safeString(tournament.type, 'N/A')),
          _infoRow('Location', _safeString(tournament.location, 'N/A')),
          _infoRow('Overs', tournament.overs.toString()),
          _infoRow('Teams', tournament.teams.length.toString()),
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildMatchesTab() {
    final matches = tournament.matches ?? [];
    if (matches.isEmpty) {
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

    // Filter valid matches
    final validMatches = matches.where((m) {
      return (m.teamA.isNotEmpty) && (m.teamB.isNotEmpty);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: validMatches.length,
      itemBuilder: (context, index) {
        final m = validMatches[index];
        final matchNo = _extractMatchNumber(m.id);

        final result = _isCompleted(m.status)
            ? "Winner: ${_safeString(m.winner, 'TBD')}"
            : null;
        final scheduled = _formatDateTime(m.scheduledAt);

        return _MatchCardViewer(
          matchNo: matchNo,
          teamA: _safeString(m.teamA, 'Team A'),
          teamB: _safeString(m.teamB, 'Team B'),
          result: result,
          scheduled: scheduled,
          match: m,
        );
      },
    );
  }

  Widget _buildBracketTab() {
    final matches = tournament.matches ?? [];
    if (matches.isEmpty) {
      return const Center(child: Text('No matches to display in bracket'));
    }

    // [FIX] Map local MatchModel to Detailed MatchModel
    final bracketMatches = matches.map((m) {
      // Safe access to properties that might be null in local model
      final dynamic dynMatch = m;
      String roundVal = 'round_1';
      try {
        roundVal = dynMatch.round ?? 'round_1';
      } catch (_) {}

      return detailed_matches.MatchModel(
        id: m.id,
        teamA: m.teamA,
        teamB: m.teamB,
        // Map status string to detailed Enum
        status: detailed_matches.MatchStatus.fromBackendValue(m.status),
        scheduledAt: m.scheduledAt,
        creatorId: '',
        tournamentId: int.tryParse(tournament.id) ?? 0,
        // Map 'round' (required by bracket)
        round: roundVal,
        runs: 0,
        wickets: 0,
        overs: 0.0,
      );
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: TournamentBracketWidget(
        matches: bracketMatches,
        onMatchTap: (match) {
          // Tap logic can be added here if needed
        },
      ),
    );
  }
}

// ---------------- Read-only MatchCard for viewer ----------------

class _MatchCardViewer extends StatelessWidget {
  final int matchNo;
  final String teamA;
  final String teamB;
  final String? result;
  final String? scheduled;
  final local.MatchModel match;

  const _MatchCardViewer({
    required this.matchNo,
    required this.teamA,
    required this.teamB,
    this.result,
    this.scheduled,
    required this.match,
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
              Text(
                "Scheduled: $scheduled",
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}
