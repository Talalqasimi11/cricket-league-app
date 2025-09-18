// lib/features/teams/screens/player_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'team_dashboard_screen.dart'; // ✅ Import Player model

class PlayerDashboardScreen extends StatelessWidget {
  final Player player; // ✅ Full player object

  const PlayerDashboardScreen({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // light background
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Player Image + Name
            Column(
              children: [
                CircleAvatar(radius: 60, backgroundImage: NetworkImage(player.imageUrl)),
                const SizedBox(height: 10),
                Text(
                  player.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(player.role, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 20),

            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildStatCard(Icons.sports_cricket, "Runs", player.runs.toString()),
                _buildStatCard(
                  Icons.leaderboard,
                  "Batting Avg",
                  player.battingAverage.toStringAsFixed(2),
                ),
                _buildStatCard(
                  Icons.trending_up,
                  "Strike Rate",
                  player.strikeRate.toStringAsFixed(2),
                ),
                _buildStatCard(Icons.sports, "Wickets", player.wickets.toString()),
              ],
            ),
            const SizedBox(height: 20),

            // Edit Player Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16a34a),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text("Edit Player Info", style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                _showEditPlayerDialog(context, player);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Card builder for stats
  Widget _buildStatCard(IconData? icon, String title, String value, {String? customText}) {
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
          if (icon != null)
            Icon(icon, size: 40, color: Colors.green)
          else
            Text(
              customText ?? "",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
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

  /// Popup dialog for editing player info
  void _showEditPlayerDialog(BuildContext context, Player player) {
    final nameController = TextEditingController(text: player.name);
    final roleController = TextEditingController(text: player.role);
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
              CircleAvatar(radius: 50, backgroundImage: NetworkImage(player.imageUrl)),
              const SizedBox(height: 20),
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
                        // TODO: Save updated player info to backend
                        Navigator.pop(context);
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text("Player Info Updated")));
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
