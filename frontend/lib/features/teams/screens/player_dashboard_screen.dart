// lib/features/teams/screens/player_dashboard_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ✅ Import Player model
import '../models/player.dart';

class PlayerDashboardScreen extends StatefulWidget {
  final Player player;

  const PlayerDashboardScreen({super.key, required this.player});

  @override
  State<PlayerDashboardScreen> createState() => _PlayerDashboardScreenState();
}

class _PlayerDashboardScreenState extends State<PlayerDashboardScreen> {
  final storage = const FlutterSecureStorage();
  late Player _player;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _player = widget.player;
  }

  /// 🔹 Update Player on Backend
  Future<void> _updatePlayer(Player updatedPlayer) async {
    setState(() => _loading = true);
    final token = await storage.read(key: 'jwt_token');

    final response = await http.put(
      Uri.parse("http://localhost:5000/api/players/${updatedPlayer.id}"),
      headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"},
      body: jsonEncode(updatedPlayer.toJson()),
    );

    setState(() => _loading = false);

    if (response.statusCode == 200) {
      setState(() => _player = updatedPlayer);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ Player info updated")));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Failed: ${response.body}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Player Dashboard",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 🔹 Player Image + Name
                  Column(
                    children: [
                      CircleAvatar(radius: 60, backgroundColor: Colors.grey[300]),
                      const SizedBox(height: 10),
                      Text(
                        _player.playerName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(_player.playerRole, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 🔹 Stats Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildStatCard(Icons.sports_cricket, "Runs", _player.runs.toString()),
                      _buildStatCard(
                        Icons.leaderboard,
                        "Batting Avg",
                        _player.battingAverage.toStringAsFixed(2),
                      ),
                      _buildStatCard(
                        Icons.trending_up,
                        "Strike Rate",
                        _player.strikeRate.toStringAsFixed(2),
                      ),
                      _buildStatCard(Icons.sports, "Wickets", _player.wickets.toString()),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 🔹 Edit Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16a34a),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      "Edit Player Info",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _showEditPlayerDialog(_player),
                  ),
                ],
              ),
            ),
    );
  }

  /// 🔹 Card builder for stats
  Widget _buildStatCard(IconData? icon, String title, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, size: 40, color: Colors.green),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  /// 🔹 Popup dialog for editing player info
  void _showEditPlayerDialog(Player player) {
    final nameController = TextEditingController(text: player.playerName);
    final roleController = TextEditingController(text: player.playerRole);
    final runsController = TextEditingController(text: player.runs.toString());
    final avgController = TextEditingController(text: player.battingAverage.toString());
    final strikeController = TextEditingController(text: player.strikeRate.toString());
    final wicketsController = TextEditingController(text: player.wickets.toString());

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Edit Player Info",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 20),
              CircleAvatar(radius: 50, backgroundColor: Colors.grey[300]),
              const SizedBox(height: 20),

              // 🔹 Input fields
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Player Name"),
              ),
              TextField(
                controller: roleController,
                decoration: const InputDecoration(labelText: "Role"),
              ),
              TextField(
                controller: runsController,
                decoration: const InputDecoration(labelText: "Runs"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: avgController,
                decoration: const InputDecoration(labelText: "Batting Avg"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: strikeController,
                decoration: const InputDecoration(labelText: "Strike Rate"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: wicketsController,
                decoration: const InputDecoration(labelText: "Wickets"),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final updated = Player(
                          id: player.id,
                          playerName: nameController.text,
                          playerRole: roleController.text,
                          runs: int.tryParse(runsController.text) ?? 0,
                          matchesPlayed: player.matchesPlayed,
                          hundreds: player.hundreds,
                          fifties: player.fifties,
                          battingAverage: double.tryParse(avgController.text) ?? 0,
                          strikeRate: double.tryParse(strikeController.text) ?? 0,
                          wickets: int.tryParse(wicketsController.text) ?? 0,
                        );
                        Navigator.pop(context);
                        _updatePlayer(updated);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16a34a)),
                      child: const Text("Save Changes"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
