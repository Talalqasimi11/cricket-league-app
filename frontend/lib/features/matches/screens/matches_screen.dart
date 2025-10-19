// lib/features/matches/screens/matches_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/api_client.dart';
import 'create_match_screen.dart';
import 'live_match_view_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  bool _loading = false;
  List<Map<String, dynamic>> _matches = [];
  String _filter = 'All'; // All | Live | Finished | Upcoming

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    setState(() => _loading = true);
    try {
      final resp = await ApiClient.instance.get('/api/tournament-matches');
      if (resp.statusCode != 200) {
        throw Exception('Failed matches ${resp.statusCode}');
      }
      final rows = List<Map<String, dynamic>>.from(jsonDecode(resp.body));
      setState(() => _matches = rows);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading matches: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2D2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2D2A),
        elevation: 0,
        title: const Text(
          "Matches",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _fetchMatches,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchMatches,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Filter chips
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final f in const [
                        'All',
                        'Live',
                        'Finished',
                        'Upcoming',
                      ])
                        ChoiceChip(
                          label: Text(f),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Matches list
                  ..._filteredMatches().map((m) {
                    final teamA = (m['team1_name'] ?? 'TBD').toString();
                    final teamB = (m['team2_name'] ?? 'TBD').toString();
                    final status = (m['status'] ?? 'upcoming').toString();
                    final tName = (m['tournament_name'] ?? '').toString();
                    final dateRaw = m['match_date'];
                    final dateStr =
                        dateRaw == null || dateRaw.toString().isEmpty
                        ? 'Not scheduled'
                        : m['match_date'].toString();
                    Color statusColor;
                    switch (status) {
                      case 'live':
                        statusColor = Colors.red;
                        break;
                      case 'finished':
                        statusColor = Colors.green;
                        break;
                      default:
                        statusColor = Colors.grey;
                    }
                    return _buildMatchCard(
                      context,
                      matchId: m['id'].toString(),
                      teamA: teamA,
                      teamB: teamB,
                      dateTime: dateStr,
                      status: status,
                      statusColor: statusColor,
                      subtitle: tName.isEmpty ? null : tName,
                      parentMatchId: m['parent_match_id'] as int?,
                    );
                  }),
                ],
              ),
            ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60), // above navbar
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF36e27b),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            // ✅ Navigate to Create Match Screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateMatchScreen()),
            );
          },
          child: const Text(
            "Create Match",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filteredMatches() {
    if (_filter == 'All') return _matches;
    final key = _filter.toLowerCase();
    return _matches
        .where((m) => (m['status'] ?? '').toString().toLowerCase() == key)
        .toList();
  }

  Widget _buildMatchCard(
    BuildContext context, {
    required String matchId,
    required String teamA,
    required String teamB,
    required String dateTime,
    required String status,
    required Color statusColor,
    String? subtitle,
    int? parentMatchId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C4A44),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFF1A2D2A),
                    child: Icon(Icons.sports_cricket, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$teamA vs $teamB",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFF95c6a9),
                            fontSize: 12,
                          ),
                        ),
                      Text(
                        dateTime,
                        style: const TextStyle(
                          color: Color(0xFF95c6a9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Builder(
                builder: (context) {
                  // Navigation buttons based on status and parent match id
                  final parentId = parentMatchId;
                  if (parentId != null && status == 'live') {
                    return TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LiveMatchViewScreen(
                              matchId: parentId.toString(),
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF36e27b),
                      ),
                      icon: const Icon(Icons.live_tv),
                      label: const Text('View Live'),
                    );
                  } else if (parentId != null && status == 'completed') {
                    return TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/matches/scorecard',
                          arguments: {'matchId': parentId.toString()},
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF36e27b),
                      ),
                      icon: const Icon(Icons.scoreboard),
                      label: const Text('Scorecard'),
                    );
                  }
                  return TextButton.icon(
                    onPressed: null,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF36e27b),
                    ),
                    icon: const Icon(Icons.remove_red_eye_outlined),
                    label: const Text('Not available'),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
