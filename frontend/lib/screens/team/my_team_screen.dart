import 'package:flutter/material.dart';

class MyTeamScreen extends StatelessWidget {
  const MyTeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for captain's team
    final team = {
      "name": "Warriors",
      "trophies": 3,
      "players": [
        {
          "name": "Ali Khan",
          "role": "Batsman",
          "runs": 850,
          "avg": 42.5,
          "sr": 128.0,
          "wickets": 0,
        },
        {
          "name": "Bilal Ahmed",
          "role": "Bowler",
          "runs": 120,
          "avg": 12.0,
          "sr": 90.0,
          "wickets": 35,
        },
        {
          "name": "Zeeshan Malik",
          "role": "All-Rounder",
          "runs": 400,
          "avg": 25.0,
          "sr": 110.0,
          "wickets": 18,
        },
      ],
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Team"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Edit team info
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Team Info Section
          Card(
            margin: const EdgeInsets.all(12),
            child: ListTile(
              leading: const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.shield, color: Colors.white),
              ),
              title: Text(
                team["name"] as String,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Text("🏆 ${team["trophies"]} trophies"),
              trailing: IconButton(
                icon: const Icon(Icons.history),
                onPressed: () {
                  // TODO: Navigate to match history
                },
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Players", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),

          // Players List
          Expanded(
            child: ListView.builder(
              itemCount: (team["players"] as List).length,
              itemBuilder: (context, index) {
                final player = (team["players"] as List)[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Text(player["name"][0]),
                    ),
                    title: Text(player["name"]),
                    subtitle: Text(
                      "${player["role"]} • Runs: ${player["runs"]} • Avg: ${player["avg"]} • SR: ${player["sr"]} • Wkts: ${player["wickets"]}",
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // TODO: Edit player profile
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add new player
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
