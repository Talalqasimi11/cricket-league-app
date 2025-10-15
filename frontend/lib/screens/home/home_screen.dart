// lib/features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/bottom_nav.dart';
import '../../features/tournaments/screens/tournaments_screen.dart';
import '../../features/teams/screens/my_team_screen.dart'; // ✅ My Team screen
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
  List<Map<String, dynamic>> _teams = [];

  @override
  void initState() {
    super.initState();
    _fetchTeams();
  }

  Future<void> _fetchTeams() async {
    setState(() => _loading = true);
    try {
      final resp = await http.get(Uri.parse('${ApiClient.baseUrl}/api/teams/all'));
      if (resp.statusCode == 200) {
        final List<dynamic> list = List<dynamic>.from(jsonDecode(resp.body));
        setState(() {
          _teams = list.map((e) => e as Map<String, dynamic>).toList();
        });
      } else {
        // keep list empty and show message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load teams (${resp.statusCode})')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading teams: $e')),
        );
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
              const Text('All Teams', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _teams.length,
                  itemBuilder: (context, index) {
                    final t = _teams[index];
final String name = (t['team_name'] as String?) ?? 'Unknown Team';
                    final int trophies = (t['trophies'] as int?) ?? 0;
                    final String? teamId = (t['id']?.toString());
                    return GestureDetector(
                      onTap: () {
                        if (teamId == null) return;
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
                      BoxShadow(color: Color(0x11000000), blurRadius: 6, offset: Offset(0, 2)),
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
                      child: const Icon(Icons.shield, color: Color(0xFF15803D)),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Row(
                      children: [
                        const Icon(Icons.emoji_events, size: 16, color: Color(0xFF20DF6C)),
                        const SizedBox(width: 6),
                        Text(
                          '$trophies Trophies',
                          style: const TextStyle(color: Color(0xFF20DF6C)),
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
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: BottomNavBar(currentIndex: _selectedIndex, onTap: _onNavTapped),
    );
  }
}
