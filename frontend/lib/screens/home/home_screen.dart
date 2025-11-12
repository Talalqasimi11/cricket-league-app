// lib/features/home/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../../widgets/bottom_nav.dart';
import '../../widgets/custom_dropdown_menu.dart';
import '../../widgets/offline_status_indicator.dart';
import '../../features/tournaments/screens/tournaments_screen.dart';
import '../../core/json_utils.dart';
import '../../core/theme/theme_config.dart';
import '../../core/error_dialog.dart';
import '../../features/teams/screens/my_team_screen.dart'; // ✅ My Team screen
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../features/matches/screens/matches_screen.dart'; // ✅ Matches screen
import '../../core/api_client.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  bool _loading = false;
  bool _searching = false;
  List<Map<String, dynamic>> _teams = [];
  List<Map<String, dynamic>> _filteredTeams = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _fetchTeams();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    _performClientSideSearch(query);
  }

  void _performClientSideSearch(String query) {
    setState(() {
      _searching = true;
    });

    if (query.isEmpty) {
      setState(() {
        _filteredTeams = _teams;
        _searching = false;
      });
      return;
    }

    final filtered = _teams.where((team) {
      final name = asType<String>(team['team_name'], '').toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredTeams = filtered;
      _searching = false;
    });
  }

  Future<void> _fetchTeams() async {
    setState(() => _loading = true);
    try {
      final resp = await ApiClient.instance.get('/api/teams');
      if (resp.statusCode == 200) {
        final response = jsonDecode(resp.body);

        setState(() {
          _teams = (response['teams'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
          _filteredTeams = _teams;
        });
      } else {
        if (mounted) {
          await ErrorDialog.showApiError(
            context,
            response: resp,
            onRetry: () => _fetchTeams(),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        await ErrorDialog.showGenericError(
          context,
          error: e,
          onRetry: () => _fetchTeams(),
          showRetryButton: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _homeTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Container(
          constraints: const BoxConstraints.expand(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'All Teams',
                          style: AppTypographyExtended.headlineSmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const OfflineStatusIndicator(),
                      ],
                    ),
                    if (!authProvider.isAuthenticated) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Login to manage your team and participate in tournaments',
                                style: AppTypographyExtended.bodyMedium.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search teams by name',
                          prefixIcon: Icon(
                            Icons.search,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          filled: true,
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _searching
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Searching...',
                              style: AppTypographyExtended.bodyLarge.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _filteredTeams.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shield,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'No teams found'
                                  : 'No teams available',
                              style: AppTypographyExtended.bodyLarge.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: _filteredTeams.length,
                        itemBuilder: (context, index) {
                          final t = _filteredTeams[index];
                          final String name = asType<String>(
                            t['team_name'],
                            'Unknown Team',
                          );
                          final int trophies = asType<int>(t['trophies'], 0);
                          final int teamId = asType<int>(t['id'], 0);
                          return GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/team/view',
                                arguments: {'teamId': teamId, 'teamName': name},
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.shield,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: AppTypographyExtended.titleMedium
                                      .copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                subtitle: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.emoji_events,
                                      size: 16,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '$trophies Trophies',
                                        style: AppTypographyExtended.bodySmall
                                            .copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _homeTab(), // ✅ All Teams
      const MatchesScreen(), // ✅ Matches screen connected here
      const TournamentsScreen(), // ✅ real tournaments page
      const MyTeamScreen(), // ✅ My Team page
    ];

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'CricLeague',
              style: AppTypographyExtended.headlineSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: Builder(
              builder: (context) {
                return IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () {
                    CustomDropdownOverlay.show(
                      context: context,
                      builder: (context) => AppMenu(
                        isAuthenticated: authProvider.isAuthenticated,
                        onLogin: () {
                          Navigator.pop(context); // Close menu
                          Navigator.pushNamed(context, '/login');
                        },
                        onLogout: () async {
                          Navigator.pop(context); // Close menu
                          await authProvider.logout();
                        },
                        onAccount: () {
                          Navigator.pop(context); // Close menu
                          Navigator.pushNamed(context, '/account');
                        },
                        onContact: () {
                          Navigator.pop(context); // Close menu
                          Navigator.pushNamed(context, '/contact');
                        },
                        onFeedback: () {
                          Navigator.pop(context); // Close menu
                          Navigator.pushNamed(context, '/feedback');
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          body: SafeArea(child: pages[_selectedIndex]),
          bottomNavigationBar: BottomNavBar(
            currentIndex: _selectedIndex,
            onTap: _onNavTapped,
          ),
        );
      },
    );
  }
}
