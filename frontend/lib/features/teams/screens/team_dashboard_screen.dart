// lib/features/teams/screens/team_dashboard_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/player.dart';
import 'player_dashboard_screen.dart';

class TeamDashboardScreen extends StatefulWidget {
  // These initial values are useful for a faster perceived load time.
  final String? teamId;
  final String? teamName;
  final String? teamLogoUrl;
  final int? trophies;
  final List<Player>? players;

  const TeamDashboardScreen({
    super.key,
    this.teamId,
    this.teamName,
    this.teamLogoUrl,
    this.trophies,
    this.players,
  });

  @override
  State<TeamDashboardScreen> createState() => _TeamDashboardScreenState();
}

class _TeamDashboardScreenState extends State<TeamDashboardScreen> {
  final storage = const FlutterSecureStorage();
  bool _isLoading = true;

  // --- State variables ---
  String teamName = '';
  String teamLogoUrl = '';
  String teamLocation = '';
  int trophies = 0;
  List<Player> players = [];
  int? captainPlayerId;
  int? viceCaptainPlayerId;

  @override
  void initState() {
    super.initState();
    // Use initial widget data to build the UI instantly
    teamName = widget.teamName ?? 'Team';
    teamLogoUrl = widget.teamLogoUrl ?? '';
    trophies = widget.trophies ?? 0;
    players = widget.players ?? [];
    // Fetch the latest data from the server in the background
    _fetchTeamDetails();
  }

