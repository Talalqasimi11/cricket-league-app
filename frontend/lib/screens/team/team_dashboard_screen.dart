import 'package:flutter/material.dart';

class TeamDashboardScreen extends StatelessWidget {
  final String teamName;
  const TeamDashboardScreen({super.key, required this.teamName});

  @override
  Widget build(BuildContext context) {
    // dummy players
    final players = [
      {"name": "Ali", "role": "Batsman", "runs": "482"},
      {"name": "Usman", "role": "Bowler", "wickets": "24"},
      {"name": "Imran", "role": "All-Rounder", "runs": "210"},
    ];

    return Scaffold(
      appBar: AppBar(title: Text(teamName)),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.green[700],
                      child: Text(
                        teamName[0],
                        style: const TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teamName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text("🏆 Trophies: 3"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text("Players", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: players.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final p = players[index];
                  return ListTile(
                    title: Text(p["name"]!),
                    subtitle: Text(
                      p["role"]! +
                          (p.containsKey("runs")
                              ? " • Runs: ${p['runs']}"
                              : (p.containsKey("wickets") ? " • Wickets: ${p['wickets']}" : "")),
                    ),
                    onTap: () {
                      // TODO: open player profile
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
