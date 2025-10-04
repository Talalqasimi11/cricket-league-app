// lib/features/teams/screens/team_dashboard_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/features/teams/screens/my_team_screen.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/player.dart'; // ✅ Use separate Player model
import 'player_dashboard_screen.dart';

class TeamDashboardScreen extends StatefulWidget {
  final String teamId; // use teamId to fetch data dynamically

  const TeamDashboardScreen({super.key, required this.teamId, required teamName, required teamLogoUrl, required trophies, required List<Player> players});

  @override
  State<TeamDashboardScreen> createState() => _TeamDashboardScreenState();
}

class _TeamDashboardScreenState extends State<TeamDashboardScreen> {
  final storage = const FlutterSecureStorage();
  bool _isLoading = true;
  String teamName = '';
  String teamLogoUrl = '';
  int trophies = 0;
  List<Player> players = [];

  @override
  void initState() {
    super.initState();
    _fetchTeamDetails();
  }

  Future<void> _fetchTeamDetails() async {
    setState(() => _isLoading = true);
    final token = await storage.read(key: 'jwt_token');

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/teams/${widget.teamId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          teamName = data['team_name'] ?? '';
          teamLogoUrl = data['team_logo'] ?? '';
          trophies = data['trophies'] ?? 0;
          players = (data['players'] as List).map((p) => Player.fromJson(p)).toList();
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Failed to load team')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// API placeholder: Add player
  Future<void> _addPlayer(String name, String role) async {
    final token = await storage.read(key: 'jwt_token');

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/players'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'team_id': widget.teamId, 'player_name': name, 'player_role': role}),
      );

      if (response.statusCode == 201) {
        final newPlayer = Player.fromJson(jsonDecode(response.body));
        setState(() => players.add(newPlayer));
      }
    } catch (e) {
      debugPrint("Add player failed: $e");
    }
  }

  /// API placeholder: Edit team
  Future<void> _editTeam(String name, String logo) async {
    final token = await storage.read(key: 'jwt_token');
    try {
      final response = await http.put(
        Uri.parse('http://localhost:5000/api/teams/${widget.teamId}'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'team_name': name, 'team_logo': logo}),
      );

      if (response.statusCode == 200) {
        setState(() {
          teamName = name;
          teamLogoUrl = logo;
        });
      }
    } catch (e) {
      debugPrint("Edit team failed: $e");
    }
  }

  /// API placeholder: Delete team
  Future<void> _deleteTeam() async {
    final token = await storage.read(key: 'jwt_token');
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:5000/api/teams/${widget.teamId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Team $teamName deleted")));
      }
    } catch (e) {
      debugPrint("Delete team failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF122118),
      appBar: AppBar(
        backgroundColor: const Color(0xFF122118),
        elevation: 0,
        title: const Text(
          "Team Dashboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // TEAM LOGO + NAME + TROPHIES
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(
                          teamLogoUrl.isNotEmpty ? teamLogoUrl : 'https://picsum.photos/200',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        teamName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text("$trophies Trophies", style: const TextStyle(color: Colors.greenAccent)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // PLAYERS LIST
                  Expanded(
                    child: ListView.builder(
                      itemCount: players.length,
                      itemBuilder: (context, index) {
                        final player = players[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlayerDashboardScreen(player: player),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A2C22),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(radius: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        player.playerName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        player.playerRole,
                                        style: const TextStyle(
                                          color: Colors.greenAccent,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        "Runs: ${player.runs} | Avg: ${player.battingAverage} | SR: ${player.strikeRate} | Wkts: ${player.wickets}",
                                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ACTION BUTTONS
                  Column(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF15803D),
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.person_add, color: Colors.white),
                        label: const Text("Add Player"),
                        onPressed: () => _showAddPlayerDialog(context),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF15803D),
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.edit, color: Colors.white),
                              label: const Text("Edit Team"),
                              onPressed: () => _showEditTeamDialog(context, teamName, teamLogoUrl),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF20DF6C),
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.sports_cricket, color: Colors.black),
                              label: const Text(
                                "Start Match",
                                style: TextStyle(color: Colors.black),
                              ),
                              onPressed: () {
                                _showCaptainSelectionDialog(context, players);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        icon: const Icon(Icons.delete),
                        label: const Text("Delete Team"),
                        onPressed: () => _showDeleteOtpDialog(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  // --- Dialogs (unchanged, but now work with Player model) ---
  void _showAddPlayerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final roleController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2C22),
        title: const Text("Add Player", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Player Name"),
            ),
            TextField(
              controller: roleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Role"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              _addPlayer(nameController.text, roleController.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Player Added")));
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showEditTeamDialog(BuildContext context, String name, String logo) {
    final nameController = TextEditingController(text: name);
    final logoController = TextEditingController(text: logo);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2C22),
        title: const Text("Edit Team", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Team Name"),
            ),
            TextField(
              controller: logoController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Team Logo URL"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              _editTeam(nameController.text, logoController.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Team Updated")));
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showCaptainSelectionDialog(BuildContext context, List<Player> players) {
    Player? selectedCaptain;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A2C22),
            title: const Text("Select Captain", style: TextStyle(color: Colors.white)),
            content: DropdownButton<Player>(
              dropdownColor: const Color(0xFF1A2C22),
              value: selectedCaptain,
              hint: const Text("Choose a captain", style: TextStyle(color: Colors.white70)),
              isExpanded: true,
              items: players
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.playerName, style: const TextStyle(color: Colors.white)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => selectedCaptain = value),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  if (selectedCaptain != null) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Match started with ${selectedCaptain!.playerName} as captain",
                        ),
                      ),
                    );
                  }
                },
                child: const Text("Start Match"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteOtpDialog(BuildContext context) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2C22),
        title: const Text("OTP Verification", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Enter OTP sent to your registered phone to delete the team.",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: otpController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "OTP Code"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              _deleteTeam();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