  Future<void> _fetchTeamDetails() async {
    setState(() => _isLoading = true);
    final token = await storage.read(key: 'jwt_token');

    try {
      // Fetch team and players in parallel for efficiency
      final responses = await Future.wait([
        http.get(Uri.parse('${ApiClient.baseUrl}/api/teams/my-team'), headers: {'Authorization': 'Bearer $token'}),
        http.get(Uri.parse('${ApiClient.baseUrl}/api/players/my-players'), headers: {'Authorization': 'Bearer $token'}),
      ]);

      final teamResponse = responses[0];
      final playersResponse = responses[1];

      // Process players first, as they are needed for captain/vice-captain logic
      if (playersResponse.statusCode == 200) {
        final list = jsonDecode(playersResponse.body) as List;
        players = list.map((p) => Player.fromJson(p)).toList();
      }

      if (teamResponse.statusCode == 200) {
        final data = jsonDecode(teamResponse.body);
        teamName = data['team_name']?.toString() ?? teamName;
        teamLogoUrl = data['team_logo']?.toString() ?? teamLogoUrl;
        teamLocation = data['team_location']?.toString() ?? teamLocation;
        trophies = (data['trophies'] as num?)?.toInt() ?? trophies;

        // --- Safer Captain/Vice-Captain ID resolution ---
        // It's crucial that the backend sends IDs. Name matching is unreliable.
        captainPlayerId = (data['captain_player_id'] as num?)?.toInt();
        viceCaptainPlayerId = (data['vice_captain_player_id'] as num?)?.toInt();
      }

      if (teamResponse.statusCode != 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not refresh team data.')));
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Adds a new player with optimistic UI update.
  Future<void> _addPlayer(String name, String role) async {
    final token = await storage.read(key: 'jwt_token');
    final placeholderId = DateTime.now().millisecondsSinceEpoch * -1;
    final placeholder = Player(id: placeholderId, playerName: name, playerRole: role, runs: 0, matchesPlayed: 0, hundreds: 0, fifties: 0, battingAverage: 0, strikeRate: 0, wickets: 0);
    
    // Optimistic UI update
    setState(() => players.add(placeholder));

    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/api/players/add'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'player_name': name, 'player_role': role}),
      );

      if (response.statusCode == 201) {
        final newPlayer = Player.fromJson(jsonDecode(response.body));
        // Replace placeholder with the real player from the server
        setState(() {
          final index = players.indexWhere((p) => p.id == placeholderId);
          if (index != -1) players[index] = newPlayer;
        });
      } else {
        throw 'Failed to add player: ${response.body}';
      }
    } catch (e) {
      // Revert on failure
      setState(() => players.removeWhere((p) => p.id == placeholderId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  /// Edits the team details.
  Future<void> _editTeam(String newName, String newLocation, {int? captainId, int? viceCaptainId}) async {
    final token = await storage.read(key: 'jwt_token');
    try {
      final response = await http.put(
        Uri.parse('${ApiClient.baseUrl}/api/teams/update'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'team_name': newName,
          'team_location': newLocation,
          if (captainId != null) 'captain_player_id': captainId,
          if (viceCaptainId != null) 'vice_captain_player_id': viceCaptainId,
        }),
      );

      if (response.statusCode == 200) {
        // Update local state on success
        setState(() {
          teamName = newName;
          teamLocation = newLocation;
          captainPlayerId = captainId ?? captainPlayerId;
          viceCaptainPlayerId = viceCaptainId ?? viceCaptainPlayerId;
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Team Updated")));
      } else {
        throw 'Failed to update team: ${response.body}';
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
  
  // NOTE: A "Delete Team" endpoint was not found in the backend code provided.
  // This function is a placeholder.
  Future<void> _deleteTeam() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Delete functionality is not yet implemented in the backend."))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF122118),
      appBar: AppBar(
        backgroundColor: const Color(0xFF122118),
        elevation: 0,
        title: Text(teamName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading && players.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchTeamDetails,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    _buildTeamHeader(),
                    const SizedBox(height: 20),
                    Expanded(child: _buildPlayersList()),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTeamHeader() => Column(
    children: [
      CircleAvatar(
        radius: 60,
        backgroundColor: Colors.grey.shade800,
        backgroundImage: teamLogoUrl.isNotEmpty ? NetworkImage(teamLogoUrl) : null,
        child: teamLogoUrl.isEmpty ? const Icon(Icons.shield, color: Colors.white54, size: 60) : null,
      ),
      const SizedBox(height: 8),
      Text(teamName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
      Text("$trophies Trophies", style: const TextStyle(color: Color(0xFF95C6A9))),
    ],
  );

  Widget _buildPlayersList() => players.isEmpty
      ? const Center(child: Text("No players in this team yet.", style: TextStyle(color: Colors.grey)))
      : ListView.builder(
          itemCount: players.length,
          itemBuilder: (context, index) {
            final player = players[index];
            bool isCaptain = player.id == captainPlayerId;
            bool isViceCaptain = player.id == viceCaptainPlayerId;
            return Card(
              color: const Color(0xFF1A2C22),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(radius: 24, child: Icon(Icons.person)),
                title: Text(player.playerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  "${player.playerRole}\nRuns: ${player.runs} | Avg: ${player.battingAverage.toStringAsFixed(1)}",
                  style: const TextStyle(color: Color(0xFF95C6A9), fontSize: 12),
                ),
                trailing: isCaptain
                  ? const Chip(label: Text('C'), backgroundColor: Colors.amber)
                  : isViceCaptain ? const Chip(label: Text('VC')) : null,
                onTap: () async {
                  final updatedPlayer = await Navigator.push<Player>(
                    context,
                    MaterialPageRoute(builder: (_) => PlayerDashboardScreen(player: player)),
                  );
                  if (updatedPlayer != null) {
                    setState(() {
                      players[index] = updatedPlayer;
                    });
                  }
                },
              ),
            );
          },
        );

  Widget _buildActionButtons() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16.0),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF15803D), padding: const EdgeInsets.symmetric(vertical: 12)),
                icon: const Icon(Icons.person_add, color: Colors.white),
                label: const Text("Add Player", style: TextStyle(color: Colors.white)),
                onPressed: () => _showAddPlayerDialog(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF15803D), padding: const EdgeInsets.symmetric(vertical: 12)),
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text("Edit Team", style: TextStyle(color: Colors.white)),
                onPressed: () => _showEditTeamDialog(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          icon: const Icon(Icons.delete),
          label: const Text("Delete Team"),
          onPressed: _deleteTeam,
        ),
      ],
    ),
  );

  void _showAddPlayerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final roles = ['Batsman', 'Bowler', 'All-rounder', 'Wicketkeeper'];
    String? selectedRole = roles[0];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Player"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Player Name")),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedRole,
              decoration: const InputDecoration(labelText: "Role"),
              items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (value) => selectedRole = value,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty || selectedRole == null) return;
              _addPlayer(name, selectedRole!);
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showEditTeamDialog(BuildContext context) {
    final nameController = TextEditingController(text: teamName);
    final locationController = TextEditingController(text: teamLocation);
    int? tempCaptainId = captainPlayerId;
    int? tempViceCaptainId = viceCaptainPlayerId;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text("Edit Team"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Team Name")),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: "Team Location")),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: tempCaptainId,
                  decoration: const InputDecoration(labelText: "Captain"),
                  items: players.map((p) => DropdownMenuItem<int>(value: p.id, child: Text(p.playerName))).toList(),
                  onChanged: (v) => setStateDialog(() => tempCaptainId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: tempViceCaptainId,
                  decoration: const InputDecoration(labelText: "Vice Captain"),
                  items: players.map((p) => DropdownMenuItem<int>(value: p.id, child: Text(p.playerName))).toList(),
                  onChanged: (v) => setStateDialog(() => tempViceCaptainId = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (tempCaptainId != null && tempCaptainId == tempViceCaptainId) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Captain and Vice Captain must be different.')));
                  return;
                }
                _editTeam(nameController.text.trim(), locationController.text.trim(), captainId: tempCaptainId, viceCaptainId: tempViceCaptainId);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      }),
    );
  }
}