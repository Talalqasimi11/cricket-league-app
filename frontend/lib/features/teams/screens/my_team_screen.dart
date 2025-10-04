// lib/features/teams/screens/my_team_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'team_dashboard_screen.dart';
import '../models/player.dart';

class MyTeamScreen extends StatefulWidget {
  const MyTeamScreen({super.key});

  @override
  State<MyTeamScreen> createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends State<MyTeamScreen> {
  final storage = const FlutterSecureStorage();

  bool _isLoading = true;
  Map<String, dynamic>? _teamData;
  List<Player> _players = [];
  List<Map<String, dynamic>> _matches = [];

  @override
  void initState() {
    super.initState();
    _fetchTeamData();
  }

  Future<void> _fetchTeamData() async {
    setState(() => _isLoading = true);
    final token = await storage.read(key: 'jwt_token');

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/teams/my-team'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _teamData = data['team'];
          _players = (data['players'] as List).map((player) => Player.fromJson(player)).toList();
          _matches = List<Map<String, dynamic>>.from(data['matches'] ?? []);
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Failed to fetch team data')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    await storage.delete(key: 'jwt_token');
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        elevation: 0,
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile avatar + name + email
                Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 56,
                          backgroundImage: NetworkImage(
                            _teamData?['captain_image'] ??
                                'https://lh3.googleusercontent.com/a-/profile.png',
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                              onPressed: () {
                                // TODO: change profile picture
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _teamData?['captain_name'] ?? 'Captain Name',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      _teamData?['captain_phone'] ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // My Teams Section
                const Text(
                  "My Teams",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Card(
                  color: Colors.grey.shade800,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _teamData?['team_logo'] ?? "https://picsum.photos/200/200",
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      _teamData?['team_name'] ?? "Team Name",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Matches Won: ${_teamData?['matches_won'] ?? 0}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeamDashboardScreen(
                            teamName: _teamData?['team_name'] ?? '',
                            teamLogoUrl: _teamData?['team_logo'] ?? '',
                            trophies: _teamData?['trophies'] ?? 0,
                            players: _players,
                            teamId: '',
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // My Matches Section
                const Text(
                  "My Matches",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                ..._matches.map((match) {
                  return Card(
                    color: Colors.grey.shade800,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              match['opponent_logo'] ?? "https://picsum.photos/200/201",
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            "${_teamData?['team_name']} vs ${match['opponent_name']}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            match['result'] == 'won' ? "Won" : "Lost",
                            style: TextStyle(
                              color: match['result'] == 'won' ? Colors.green : Colors.red,
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                          onTap: () {
                            // TODO: Navigate to match details
                          },
                        ),
                        const Divider(color: Colors.grey),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 32),

                // Logout button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade800,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _logout,
                  child: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey.shade900,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        currentIndex: 3, // Profile active
        onTap: (index) {
          // TODO: navigation handling
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.sports_cricket), label: "Matches"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Stats"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
