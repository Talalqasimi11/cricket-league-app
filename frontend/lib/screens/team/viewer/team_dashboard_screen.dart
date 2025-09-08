import 'package:flutter/material.dart';
import '../../player/viewer/player_dashboard_screen.dart';
import '../../../widgets/bottom_nav.dart';

class TeamDashboardScreen extends StatelessWidget {
  final String teamName;
  final String imageUrl;
  final int trophies;

  const TeamDashboardScreen({
    super.key,
    required this.teamName,
    required this.imageUrl,
    required this.trophies,
  });

  @override
  Widget build(BuildContext context) {
    // sample players list (viewer)
    final players = [
      {
        "name": "Arjun Sharma",
        "role": "Captain",
        "image": "https://via.placeholder.com/150",
        "runs": 980,
        "avg": 34.2,
        "sr": 115.5,
        "wickets": 12,
      },
      {
        "name": "Rohan Verma",
        "role": "Batsman",
        "image": "https://via.placeholder.com/150",
        "runs": 720,
        "avg": 28.8,
        "sr": 108.7,
        "wickets": 4,
      },
      {
        "name": "Karan Patel",
        "role": "Bowler",
        "image": "https://via.placeholder.com/150",
        "runs": 240,
        "avg": 12.6,
        "sr": 60.2,
        "wickets": 34,
      },
      {
        "name": "Vikram Singh",
        "role": "All-rounder",
        "image": "https://via.placeholder.com/150",
        "runs": 430,
        "avg": 25.3,
        "sr": 95.1,
        "wickets": 18,
      },
      {
        "name": "Siddharth Kapoor",
        "role": "Wicketkeeper",
        "image": "https://via.placeholder.com/150",
        "runs": 330,
        "avg": 22.0,
        "sr": 92.4,
        "wickets": 2,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF122118),
      appBar: AppBar(
        backgroundColor: const Color(0xFF122118),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Team Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Team header
              Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(radius: 56, backgroundImage: NetworkImage(imageUrl)),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF122118),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield, color: Color(0xFF20DF6C), size: 22),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    teamName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$trophies Trophies', style: const TextStyle(color: Color(0xFF95C6A9))),
                ],
              ),
              const SizedBox(height: 20),

              // Players title
              Row(
                children: const [
                  Text(
                    'Players',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Player list
              Column(
                children: players.map((p) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a2c22),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlayerDashboardScreen(
                              playerName: p['name'] as String,
                              role: p['role'] as String,
                              teamName: teamName,
                              imageUrl: p['image'] as String,
                              runs: p['runs'] as int,
                              battingAvg: (p['avg'] as num).toDouble(),
                              strikeRate: (p['sr'] as num).toDouble(),
                              wickets: p['wickets'] as int,
                            ),
                          ),
                        );
                      },
                      leading: CircleAvatar(backgroundImage: NetworkImage(p['image'] as String)),
                      title: Text(p['name'] as String, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                        p['role'] as String,
                        style: const TextStyle(color: Color(0xFF95C6A9)),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),
              // Start match button (viewer should not start — but placed visually as in HTML)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF20DF6C),
                    foregroundColor: const Color(0xFF122118),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // viewer flow: show info snackbar (can't start)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Only the captain can start a match')),
                    );
                  },
                  icon: const Icon(Icons.sports_cricket),
                  label: const Text('Start Match', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (i) {
          // keep local behaviour: pop on Home tap
          if (i == 0) Navigator.popUntil(context, (route) => route.isFirst);
        },
        backgroundColor: const Color(0xFF1B3224),
        selectedColor: const Color(0xFF20DF6C),
        unselectedColor: const Color(0xFF95C6A9),
      ),
    );
  }
}
