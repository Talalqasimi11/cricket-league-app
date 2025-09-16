// lib/features/teams/screens/player_dashboard_screen.dart

import 'package:flutter/material.dart';

class PlayerDashboardScreen extends StatelessWidget {
  final String playerName;
  final String role;
  final String teamName;
  final String imageUrl;
  final int runs;
  final double battingAvg;
  final double strikeRate;
  final int wickets;
  final int fifties;
  final int hundreds;

  const PlayerDashboardScreen({
    super.key,
    required this.playerName,
    required this.role,
    required this.teamName,
    required this.imageUrl,
    required this.runs,
    required this.battingAvg,
    required this.strikeRate,
    required this.wickets,
    required this.fifties,
    required this.hundreds,
  });

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
                CircleAvatar(radius: 60, backgroundImage: NetworkImage(imageUrl)),
                const SizedBox(height: 10),
                Text(
                  playerName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text("$role • $teamName", style: const TextStyle(color: Colors.grey)),
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
                _buildStatCard(Icons.sports_cricket, "Runs", runs.toString()),
                _buildStatCard(Icons.leaderboard, "Batting Avg", battingAvg.toStringAsFixed(2)),
                _buildStatCard(Icons.trending_up, "Strike Rate", strikeRate.toStringAsFixed(2)),
                _buildStatCard(Icons.sports, "Wickets", wickets.toString()),
                _buildStatCard(null, "50s", fifties.toString(), customText: "50"),
                _buildStatCard(null, "100s", hundreds.toString(), customText: "100"),
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
                _showEditPlayerDialog(context);
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
  void _showEditPlayerDialog(BuildContext context) {
    final nameController = TextEditingController(text: playerName);
    final roleController = TextEditingController(text: role);
    final runsController = TextEditingController(text: runs.toString());
    final avgController = TextEditingController(text: battingAvg.toString());
    final strikeController = TextEditingController(text: strikeRate.toString());
    final wicketsController = TextEditingController(text: wickets.toString());
    final fiftiesController = TextEditingController(text: fifties.toString());
    final hundredsController = TextEditingController(text: hundreds.toString());

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
              CircleAvatar(radius: 50, backgroundImage: NetworkImage(imageUrl)),
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
              TextField(
                controller: fiftiesController,
                decoration: const InputDecoration(labelText: "50s"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: hundredsController,
                decoration: const InputDecoration(labelText: "100s"),
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
