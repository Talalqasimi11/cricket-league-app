import 'package:flutter/material.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> matches = [
      {"teamA": "Warriors", "teamB": "Titans", "status": "Live", "overs": "12.3"},
      {"teamA": "Strikers", "teamB": "Riders", "status": "Upcoming", "time": "Tomorrow 3:00 PM"},
      {
        "teamA": "Titans",
        "teamB": "Riders",
        "status": "Completed",
        "result": "Titans won by 5 wickets",
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Matches"), centerTitle: true),
      body: ListView.builder(
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text("${match["teamA"]} vs ${match["teamB"]}"),
              subtitle: Text(
                match["status"] == "Live"
                    ? "Live • Overs: ${match["overs"]}"
                    : match["status"] == "Upcoming"
                    ? "Starts at: ${match["time"]}"
                    : "Result: ${match["result"]}",
                style: TextStyle(
                  color: match["status"] == "Live"
                      ? Colors.red
                      : (match["status"] == "Upcoming" ? Colors.blue : Colors.black),
                  fontWeight: match["status"] == "Live" ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Navigate to Match Details / Live Score screen
              },
            ),
          );
        },
      ),
    );
  }
}
