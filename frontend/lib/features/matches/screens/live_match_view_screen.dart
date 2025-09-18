import 'package:flutter/material.dart';

class LiveMatchViewScreen extends StatelessWidget {
  final String teamA;
  final String teamB;
  final String overs;
  final String score;
  final String currentOvers;
  final List<Map<String, String>> ballByBall;
  // ✅ New field

  const LiveMatchViewScreen({
    super.key,
    required this.teamA,
    required this.teamB,
    required this.overs,
    required this.score,
    required this.currentOvers,
    required this.ballByBall,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Live Match",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🏏 Match Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1a3d27),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Match Title + Overs
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$teamA vs $teamB",
                      style: const TextStyle(
                        color: Color(0xFF36e27b),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "$overs Overs Match",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "LIVE",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                // Placeholder Team Logos
                Row(
                  children: const [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey,
                      backgroundImage: NetworkImage(
                        "https://via.placeholder.com/150/000000/FFFFFF/?text=A",
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text("vs", style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey,
                      backgroundImage: NetworkImage(
                        "https://via.placeholder.com/150/000000/FFFFFF/?text=B",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 📊 Scorecard
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1a3d27),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const Text(
                  "Batting Team",
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                // Score + Overs
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          score,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Runs / Wickets",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    Column(
                      children: [
                        Text(
                          currentOvers,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text("Overs", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 📒 Ball-by-Ball Log
          const Text(
            "Ball-by-Ball Log",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ...ballByBall.map(
            (ball) => _buildBallLog(
              over: ball["over"] ?? "",
              bowler: ball["bowler"] ?? "",
              batsman: ball["batsman"] ?? "",
              commentary: ball["commentary"] ?? "",
              result: ball["result"] ?? "",
            ),
          ),
        ],
      ),

      // 🔽 Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1a3d27),
        selectedItemColor: const Color(0xFF36e27b),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.sports_cricket), label: "Matches"),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: "Tournaments"),
          BottomNavigationBarItem(icon: Icon(Icons.query_stats), label: "Stats"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  /// 🔹 Single ball log card widget
  Widget _buildBallLog({
    required String over,
    required String bowler,
    required String batsman,
    required String commentary,
    required String result,
  }) {
    // Result-based color
    Color resultColor;
    if (result == "W") {
      resultColor = Colors.red;
    } else if (result == "6") {
      resultColor = Colors.green;
    } else if (result == "4") {
      resultColor = Colors.greenAccent;
    } else {
      resultColor = Colors.white;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1a3d27).withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Over bubble
          CircleAvatar(
            radius: 16,
            backgroundColor: result == "W" ? Colors.red.withOpacity(0.2) : const Color(0xFF1a3d27),
            child: Text(
              over,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: result == "W" ? Colors.red : Colors.green,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Commentary
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$bowler to $batsman",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                Text(commentary, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),

          // Result (runs, W, etc.)
          Text(
            result,
            style: TextStyle(fontWeight: FontWeight.bold, color: resultColor),
          ),
        ],
      ),
    );
  }
}
