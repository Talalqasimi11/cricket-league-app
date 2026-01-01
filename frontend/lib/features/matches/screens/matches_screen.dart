// lib/features/matches/screens/matches_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/icons.dart';
import '../../../core/theme/theme_config.dart';
import '../../../widgets/custom_button.dart';
import '../models/match_model.dart';
import '../providers/match_provider.dart';
import '../../../core/auth_provider.dart'; // [Fixed Path]
import 'create_match_screen.dart';
import 'live_match_view_screen.dart';
import 'live_match_scoring_screen.dart'; // [Added]

enum MatchFilter {
  all('All'),
  my('My Matches'),
  live('Live'),
  completed('Finished'),
  scheduled('Upcoming');

  const MatchFilter(this.label);
  final String label;

  String get statusKey {
    switch (this) {
      case MatchFilter.all:
        return '';
      case MatchFilter.my:
        return 'my';
      case MatchFilter.live:
        return 'live';
      case MatchFilter.completed:
        return 'completed';
      case MatchFilter.scheduled:
        return 'scheduled';
    }
  }
}

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with AutomaticKeepAliveClientMixin {
  MatchFilter _selectedFilter = MatchFilter.all;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchMatches());
  }

  Future<void> _safeCall(Future<void> Function() action) async {
    try {
      if (!mounted) return;
      await action();
    } catch (e) {
      debugPrint('SafeCall error: $e');
    }
  }

  Future<void> _fetchMatches() async {
    if (!mounted) return;

    final provider = context.read<MatchProvider>();
    debugPrint('MatchesScreen: _fetchMatches called. Filter: $_selectedFilter');
    return _safeCall(() async {
      final status = _selectedFilter.statusKey;
      if (status == 'my') {
        await provider.fetchMyMatches();
      } else {
        await provider.fetchMatches(status: status.isEmpty ? null : status);
      }
    });
  }

  void _onFilterChanged(MatchFilter filter) {
    if (_selectedFilter == filter) return;

    setState(() {
      _selectedFilter = filter;
    });

    _fetchMatches();
  }

  Future<void> _handleRetry() async {
    if (!mounted) return;

    final provider = context.read<MatchProvider>();
    provider.clearError();
    await _fetchMatches();
  }

  void _navigateToCreateMatch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateMatchScreen()),
    ).then((created) {
      if (created == true && mounted) _fetchMatches();
    });
  }

  void _navigateToLiveMatch(String matchId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LiveMatchViewScreen(matchId: matchId)),
    ).then((_) {
      if (mounted) _fetchMatches();
    });
  }

  void _navigateToLiveScoring(MatchModel match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveMatchScoringScreen(
          matchId: match.id,
          teamA: match.teamA,
          teamB: match.teamB,
        ),
      ),
    ).then((_) {
      if (mounted) _fetchMatches();
    });
  }

  void _navigateToScorecard(String matchId) {
    Navigator.pushNamed(
      context,
      '/matches/scorecard',
      arguments: {'matchId': matchId},
    ).then((_) {
      if (mounted) _fetchMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(theme),
      body: _buildBody(theme),
      floatingActionButton: _buildFloatingActionButton(theme),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      title: Text(
        'Matches',
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      actions: [
        Consumer<MatchProvider>(
          builder: (context, provider, _) {
            final loading = provider.isLoading;

            return IconButton(
              onPressed: loading ? null : _fetchMatches,
              icon: loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onSurface,
                        ),
                      ),
                    )
                  : AppIcons.refreshIcon(color: theme.colorScheme.onSurface),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(ThemeData theme) {
    return Consumer<MatchProvider>(
      builder: (context, provider, _) {
        if (provider.hasError && !provider.isLoading) {
          return _buildErrorState(theme, provider.error);
        }

        return RefreshIndicator(
          onRefresh: _fetchMatches,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildFilterChips(theme)),
              if (provider.isLoading && !provider.hasMatches)
                _buildLoadingState()
              else if (!provider.hasMatches)
                _buildEmptyState(theme)
              else
                _buildMatchesList(theme, provider),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: MatchFilter.values.map((filter) {
            final selected = _selectedFilter == filter;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  filter.label,
                  style: TextStyle(
                    color: selected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
                selected: selected,
                selectedColor: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                onSelected: (_) => _onFilterChanged(filter),
                elevation: selected ? 2 : 0,
                pressElevation: 4,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSkeletonCard(),
          ),
          childCount: 5,
        ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _shimmerBox(height: 20),
            const SizedBox(height: 12),
            _shimmerBox(height: 16, width: 150),
            const SizedBox(height: 8),
            _shimmerBox(height: 16, width: 200),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox({required double height, double? width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final text = 'No ${_selectedFilter.label.toLowerCase()} matches';

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcons.cricketIcon(
              size: 80,
              color: theme.colorScheme.onSurface.withAlpha(80),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later or try a different filter',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withAlpha(110),
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Refresh',
              onPressed: _fetchMatches,
              variant: ButtonVariant.outline,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcons.errorIcon(size: 80, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load matches',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.error,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withAlpha(140),
                ),
              ),
            ],
            const SizedBox(height: 24),
            CustomButton(
              text: 'Retry',
              onPressed: _handleRetry,
              variant: ButtonVariant.primary,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesList(ThemeData theme, MatchProvider provider) {
    final matches = _getFilteredMatches(provider);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final match = matches[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMatchCard(theme, match),
          );
        }, childCount: matches.length),
      ),
    );
  }

  List<MatchModel> _getFilteredMatches(MatchProvider provider) {
    switch (_selectedFilter) {
      case MatchFilter.all:
        return provider.matches;
      case MatchFilter.my:
        return provider
            .matches; // Provider already stores filtered matches if status was 'my'
      case MatchFilter.live:
        return provider.getLiveMatches();
      case MatchFilter.completed:
        return provider.getCompletedMatches();
      case MatchFilter.scheduled:
        return provider.getUpcomingMatches();
    }
  }

  Widget _buildMatchCard(ThemeData theme, MatchModel match) {
    final status = match.status;
    final isLive = status == MatchStatus.live;
    final isCompleted = status == MatchStatus.completed;
    final isScheduled = status == MatchStatus.planned;
    final matchId = match.id.toString();

    final currentUser = context.read<AuthProvider>().userId;
    final isCreator = currentUser != null && match.creatorId == currentUser;

    final canResume =
        isLive &&
        (isCreator || context.read<AuthProvider>().hasScope('match:modify'));
    final canStart =
        isScheduled &&
        (isCreator || context.read<AuthProvider>().hasScope('match:modify'));

    return Card(
      elevation: AppElevation.level1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: InkWell(
        onTap: () {
          if (canResume || canStart) {
            _navigateToLiveScoring(match);
          } else if (isLive) {
            _navigateToLiveMatch(matchId);
          } else if (isCompleted) {
            _navigateToScorecard(matchId);
          }
        },
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatusBadge(theme, status),
                  const Spacer(),
                  Text(
                    _formatMatchDate(match.scheduledAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withAlpha(140),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // [Fixed] Use correct property names teamA/teamB
              _buildTeamRow(theme, match.teamA),
              const SizedBox(height: 8),
              _buildTeamRow(theme, match.teamB),
              const SizedBox(height: 12),
              CustomButton(
                text: canResume
                    ? 'Resume Scoring'
                    : canStart
                    ? 'Start Scoring'
                    : isLive
                    ? 'View Live'
                    : isCompleted
                    ? 'View Scorecard'
                    : 'Scheduled',
                onPressed: (canResume || canStart)
                    ? () => _navigateToLiveScoring(match)
                    : isLive
                    ? () => _navigateToLiveMatch(matchId)
                    : isCompleted
                    ? () => _navigateToScorecard(matchId)
                    : null,
                variant: (canResume || canStart)
                    ? ButtonVariant.primary
                    : ButtonVariant.outline,
                icon: (canResume || canStart)
                    ? Icons.edit
                    : isLive
                    ? Icons.live_tv
                    : isCompleted
                    ? Icons.scoreboard
                    : Icons.schedule,
                fullWidth: true,
              ),
              if (isCreator ||
                  context.read<AuthProvider>().hasScope('match:modify')) ...[
                const SizedBox(height: 8),
                CustomButton(
                  text: 'Delete Match',
                  onPressed: () => _confirmDelete(match),
                  variant: ButtonVariant.danger,
                  icon: Icons.delete_outline,
                  fullWidth: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(MatchModel match) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Match'),
        content: const Text(
          'Are you sure you want to delete this match? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<MatchProvider>().deleteMatch(
                match.id,
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Match deleted successfully')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, MatchStatus status) {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (status) {
      case MatchStatus.live:
        badgeColor = AppColors.errorRed;
        badgeText = 'LIVE';
        badgeIcon = Icons.circle;
        break;
      case MatchStatus.completed:
        badgeColor = AppColors.secondaryGreen;
        badgeText = 'FINISHED';
        badgeIcon = Icons.check_circle;
        break;
      default:
        badgeColor = AppColors.primaryBlue;
        badgeText = 'UPCOMING';
        badgeIcon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            size: status == MatchStatus.live ? 8 : 12,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRow(ThemeData theme, String teamName) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              teamName.isNotEmpty ? teamName[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            teamName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  String _formatMatchDate(DateTime? date) {
    if (date == null) return 'Date TBD';

    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.inDays == 0 && date.day == now.day) {
      return 'Today, ${_formatTime(date)}';
    }
    if (diff.inDays == 1 || (diff.inDays == 0 && date.day == now.day + 1)) {
      return 'Tomorrow, ${_formatTime(date)}';
    }
    if (diff.inDays == -1 || (diff.inDays == 0 && date.day == now.day - 1)) {
      return 'Yesterday, ${_formatTime(date)}';
    }

    if (diff.inDays > 0 && diff.inDays < 7) {
      return '${_getDayName(date)}, ${_formatTime(date)}';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _getDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  Widget _buildFloatingActionButton(ThemeData theme) {
    return Consumer<MatchProvider>(
      builder: (context, provider, _) {
        final loading = provider.isLoading;

        return FloatingActionButton.extended(
          onPressed: loading ? null : _navigateToCreateMatch,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          icon: const Icon(Icons.add),
          label: const Text('Create Match'),
        );
      },
    );
  }
}
