
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tournament_stats_provider.dart';

class TournamentStatsView extends StatefulWidget {
  final String tournamentId;

  const TournamentStatsView({super.key, required this.tournamentId});

  @override
  State<TournamentStatsView> createState() => _TournamentStatsViewState();
}

class _TournamentStatsViewState extends State<TournamentStatsView> {
  @override
  void initState() {
    super.initState();
    // Fetch stats when this tab is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentStatsProvider>().fetchTournamentStats(widget.tournamentId);
    });
  }

  Future<void> _refresh() async {
    await context.read<TournamentStatsProvider>().fetchTournamentStats(widget.tournamentId, forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<TournamentStatsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && !provider.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && !provider.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(provider.error!),
                TextButton(onPressed: _refresh, child: const Text('Retry')),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCards(provider.summary),
              const SizedBox(height: 24),
              _buildLeaderboardSection(
                context,
                title: "Most Runs (Orange Cap)",
                icon: Icons.sports_cricket,
                color: Colors.orange,
                data: provider.topScorers,
                valueKey: 'total_runs',
                subValueKey: 'innings_played',
                subValueLabel: 'inns',
              ),
              const SizedBox(height: 24),
              _buildLeaderboardSection(
                context,
                title: "Most Wickets (Purple Cap)",
                icon: Icons.sports_baseball,
                color: Colors.purple,
                data: provider.topBowlers,
                valueKey: 'total_wickets',
                subValueKey: 'economy',
                subValueLabel: 'econ',
                isDouble: true, // Economy is a double
              ),
              const SizedBox(height: 24),
              _buildLeaderboardSection(
                context,
                title: "Sixes King",
                icon: Icons.whatshot,
                color: Colors.red,
                data: provider.sixesLeaderboard,
                valueKey: 'total_sixes',
                subValueKey: null,
                subValueLabel: '',
              ),
              const SizedBox(height: 40), // Bottom padding
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> summary) {
    if (summary.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        _buildStatCard(
          'Matches',
          '${summary['completed_matches'] ?? 0}/${summary['total_matches'] ?? 0}',
          Icons.event_available,
          Colors.blue,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Runs',
          '${summary['total_runs'] ?? 0}',
          Icons.trending_up,
          Colors.green,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Sixes',
          '${summary['total_sixes'] ?? 0}',
          Icons.flash_on,
          Colors.amber.shade700,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Map<String, dynamic>> data,
    required String valueKey,
    String? subValueKey,
    String? subValueLabel,
    bool isDouble = false,
  }) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: List.generate(data.length, (index) {
              final player = data[index];
              final rank = index + 1;
              final name = player['player_name'] ?? 'Unknown';
              final team = player['team_name'] ?? '-';
              final value = player[valueKey] ?? 0;
              
              String subText = team;
              if (subValueKey != null) {
                final subVal = player[subValueKey];
                final formattedSub = isDouble && subVal != null 
                    ? (subVal is String ? double.tryParse(subVal)?.toStringAsFixed(1) ?? subVal : subVal.toStringAsFixed(1))
                    : subVal.toString();
                subText += ' • $formattedSub $subValueLabel';
              }

              return ListTile(
                leading: _buildRankBadge(rank, color),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(subText, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildRankBadge(int rank, Color color) {
    Color badgeColor;
    Color textColor = Colors.white;
    
    if (rank == 1) {
      badgeColor = const Color(0xFFFFD700); // Gold
    } else if (rank == 2) {
      badgeColor = const Color(0xFFC0C0C0); // Silver
    } else if (rank == 3) {
      badgeColor = const Color(0xFFCD7F32); // Bronze
    } else {
      badgeColor = Colors.grey.shade200;
      textColor = Colors.grey.shade700;
    }

    return CircleAvatar(
      radius: 14,
      backgroundColor: badgeColor,
      child: Text(
        rank.toString(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}