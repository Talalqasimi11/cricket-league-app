// lib/features/home/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../../widgets/bottom_nav.dart';
import '../../features/tournaments/screens/tournaments_screen.dart';
import '../../core/json_utils.dart';
import '../../features/teams/screens/my_team_screen.dart'; // ✅ My Team screen
import 'package:provider/provider.dart';
import '../../core/theme_notifier.dart';
import '../../features/matches/screens/matches_screen.dart'; // ✅ Matches screen
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api_client.dart';

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load teams (${resp.statusCode})'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading teams: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onNavTapped(int index) async {
    // If "My Team" tab is tapped, check auth and redirect to login if needed
    if (index == 3) {
      final token = await _storage.read(key: 'jwt_token');
      if (!mounted) return;
      if (token == null || token.isEmpty) {
        Navigator.pushNamed(context, '/login');
        return; // do not switch tab
      }
    }
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _homeTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              const Text(
                'All Teams',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search teams by name',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
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
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Searching...',
                        style: TextStyle(color: Colors.grey),
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
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade100),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x11000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.shield,
                              color: Color(0xFF15803D),
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Row(
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                size: 16,
                                color: Color(0xFF20DF6C),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$trophies Trophies',
                                style: const TextStyle(
                                  color: Color(0xFF20DF6C),
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
                style: const TextStyle(fontWeight: FontWeight.w500),
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
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ],
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('CricLeague'),
        leading: PopupMenuButton<String>(
          icon: const Icon(Icons.menu),
          onSelected: (value) async {
            switch (value) {
              case 'account':
                if (!mounted) return;
                Navigator.pushNamed(context, '/account');
                break;
              case 'contact':
                if (!mounted) return;
                Navigator.pushNamed(context, '/contact');
                break;
              case 'feedback':
                if (!mounted) return;
                Navigator.pushNamed(context, '/feedback');
                break;
              case 'theme':
                try {
                  // Toggle theme via provider
                  // ignore: use_build_context_synchronously
                  await context.read<ThemeNotifier>().toggle();
                } catch (_) {}
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'account', child: Text('Account')),
            const PopupMenuItem(value: 'contact', child: Text('Contact Us')),
            const PopupMenuItem(value: 'feedback', child: Text('Feedback')),
            const PopupMenuItem(
              value: 'theme',
              child: Text('Theme: Light/Dark'),
            ),
          ],
        ),
      ),
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
      ),
    );
  }
}
