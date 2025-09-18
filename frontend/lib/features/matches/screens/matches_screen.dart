// lib/features/matches/screens/matches_screen.dart
import 'package:flutter/material.dart';
import 'create_match_screen.dart';
import 'live_match_view_screen.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2D2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2D2A),
        elevation: 0,
        title: const Text(
          "Matches",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications, color: Colors.white),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMatchCard(
            context,
            teamA: "Panthers",
            teamB: "Eagles",
            dateTime: "15 June 2024, 10:00 AM",
            status: "Live",
            statusColor: Colors.red,
          ),
          _buildMatchCard(
            context,
            teamA: "Warriors",
            teamB: "Titans",
            dateTime: "20 June 2024, 02:00 PM",
            status: "Upcoming",
            statusColor: Colors.grey,
          ),
          _buildMatchCard(
            context,
            teamA: "Strikers",
            teamB: "Knights",
            dateTime: "10 June 2024, 09:00 AM",
            status: "Completed",
            statusColor: Colors.green,
          ),
        ],
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60), // above navbar
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF36e27b),
            foregroundColor: const Color(0xFF122118),
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            // ✅ Navigate to Create Match Screen
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateMatchScreen()));
          },
          child: const Text(
            "Create Match",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCard(
    BuildContext context, {
    required String teamA,
    required String teamB,
    required String dateTime,
    required String status,
    required Color statusColor,
  }) {
    return GestureDetector(
      onTap: () {
        if (status == "Live") {
          // ✅ Navigate to Live Match View with static match data
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LiveMatchViewScreen(
                teamA: teamA,
                teamB: teamB,
                overs: "20", // default overs (you can customize per match)
                score: "0/0",
                currentOvers: "0.0",
                ballByBall: <Map<String, String>>[],
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C4A44),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF1A2D2A),
                  child: Icon(Icons.sports_cricket, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$teamA vs $teamB",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    Text(dateTime, style: const TextStyle(color: Color(0xFF95c6a9), fontSize: 12)),
                  ],
                ),
              ],
            ),
            Text(
              status,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
