// lib/features/teams/screens/my_team_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/api_client.dart';
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
  String _error = '';

  // Simplified state variables
  Map<String, dynamic>? _teamData;
  List<Player> _players = [];
  final List<Map<String, dynamic>> _matches = []; // This remains for future use

  // --- Simplified Getters for Team Data ---
  // These getters are now much simpler, assuming a more consistent API response.
  // The Player model already handles variations in keys like 'id' vs '_id'.

  String get teamName => _teamData?['team_name']?.toString() ?? 'Team Name';
  String? get teamLogoUrl => _teamData?['team_logo']?.toString();
  int get trophies => _teamData?['trophies'] is int ? _teamData!['trophies'] : 0;
  String get teamId => _teamData?['id']?.toString() ?? '';
  int get matchesWon => _teamData?['matches_won'] is int ? _teamData!['matches_won'] : 0;
  String get ownerName =>
      _teamData?['owner_name']?.toString() ??
      _teamData?['captain_name']?.toString() ??
      'Owner Name';
  String get ownerPhone =>
      _teamData?['owner_phone']?.toString() ??
      _teamData?['captain_phone']?.toString() ??
      '';
  String? get ownerImage =>
      _teamData?['owner_image']?.toString() ??
      _teamData?['captain_image']?.toString();


  @override
  void initState() {
    super.initState();
    _fetchTeamData();
  }

  /// Fetches both team and player data.
  Future<void> _fetchTeamData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final token = await storage.read(key: 'jwt_token');
    if (token == null) {
      _logout();
      return;
    }

    try {
      // It's better if the backend provides one endpoint for team + players.
      // For now, we fetch them in parallel.
      final responses = await Future.wait([
        http.get(
          Uri.parse('${ApiClient.baseUrl}/api/teams/my-team'),
          headers: {'Authorization': 'Bearer $token'},
        ),
        http.get(
          Uri.parse('${ApiClient.baseUrl}/api/players/my-players'),
          headers: {'Authorization': 'Bearer $token'},
        ),
      ]);

      // Process Team Response
      final teamResponse = responses[0];
      if (teamResponse.statusCode == 200) {
        _teamData = jsonDecode(teamResponse.body) as Map<String, dynamic>;
      } else if (teamResponse.statusCode != 404) {
        // Only show error if it's not a "not found" error
        throw 'Failed to load team: ${teamResponse.statusCode}';
      }

      // Process Players Response
      final playersResponse = responses[1];
      if (playersResponse.statusCode == 200) {
        final playersList = jsonDecode(playersResponse.body) as List;
        _players = playersList.map((p) => Player.fromJson(p)).toList();
      } else {
        throw 'Failed to load players: ${playersResponse.statusCode}';
      }

    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error)));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _logout() async {
    await storage.delete(key: 'jwt_token');
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
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
          : _error.isNotEmpty && _teamData == null
              ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _fetchTeamData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Profile Section
                      _buildProfileSection(),
                      const SizedBox(height: 24),

                      // My Teams Section
                      _buildMyTeamSection(),
                      const SizedBox(height: 24),

                      // My Matches Section
                      _buildMyMatchesSection(),
                      const SizedBox(height: 32),

                      // Logout Button
                      _buildLogoutButton(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        CircleAvatar(
          radius: 56,
          backgroundColor: Colors.grey.shade700,
          backgroundImage: ownerImage != null ? NetworkImage(ownerImage!) : null,
          child: ownerImage == null
              ? const Icon(Icons.person, color: Colors.white54, size: 40)
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          ownerName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        Text(
          ownerPhone,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildMyTeamSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "My Teams",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        if (_teamData != null)
          Card(
            color: Colors.grey.shade800,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  teamLogoUrl ?? "https://picsum.photos/200",
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey.shade700,
                    child: const Icon(Icons.shield, color: Colors.white54),
                  ),
                ),
              ),
              title: Text(
                teamName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Matches Won: $matchesWon",
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeamDashboardScreen(
                      teamName: teamName,
                      teamLogoUrl: teamLogoUrl,
                      trophies: trophies,
                      players: _players,
                      teamId: teamId,
                    ),
                  ),
                );
              },
            ),
          )
        else
          const Text(
            "You are not part of a team yet.",
            style: TextStyle(color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildMyMatchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "My Matches",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        if (_matches.isEmpty)
          const Text(
            "No recent matches found.",
            style: TextStyle(color: Colors.grey),
          )
        else
          ..._matches.map((match) {
            // Your match card logic here
            return Card();
          }),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
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
    );
  }
}