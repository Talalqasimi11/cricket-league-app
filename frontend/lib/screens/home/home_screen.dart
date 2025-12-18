import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../widgets/bottom_nav.dart';
import '../../../widgets/custom_dropdown_menu.dart';
import '../../../widgets/offline_status_indicator.dart';

import '../../features/tournaments/screens/tournaments_screen.dart';
import '../../features/teams/screens/my_team_screen.dart';
import '../../features/stats/screens/statistics_screen.dart';
import '../../features/matches/screens/matches_screen.dart';

import '../../../core/theme/theme_config.dart';
import '../../../core/auth_provider.dart';
import '../../../core/api_client.dart';

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
    // Defensive: execute fetch after the current frame to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTeams();
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ✅ Helper: Convert relative backend path to full URL
  String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${ApiClient.baseUrl}$path';
  }

  // ✅ Helper: Safe String extraction
  String _safeString(dynamic value, [String fallback = '']) {
    return value?.toString() ?? fallback;
  }

  // ✅ Helper: Safe Int extraction
  int _safeInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) _performSearch();
    });
  }

  Future<void> _performSearch() async {
    if (!mounted) return;
    final query = _searchController.text.trim();
    _performClientSideSearch(query);
  }

  void _performClientSideSearch(String query) {
    if (!mounted) return;
    setState(() {
      _searching = true;
    });

    try {
      if (query.isEmpty) {
        setState(() {
          _filteredTeams = List.from(_teams); // Create a copy, don't reference
          _searching = false;
        });
        return;
      }

      final filtered = _teams.where((team) {
        final nameRaw = team['team_name'];
        final name = (nameRaw is String) ? nameRaw.toLowerCase() : '';
        return name.contains(query.toLowerCase());
      }).toList();

      setState(() {
        _filteredTeams = filtered;
        _searching = false;
      });
    } catch (e) {
      debugPrint("Search error: $e");
      setState(() {
        _filteredTeams = [];
        _searching = false;
      });
    }
  }

  Future<void> _fetchTeams({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final resp = await ApiClient.instance.get(
        '/api/teams',
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;

      if (resp.statusCode == 200) {
        dynamic responseData;
        try {
          if (resp.body.isEmpty) {
            throw const FormatException("Empty response body");
          }
          responseData = jsonDecode(resp.body);
        } catch (e) {
          throw const FormatException("Invalid JSON format from server");
        }

        if (responseData is Map<String, dynamic> &&
            responseData['teams'] is List) {
          final rawList = responseData['teams'] as List;

          final safeList = rawList
              .whereType<Map<String, dynamic>>() // Only accept Maps
              .toList();

          setState(() {
            _teams = safeList;
            _filteredTeams = List.from(safeList);
          });
        } else {
          debugPrint("API Error: Unexpected structure: $responseData");
          _showErrorSnackBar('Data format error. Please contact support.');
          // Do NOT clear existing data on format error
        }
      } else if (resp.statusCode == 401 || resp.statusCode == 403) {
        _showErrorSnackBar('Authentication expired. Please log in again.');
      } else if (resp.statusCode >= 500) {
        _showErrorSnackBar(
          'Server error (${resp.statusCode}). Try again later.',
        );
      } else {
        _showErrorSnackBar('Failed to load teams (${resp.statusCode})');
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint("Fetch error: $e");

      String userMessage = 'An unexpected error occurred.';
      if (e is SocketException) {
        userMessage = 'No internet connection.';
      } else if (e is FormatException) {
        userMessage = 'Bad data received from server.';
      } else if (e is TimeoutException) {
        userMessage = 'Connection timed out.';
      }

      _showErrorSnackBar(userMessage);

      // CRITICAL FIX: Do NOT clear existing data on error
      // This ensures offline data remains visible if online fetch fails
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.refresh,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: () => _fetchTeams(forceRefresh: true),
                              tooltip: 'Refresh Teams',
                            ),
                            const OfflineStatusIndicator(),
                          ],
                        ),
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
                                style: AppTypographyExtended.bodyMedium
                                    .copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
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
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.3),
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
                    : RefreshIndicator(
                        onRefresh: () => _fetchTeams(forceRefresh: true),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: _filteredTeams.length,
                          itemBuilder: (context, index) {
                            if (index >= _filteredTeams.length) {
                              return const SizedBox();
                            }

                            final t = _filteredTeams[index];
                            final String name = _safeString(
                              t['team_name'],
                              'Unknown Team',
                            );
                            final int trophies = _safeInt(t['trophies']);
                            final int teamId = _safeInt(t['id']);

                            // ✅ Fix: Get full image URL for rendering
                            final String logoPath = _safeString(
                              t['team_logo_url'] ?? t['team_logo'],
                            );
                            final String logoUrl = _getFullImageUrl(logoPath);

                            return GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/team/view',
                                  arguments: {
                                    'teamId': teamId,
                                    'teamName': name,
                                  },
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outlineVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: logoUrl.isNotEmpty
                                          ? Image.network(
                                              logoUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Icon(
                                                      Icons.shield,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                    );
                                                  },
                                            )
                                          : Icon(
                                              Icons.shield,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
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
                                        color: Colors.amber.shade700,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '$trophies Trophies',
                                          style: AppTypographyExtended.bodySmall
                                              .copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
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
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeIndex = (_selectedIndex >= 0 && _selectedIndex < 5)
        ? _selectedIndex
        : 0;

    final pages = [
      _homeTab(),
      const MatchesScreen(),
      const TournamentsScreen(),
      const StatisticsScreen(),
      const MyTeamScreen(),
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
                    if (context.mounted) {
                      CustomDropdownOverlay.show(
                        context: context,
                        builder: (ctx) => AppMenu(
                          isAuthenticated: authProvider.isAuthenticated,
                          onLogin: () {
                            if (ctx.mounted) Navigator.pop(ctx);
                            Navigator.pushNamed(context, '/login');
                          },
                          onLogout: () async {
                            if (ctx.mounted) Navigator.pop(ctx);
                            await authProvider.logout();
                          },
                          onAccount: () {
                            if (ctx.mounted) Navigator.pop(ctx);
                            Navigator.pushNamed(context, '/account');
                          },
                          onContact: () {
                            if (ctx.mounted) Navigator.pop(ctx);
                            Navigator.pushNamed(context, '/contact');
                          },
                          onFeedback: () {
                            if (ctx.mounted) Navigator.pop(ctx);
                            Navigator.pushNamed(context, '/feedback');
                          },
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
          body: SafeArea(child: pages[safeIndex]),
          bottomNavigationBar: BottomNavBar(
            currentIndex: safeIndex,
            onTap: _onNavTapped,
          ),
        );
      },
    );
  }
}
