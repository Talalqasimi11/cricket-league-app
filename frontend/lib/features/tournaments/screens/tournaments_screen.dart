// lib/features/tournaments/screens/tournaments_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../../core/api_client.dart';
import '../../../core/json_utils.dart';
import 'tournament_create_screen.dart';
import 'tournament_draws_screen.dart' as draws; // ✅ alias to avoid conflicts
import '../widgets/tournament_card.dart';
import '../widgets/tournament_filter_tabs.dart';
import '../models/tournament_model.dart';
import '../providers/tournament_provider.dart';
import 'tournament_details_viewer_screen.dart';
import '../../../widgets/shared/modern_card.dart';
import '../../../core/auth_provider.dart';

class TournamentsScreen extends StatefulWidget {
  final bool isCaptain; // pass true for captain, false for viewer

  const TournamentsScreen({super.key, this.isCaptain = false});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  int selectedTab = 0;
  int? _userId; // decoded from JWT for "My Tournaments" filter

  @override
  void initState() {
    super.initState();
    _loadUserId();
    // Fetch tournaments using provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TournamentProvider>(context, listen: false).fetchTournaments();
    });
  }

  Future<void> _loadUserId() async {
    try {
      // Use AuthProvider to get user ID safely
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userIdString = authProvider.userId;
      final userId = int.tryParse(userIdString ?? '');
      setState(() {
        _userId = userId;
      });
      // Set user ID in provider for filtering
      if (mounted) {
        Provider.of<TournamentProvider>(context, listen: false).setCurrentUserId(userId);
      }
    } catch (e) {
      debugPrint('Error loading user ID: $e');
    }
  }

  Future<void> _openTournament(String tournamentId) async {
    try {
      final matchesResp = await ApiClient.instance.get(
        '/api/tournament-matches/$tournamentId',
      );
      List<MatchModel> matches = [];
      if (matchesResp.statusCode == 200) {
        final List<dynamic> rows = List<dynamic>.from(
          jsonDecode(matchesResp.body),
        );
        matches = rows.map((r) {
          final m = r as Map<String, dynamic>;
          final dt = asDateTime(m['match_date']);
          final backendStatus = asType<String>(m['status'], 'upcoming');
          // Normalize status using enum
          final normalizedStatus = MatchStatus.fromString(backendStatus).toString();
          return MatchModel(
            id: asType<String>(m['id'], ''),
            teamA: asType<String>(m['team1_name'], 'TBD'),
            teamB: asType<String>(m['team2_name'], 'TBD'),
            scheduledAt: dt,
            status: normalizedStatus,
            parentMatchId: m['parent_match_id']?.toString(),
          );
        }).toList();
      }

      // Get tournament data from provider
      final tournamentProvider = Provider.of<TournamentProvider>(context, listen: false);
      final tournamentData = tournamentProvider.tournaments.firstWhere(
        (t) => t.id == tournamentId,
        orElse: () => Tournament(
          id: tournamentId,
          name: 'Tournament',
          description: '',
          startDate: DateTime.now(),
          endDate: DateTime.now(),
          status: 'upcoming',
          teamCount: 0,
          matchCount: 0,
        ),
      );

      final model = TournamentModel(
        id: tournamentData.id,
        name: tournamentData.name,
        status: tournamentData.status,
        type: 'Knockout',
        dateRange: tournamentData.startDate.toString().split(' ')[0],
        location: 'Unknown', // Provider doesn't have location
        overs: 20, // Default
        teams: const [],
        matches: matches,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TournamentDetailsViewerScreen(tournament: model),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tournament details: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TournamentProvider>(
      builder: (context, tournamentProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Tournaments"),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // 🔹 Filter tabs (All / My Tournaments / Past)
                TournamentFilterTabs(
                  selectedIndex: selectedTab,
                  onChanged: (index) {
                    setState(() => selectedTab = index);
                    // Update provider filter
                    String filter = 'all';
                    if (index == 1) filter = 'mine'; // My tournaments
                    if (index == 2) filter = 'completed'; // Past tournaments
                    tournamentProvider.setFilter(filter);
                  },
                ),
                const SizedBox(height: 16),

                // 🔹 Tournament list
                Expanded(
                  child: tournamentProvider.isLoading
                      ? ListView.builder(
                          itemCount: 3, // Show 3 skeleton cards
                          itemBuilder: (context, index) => const SkeletonCard(),
                        )
                      : Builder(
                          builder: (context) {
                            List<Tournament> data = tournamentProvider.filteredTournaments;

                            // Additional filtering for "My Tournaments"
                            if (selectedTab == 1 && _userId != null && _userId! > 0) {
                              // This would require additional logic to filter by creator
                              // For now, just use the provider's filtered data
                            }

                            if (data.isEmpty) {
                              return _buildEmptyState();
                            }

                            return RefreshIndicator(
                              onRefresh: tournamentProvider.fetchTournaments,
                              child: ListView.builder(
                                itemCount: data.length,
                                itemBuilder: (context, index) {
                                  final t = data[index];
                                  final model = TournamentModel(
                                    id: t.id,
                                    name: t.name,
                                    status: t.status,
                                    type: 'Knockout',
                                    dateRange: '${t.startDate.toString().split(' ')[0]} - ${t.endDate.toString().split(' ')[0]}',
                                    location: 'Unknown',
                                    overs: 20,
                                    teams: const [],
                                  );
                                  return GestureDetector(
                                    onTap: () => _openTournament(t.id),
                                    child: TournamentCard(tournament: model),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),

                // 🔹 Captain-only action (Create Tournament → Draws screen)
                if (widget.isCaptain) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Navigate to Create Tournament
                      final createdTournament = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateTournamentScreen(),
                        ),
                      );

                      if (createdTournament != null) {
                        // Refresh tournaments list
                        tournamentProvider.fetchTournaments();
                        // Navigate to Draws screen for the creator
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => draws.TournamentDrawsScreen(
                              tournamentName: createdTournament.name,
                              tournamentId: createdTournament.id,
                              teams: createdTournament.teams,
                              isCreator: true,
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Create Tournament"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final tabTitles = ['tournaments', 'tournaments you\'ve created', 'completed tournaments'];
    final tabTitle = tabTitles[selectedTab];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selectedTab == 2 ? Icons.emoji_events : Icons.sports_cricket,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No $tabTitle found',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedTab == 0
                ? 'Tournaments will appear here once they\'re created.'
                : selectedTab == 1
                    ? 'Create your first tournament to get started!'
                    : 'Completed tournaments will appear here.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          if (widget.isCaptain && selectedTab == 1) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final tournamentProvider = Provider.of<TournamentProvider>(context, listen: false);
                // Navigate to Create Tournament
                final createdTournament = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateTournamentScreen(),
                  ),
                );

                if (createdTournament != null) {
                  // Refresh tournaments list
                  tournamentProvider.fetchTournaments();
                  // Navigate to Draws screen for the creator
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => draws.TournamentDrawsScreen(
                        tournamentName: createdTournament.name,
                        tournamentId: createdTournament.id,
                        teams: createdTournament.teams,
                        isCreator: true,
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text("Create Your First Tournament"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
