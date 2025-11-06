// lib/features/home/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/custom_dropdown_menu.dart';
import '../../features/tournaments/screens/tournaments_screen.dart';
import '../../core/json_utils.dart';
import '../../core/theme/theme_config.dart';
import '../../core/error_dialog.dart';
import '../../features/teams/screens/my_team_screen.dart'; // ✅ My Team screen
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../features/matches/screens/matches_screen.dart'; // ✅ Matches screen
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api_client.dart';

/// Menu item widget for the popup menu
class MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const MenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTypographyExtended.bodyLarge.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _loading = false;
  bool _searching = false;
  List<Map<String, dynamic>> _teams = [];
  List<Map<String, dynamic>> _filteredTeams = [];
  Timer? _debounceTimer;

  // Pagination state
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalTeams = 0;
  final int _pageSize = 20;

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

    if (query.isEmpty) {
      setState(() {
        _filteredTeams = _teams;
        _searching = false;
      });
      return;
    }

    setState(() {
      _searching = true;
    });

    try {
      // Server-side search with pagination
      await _fetchTeams(search: query);
    } catch (e) {
      // Fallback to client-side filtering
      _performClientSideSearch(query);
    }
  }

  void _performClientSideSearch(String query) {
    final filtered = _teams.where((team) {
      final name = asType<String>(team['team_name'], '').toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredTeams = filtered;
      _searching = false;
    });
  }

  Future<void> _fetchTeams({int page = 1, String? search}) async {
    setState(() => _loading = true);
    try {
      final searchQuery = search ?? _searchController.text.trim();
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': _pageSize.toString(),
      };

      if (searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final resp = await ApiClient.instance.get('/api/teams?$queryString');
      if (resp.statusCode == 200) {
        final response = jsonDecode(resp.body);

        setState(() {
          _teams = (response['teams'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
          _filteredTeams = _teams;
          _currentPage = response['pagination']['page'] ?? page;
          _totalPages = response['pagination']['pages'] ?? 1;
          _totalTeams = response['pagination']['total'] ?? 0;
        });
      } else {
        if (mounted) {
          await ErrorDialog.showApiError(
            context,
            response: resp,
            onRetry: () => _fetchTeams(page: page, search: search),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        await ErrorDialog.showGenericError(
          context,
          error: e,
          onRetry: () => _fetchTeams(page: page, search: search),
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
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  Text(
                    'All Teams',
                    style: AppTypographyExtended.headlineSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!authProvider.isAuthenticated) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search teams by name',
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isNotEmpty
                                ? 'No teams found'
                                : 'No teams available',
                            style: AppTypographyExtended.bodyLarge.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.shield,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                name,
                                style: AppTypographyExtended.titleMedium.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Icon(
                                    Icons.emoji_events,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$trophies Trophies',
                                    style: AppTypographyExtended.bodySmall.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
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
            // Pagination controls
            if (_totalPages > 1) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 1
                        ? () => _fetchTeams(page: _currentPage - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    'Page $_currentPage of $_totalPages',
                    style: AppTypographyExtended.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    onPressed: _currentPage < _totalPages
                        ? () => _fetchTeams(page: _currentPage + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Showing ${_teams.length} of $_totalTeams teams',
                style: AppTypographyExtended.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _homeTab(), // ✅ All Teams
      const MatchesScreen(), // ✅ Matches screen connected here
      const TournamentsScreen(isCaptain: true), // ✅ real tournaments page
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
            leading: CustomPopupMenu(
              menuBuilder: () => ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  color: AppColors.primary, // Using app's primary color
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!authProvider.isAuthenticated) ...[
                        MenuItem(
                          icon: Icons.login,
                          title: 'Login',
                          onTap: () {
                            Navigator.pushNamed(context, '/login');
                          },
                        ),
                      ] else ...[
                        MenuItem(
                          icon: Icons.account_circle,
                          title: 'Account',
                          onTap: () {
                            Navigator.pushNamed(context, '/account');
                          },
                        ),
                        MenuItem(
                          icon: Icons.logout,
                          title: 'Logout',
                          onTap: () async {
                            await authProvider.logout();
                          },
                        ),
                      ],
                      MenuItem(
                        icon: Icons.contact_support,
                        title: 'Contact Us',
                        onTap: () {
                          Navigator.pushNamed(context, '/contact');
                        },
                      ),
                      MenuItem(
                        icon: Icons.feedback,
                        title: 'Feedback',
                        onTap: () {
                          Navigator.pushNamed(context, '/feedback');
                        },
                      ),
                    ],
                  ),
                ),
              ),
              pressType: PressType.singleClick,
              child: Icon(
                Icons.menu,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              arrowColor: AppColors.primary,
              arrowSize: 10,
              barrierColor: Colors.black.withOpacity(0.2),
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
