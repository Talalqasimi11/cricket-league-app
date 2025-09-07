import 'package:flutter/material.dart';

class TournamentsScreen extends StatelessWidget {
  const TournamentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> tournaments = [
      {"name": "Summer Cup 2025", "status": "Ongoing", "teams": 8},
      {"name": "School League", "status": "Upcoming", "teams": 6},
      {"name": "Champions Trophy", "status": "Completed", "winner": "Warriors"},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Tournaments"), centerTitle: true),
      body: ListView.builder(
        itemCount: tournaments.length,
        itemBuilder: (context, index) {
          final t = tournaments[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(t["name"]),
              subtitle: Text(
                t["status"] == "Ongoing"
                    ? "Teams: ${t["teams"]} • Status: Ongoing"
                    : t["status"] == "Upcoming"
                    ? "Starts Soon • Teams Registered: ${t["teams"]}"
                    : "Winner: ${t["winner"]}",
                style: TextStyle(
                  color: t["status"] == "Ongoing"
                      ? Colors.green
                      : (t["status"] == "Upcoming" ? Colors.blue : Colors.black),
                  fontWeight: t["status"] == "Ongoing" ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Navigate to Tournament Details / Bracket Screen
              },
            ),
          );
        },
      ),
    );
  }
}
