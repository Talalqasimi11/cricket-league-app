// lib/features/teams/screens/my_team_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../../../core/json_utils.dart';
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

  String get teamName => asType<String>(_teamData?['team_name'], 'Team Name');
  String? get teamLogoUrl => _teamData?['team_logo']?.toString();
  int get trophies => asType<int>(_teamData?['trophies'], 0);
  String get teamId => asType<String>(_teamData?['id'], '');
  int get matchesWon => asType<int>(_teamData?['matches_won'], 0);
  String get ownerName => 'Team Owner';
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
        ApiClient.instance.get(
          '/api/teams/my-team',
          headers: {'Authorization': 'Bearer $token'},
        ),
        ApiClient.instance.get(
          '/api/players/my-players',
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_error)));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // removed duplicate simple logout; consolidated into the full logout at bottom

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty && _teamData == null
          ? Center(
              child: Text(
                _error,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            )
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      children: [
        CircleAvatar(
          radius: 56,
          backgroundColor: cs.surfaceContainerHighest,
          backgroundImage: ownerImage != null
              ? NetworkImage(ownerImage!)
              : null,
          child: ownerImage == null
              ? Icon(Icons.person, color: cs.onSurface, size: 40)
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          ownerName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          ownerPhone,
          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface),
        ),
      ],
    );
  }

  Widget _buildMyTeamSection() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "My Teams",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_teamData != null)
          Card(
            color: cs.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                    color: cs.surfaceContainerHighest,
                    child: Icon(Icons.shield, color: cs.onSurface),
                  ),
                ),
              ),
              title: Text(
                teamName,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Matches Won: $matchesWon",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurface),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: cs.onSurface),
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
          Text(
            "You are not part of a team yet.",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cs.onSurface),
          ),
      ],
    );
  }

  Widget _buildMyMatchesSection() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "My Matches",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_matches.isEmpty)
          Text(
            "No recent matches found.",
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
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
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _logout,
      child: const Text(
        "Logout",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  void _logout() async {
    try {
      final rt = await storage.read(key: 'refresh_token');
      await ApiClient.instance.post(
        '/api/auth/logout',
        body: rt != null ? {'refresh_token': rt} : null,
      );
    } catch (_) {}
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'refresh_token');
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
