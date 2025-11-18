// lib/features/tournaments/screens/tournaments_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../../core/api_client.dart';
import '../../../core/json_utils.dart';
import 'tournament_create_screen.dart';
import '../widgets/tournament_card.dart';
import '../widgets/tournament_filter_tabs.dart';
import '../models/tournament_model.dart';
import '../providers/tournament_provider.dart';
import 'tournament_details_viewer_screen.dart';
import '../../../widgets/shared/modern_card.dart';
import '../../../core/auth_provider.dart';

class TournamentsScreen extends StatefulWidget {
  final bool isCaptain;

  const TournamentsScreen({super.key, this.isCaptain = false});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  int selectedTab = 0;
  bool _isLoadingTournament = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _safelyFetchTournaments();
    });
  }

  // Safe tournament fetch with error handling
  Future<void> _safelyFetchTournaments() async {
    try {
      if (!mounted) return;
      await Provider.of<TournamentProvider>(context, listen: false).fetchTournaments();
    } catch (e) {
      debugPrint('Error fetching tournaments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load tournaments: ${_getErrorMessage(e)}'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _safelyFetchTournaments,
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadUserId() async {
    try {
      if (!mounted) return;
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userIdString = authProvider.userId;
      
      if (userIdString == null || userIdString.isEmpty) {
        debugPrint('No user ID available');
        return;
      }

      final userId = int.tryParse(userIdString);
      
      if (userId == null) {
        debugPrint('Invalid user ID format: $userIdString');
        return;
      }

      if (mounted) {
        Provider.of<TournamentProvider>(context, listen: false)
            .setCurrentUserId(userId);
      }
    } catch (e) {
      debugPrint('Error loading user ID: $e');
    }
  }

  // Safe date formatter
  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    try {
      return date.toString().split(' ')[0];
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return 'Unknown';
    }
  }

  // Safe date range formatter
  String _formatDateRange(DateTime? startDate, DateTime? endDate) {
    try {
      final start = _formatDate(startDate);
      final end = _formatDate(endDate);
      return '$start - $end';
    } catch (e) {
      debugPrint('Error formatting date range: $e');
      return 'Unknown';
    }
  }

  // Extract error message safely
  String _getErrorMessage(dynamic error) {
    if (error == null) return 'Unknown error';
    return error.toString().replaceAll('Exception:', '').trim();
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

  Future<void> _openTournament(String tournamentId) async {
    if (_isLoadingTournament) return;

    setState(() => _isLoadingTournament = true);

    try {
      // Validate tournament ID
      if (tournamentId.isEmpty) {
        throw Exception('Invalid tournament ID');
      }

      // Fetch matches with error handling
      final matchesResp = await ApiClient.instance.get(
        '/api/tournament-matches/$tournamentId',
      );

      List<MatchModel> matches = [];

      if (matchesResp.statusCode == 200) {
        try {
          final dynamic decodedBody = _safeJsonDecode(matchesResp.body);
          
          if (decodedBody == null) {
            throw const FormatException('Null response body');
          }

          if (decodedBody is! List) {
            debugPrint('Expected List but got: ${decodedBody.runtimeType}');
            throw FormatException('Invalid response format: expected List');
          }

          final List<dynamic> rows = List<dynamic>.from(decodedBody);

          matches = rows.map((r) {
            try {
              if (r is! Map<String, dynamic>) {
                debugPrint('Invalid match data: ${r.runtimeType}');
                return null;
              }

              final m = r as Map<String, dynamic>;
              
              // Safe field extraction
              final matchId = asType<String>(m['id'], '');
              final team1Name = asType<String>(m['team1_name'], 'TBD');
              final team2Name = asType<String>(m['team2_name'], 'TBD');
              final matchDate = asDateTime(m['match_date']);
              final backendStatus = asType<String>(m['status'], 'upcoming');
              final parentMatchId = m['parent_match_id']?.toString();

              // Normalize status
              final normalizedStatus = MatchStatus.fromString(backendStatus).toString();

              return MatchModel(
                id: matchId,
                teamA: team1Name,
                teamB: team2Name,
                scheduledAt: matchDate,
                status: normalizedStatus,
                parentMatchId: parentMatchId,
              );
            } catch (e) {
              debugPrint('Error parsing match: $e');
              return null;
            }
          }).whereType<MatchModel>().toList(); // Filter out nulls
        } catch (e) {
          debugPrint('Error processing matches: $e');
          // Continue with empty matches list
        }
      } else {
        debugPrint('Failed to fetch matches: ${matchesResp.statusCode}');
        debugPrint('Response: ${matchesResp.body}');
      }

      if (!mounted) return;

      // Get tournament data from provider safely
      final tournamentProvider = Provider.of<TournamentProvider>(
        context,
        listen: false,
      );

      Tournament? tournamentData;
      try {
        tournamentData = tournamentProvider.tournaments.firstWhere(
          (t) => t.id == tournamentId,
        );
      } catch (e) {
        debugPrint('Tournament not found in provider: $e');
        // Create fallback tournament
        tournamentData = Tournament(
          id: tournamentId,
          name: 'Tournament',
          description: '',
          startDate: DateTime.now(),
          endDate: DateTime.now(),
          status: 'upcoming',
          teamCount: 0,
          matchCount: 0,
        );
      }

      // Create tournament model with safe data
      final model = TournamentModel(
        id: tournamentData.id,
        name: tournamentData.name.isNotEmpty ? tournamentData.name : 'Tournament',
        status: tournamentData.status.isNotEmpty ? tournamentData.status : 'upcoming',
        type: 'Knockout',
        dateRange: _formatDateRange(tournamentData.startDate, tournamentData.endDate),
        location: 'Unknown',
        overs: 20,
        teams: const [],
        matches: matches,
      );

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TournamentDetailsViewerScreen(tournament: model),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error loading tournament details: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${_getErrorMessage(e)}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _openTournament(tournamentId),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingTournament = false);
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
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _safelyFetchTournaments,
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TournamentFilterTabs(
                  selectedIndex: selectedTab,
                  onChanged: (index) {
                    setState(() => selectedTab = index);
                    String filter = 'all';
                    if (index == 1) filter = 'mine';
                    if (index == 2) filter = 'completed';
                    tournamentProvider.setFilter(filter);
                  },
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: tournamentProvider.isLoading
                      ? ListView.builder(
                          itemCount: 3,
                          itemBuilder: (context, index) => const SkeletonCard(),
                        )
                      : _buildTournamentsList(tournamentProvider),
                ),

                if (widget.isCaptain) ...[
                  const SizedBox(height: 12),
                  _buildCreateButton(tournamentProvider),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTournamentsList(TournamentProvider tournamentProvider) {
    try {
      final List<Tournament> data = tournamentProvider.filteredTournaments ?? [];

      if (data.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: _safelyFetchTournaments,
        child: ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            try {
              if (index >= data.length) {
                return const SizedBox.shrink();
              }

              final t = data[index];

              // Validate tournament data
              if (t.id.isEmpty) {
                debugPrint('Tournament at index $index has empty ID');
                return const SizedBox.shrink();
              }

              // Create model with safe data
              final model = TournamentModel(
                id: t.id,
                name: t.name.isNotEmpty ? t.name : 'Unnamed Tournament',
                status: t.status.isNotEmpty ? t.status : 'upcoming',
                type: 'Knockout',
                dateRange: _formatDateRange(t.startDate, t.endDate),
                location: 'Unknown',
                overs: 20,
                teams: const [],
              );

              return TournamentCard(
                tournament: model,
                onTap: () => _openTournament(t.id),
                isCaptain: widget.isCaptain,
                onTournamentStarted: _safelyFetchTournaments,
              );
            } catch (e) {
              debugPrint('Error building tournament card at index $index: $e');
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error loading tournament',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
              );
            }
          },
        ),
      );
    } catch (e) {
      debugPrint('Error building tournaments list: $e');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading tournaments',
              style: TextStyle(fontSize: 18, color: Colors.red[700]),
            ),
            const SizedBox(height: 8),
            Text(
              _getErrorMessage(e),
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _safelyFetchTournaments,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCreateButton(TournamentProvider tournamentProvider) {
    return ElevatedButton.icon(
      onPressed: _isLoadingTournament
          ? null
          : () async {
              try {
                final createdTournament = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateTournamentScreen(),
                  ),
                );

                if (createdTournament != null && mounted) {
                  await _safelyFetchTournaments();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Tournament created successfully! Check "My Tournaments" to manage teams and matches.',
                        ),
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                }
              } catch (e) {
                debugPrint('Error creating tournament: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${_getErrorMessage(e)}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
    );
  }

  Widget _buildEmptyState() {
    final tabTitles = [
      'tournaments',
      'tournaments you\'ve created',
      'completed tournaments'
    ];
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
            _getEmptyStateMessage(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          if (widget.isCaptain && selectedTab == 1) ...[
            const SizedBox(height: 24),
            _buildEmptyStateCreateButton(),
          ],
        ],
      ),
    );
  }

  String _getEmptyStateMessage() {
    switch (selectedTab) {
      case 0:
        return 'Tournaments will appear here once they\'re created.';
      case 1:
        return 'Create your first tournament to get started!';
      case 2:
        return 'Completed tournaments will appear here.';
      default:
        return '';
    }
  }

  Widget _buildEmptyStateCreateButton() {
    return ElevatedButton.icon(
      onPressed: _isLoadingTournament
          ? null
          : () async {
              try {
                if (!mounted) return;
                
                final tournamentProvider = Provider.of<TournamentProvider>(
                  context,
                  listen: false,
                );

                final createdTournament = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateTournamentScreen(),
                  ),
                );

                if (createdTournament != null && mounted) {
                  await _safelyFetchTournaments();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Tournament created successfully! Check "My Tournaments" to manage teams and matches.',
                        ),
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                }
              } catch (e) {
                debugPrint('Error creating tournament: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${_getErrorMessage(e)}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
      icon: const Icon(Icons.add),
      label: const Text("Create Your First Tournament"),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
}