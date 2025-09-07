import 'package:flutter/material.dart';

class TeamDetailsScreen extends StatelessWidget {
  final String teamName;

  const TeamDetailsScreen({super.key, required this.teamName});

  @override
  Widget build(BuildContext context) {
    // Dummy players for now
    final players = ["Ali Khan", "Ahmed Raza", "Bilal Ahmed", "Fahad Hussain", "Zeeshan Malik"];

    return Scaffold(
      appBar: AppBar(title: Text(teamName)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text("Players", style: Theme.of(context).textTheme.titleLarge),
          ),

          // Player list
          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(player[0]), // first letter
                    ),
                    title: Text(player),
                    subtitle: const Text("Role: All-rounder"), // later from DB
                    trailing: IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () {
                        // TODO: Navigate to player profile screen
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
