// lib/features/tournaments/screens/tournaments_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth_provider.dart';
import '../models/tournament_model.dart';
import '../providers/tournament_provider.dart';
import '../widgets/tournament_card.dart';
import '../widgets/tournament_filter_tabs.dart';
import 'tournament_create_screen.dart';
import 'tournament_details_viewer_screen.dart';
import 'tournament_details_creator_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _fetchTournamentsSafely(),
    );
  }

  Future<void> _loadUserId() async {
    try {
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = int.tryParse(authProvider.userId ?? '');
      if (userId != null) {
        Provider.of<TournamentProvider>(
          context,
          listen: false,
        ).setCurrentUserId(userId);
      }
    } catch (e) {
      debugPrint('Error loading user ID: $e');
    }
  }

  Future<void> _fetchTournamentsSafely({bool forceRefresh = false}) async {
    try {
      if (!mounted) return;
      // Set initial filter based on default tab (0 -> Active)
      final provider = Provider.of<TournamentProvider>(context, listen: false);

      if (selectedTab == 0) {
        provider.setFilter('active'); // 'live' -> 'active' to match model
      } else if (selectedTab == 1) {
        provider.setFilter('upcoming');
      } else if (selectedTab == 2) {
        provider.setFilter('completed');
      } else if (selectedTab == 3) {
        provider.setFilter('mine');
      }

      await provider.fetchTournaments(forceRefresh: forceRefresh);
    } catch (e) {
      debugPrint('Error fetching tournaments: $e');
      if (mounted) {
        _showSnack(
          'Failed to load tournaments: $e',
          action: () => _fetchTournamentsSafely(forceRefresh: true),
        );
      }
    }
  }

  void _showSnack(String message, {VoidCallback? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: action != null
            ? SnackBarAction(label: 'Retry', onPressed: action)
            : null,
      ),
    );
  }

  Future<void> _openTournament(TournamentModel tournament) async {
    if (_isLoadingTournament) return;
    setState(() => _isLoadingTournament = true);

    try {
      final provider = Provider.of<TournamentProvider>(context, listen: false);
      final isCreator = provider.canEdit(tournament);

      if (isCreator) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                TournamentDetailsCreatorScreen(tournament: tournament),
          ),
        );
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                TournamentDetailsViewerScreen(tournament: tournament),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error opening tournament: $e');
      if (mounted) {
        _showSnack(
          'Error opening tournament: $e',
          action: () => _openTournament(tournament),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingTournament = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TournamentProvider>(
      builder: (context, provider, _) {
        final authProvider = Provider.of<AuthProvider>(context);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tournaments'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _fetchTournamentsSafely(forceRefresh: true),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TournamentFilterTabs(
                  selectedIndex: selectedTab,
                  onChanged: (index) {
                    setState(() => selectedTab = index);
                    // Updated filter mapping
                    if (index == 0) {
                      provider.setFilter('active');
                    } else if (index == 1) {
                      provider.setFilter('upcoming');
                    } else if (index == 2) {
                      provider.setFilter('completed');
                    } else if (index == 3) {
                      provider.setFilter('mine');
                    }
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: provider.isLoading
                      ? ListView.builder(
                          itemCount: 3,
                          itemBuilder: (_, __) =>
                              const Placeholder(fallbackHeight: 100),
                        )
                      : _buildTournamentsList(provider),
                ),
                if (authProvider.isAuthenticated) const SizedBox(height: 12),
                if (authProvider.isAuthenticated) _buildCreateButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTournamentsList(TournamentProvider provider) {
    final data = provider.filteredTournaments;
    if (data.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: () => _fetchTournamentsSafely(forceRefresh: true),
      child: ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          final t = data[index];
          final isOwner = provider.canEdit(t);

          return TournamentCard(
            tournament: t,
            onTap: () => _openTournament(t),
            isCreator: isOwner,
          );
        },
      ),
    );
  }

  Widget _buildCreateButton() {
    return ElevatedButton.icon(
      onPressed: _isLoadingTournament
          ? null
          : () async {
              if (!mounted) return;
              final created = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateTournamentScreen(),
                ),
              );
              if (created != null && mounted) {
                // [Fix] Auto-switch to "My Tournaments" (Index 3)
                setState(() => selectedTab = 3);
                Provider.of<TournamentProvider>(
                  context,
                  listen: false,
                ).setFilter('mine');

                await _fetchTournamentsSafely(forceRefresh: true);
                if (mounted) _showSnack('Tournament created successfully!');
              }
            },
      icon: const Icon(Icons.add),
      label: const Text('Create Tournament'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildEmptyState() {
    final tabTitles = [
      'live tournaments',
      'upcoming tournaments',
      'completed tournaments',
      'your tournaments',
    ];
    final tabTitle = tabTitles[selectedTab];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selectedTab == 3 ? Icons.edit_document : Icons.sports_cricket,
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
                ? 'Live matches will appear here.'
                : selectedTab == 1
                ? 'Scheduled tournaments will appear here.'
                : selectedTab == 2
                ? 'Past tournament results will appear here.'
                : 'Create a tournament to manage it here.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          if (selectedTab == 3) const SizedBox(height: 24),
        ],
      ),
    );
  }
}
