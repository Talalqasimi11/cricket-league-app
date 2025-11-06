// lib/features/matches/screens/matches_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/api_client.dart';
import '../../../core/error_dialog.dart';
import '../../../core/icons.dart';
import '../../../core/theme/theme_config.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/shared/modern_card.dart';
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
      if (resp.statusCode == 200) {
        final rows = List<Map<String, dynamic>>.from(jsonDecode(resp.body));
        setState(() => _matches = rows);
      } else {
        if (mounted) {
          await ErrorDialog.showApiError(
            context,
            response: resp,
            onRetry: _fetchMatches,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        await ErrorDialog.showGenericError(
          context,
          error: e,
          onRetry: _fetchMatches,
          showRetryButton: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          "Matches",
          style: AppTypographyExtended.headlineSmall.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _fetchMatches,
            icon: AppIcons.refreshIcon(color: theme.colorScheme.onSurface),
          ),
        ],
      ),
      body: RefreshIndicator(
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
                    label: Text(
                      f,
                      style: AppTypographyExtended.bodyMedium.copyWith(
                        color: _filter == f
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    selected: _filter == f,
                    selectedColor: theme.colorScheme.primary,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Matches list
            if (_loading)
              ...List.generate(3, (index) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: const SkeletonCard(),
              ))
            else
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

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: MatchCard(
                          teamA: teamA,
                          teamB: teamB,
                          dateTime: dateStr,
                          status: status,
                          subtitle: tName.isEmpty ? null : tName,
                          actionButton: Builder(
                            builder: (context) {
                              // Navigation buttons based on status and parent match id
                              final parentId = m['parent_match_id'] as int?;
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
                                    foregroundColor: theme.colorScheme.primary,
                                  ),
                                  icon: const Icon(Icons.live_tv, size: 16),
                                  label: const Text('View Live'),
                                );
                              } else if (parentId != null && status == 'finished') {
                                return TextButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/matches/scorecard',
                                      arguments: {'matchId': parentId.toString()},
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: theme.colorScheme.primary,
                                  ),
                                  icon: const Icon(Icons.scoreboard, size: 16),
                                  label: const Text('Scorecard'),
                                );
                              }
                              return TextButton.icon(
                                onPressed: null,
                                style: TextButton.styleFrom(
                                  foregroundColor: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                                icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                                label: const Text('Not available'),
                              );
                            },
                          ),
                        ),
                      );
                    }),
          ],
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60), // above navbar
        child: PrimaryButton(
          text: "Create Match",
          onPressed: () {
            // ✅ Navigate to Create Match Screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateMatchScreen()),
            );
          },
          fullWidth: true,
          size: ButtonSize.large,
          icon: Icons.add,
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
}
