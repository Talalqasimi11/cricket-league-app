import 'package:flutter/material.dart';
// import 'scorecard_screen.dart';
// import 'match_statistics_screen.dart';

class PostMatchScreen extends StatefulWidget {
  final String teamA;
  final String teamB;
  final List<Map<String, dynamic>> teamABatting;
  final List<Map<String, dynamic>> teamABowling;
  final List<Map<String, dynamic>> teamBBatting;
  final List<Map<String, dynamic>> teamBBowling;

  /// User type flags
  final bool isCaptain;
  final bool isRegisteredTeam;

  const PostMatchScreen({
    super.key,
    required this.teamA,
    required this.teamB,
    required this.teamABatting,
    required this.teamABowling,
    required this.teamBBatting,
    required this.teamBBowling,
    this.isCaptain = false,
    this.isRegisteredTeam = false,
  });

  @override
  State<PostMatchScreen> createState() => _PostMatchScreenState();
}

class _PostMatchScreenState extends State<PostMatchScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    String message;
    Color messageColor;

    if (widget.isCaptain && widget.isRegisteredTeam) {
      message = "Your player stats are added to the team stats.";
      messageColor = Colors.greenAccent;
    } else {
      message = "You are not a registered user, your data will not be saved.";
      messageColor = Colors.redAccent;
    }

    final List<Widget> _screens = [
      // ScorecardScreen(teamA: widget.teamA, teamB: widget.teamB),
      // MatchStatisticsScreen(
      //   teamA: widget.teamA,
      //   teamB: widget.teamB,
      //   teamABatting: widget.teamABatting,
      //   teamABowling: widget.teamABowling,
      //   teamBBatting: widget.teamBBatting,
      //   teamBBowling: widget.teamBBowling,
      // ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF122118),
      appBar: AppBar(
        backgroundColor: const Color(0xFF122118),
        title: const Text(
          "Post-Match Summary",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildMessage(message, messageColor),
          const SizedBox(height: 20),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: const Color(0xFF1A2C22),
        selectedItemColor: const Color(0xFF38e07b),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.scoreboard), label: "Scorecard"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Stats"),
        ],
      ),
    );
  }

  Widget _buildMessage(String message, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            color == Colors.redAccent ? Icons.warning : Icons.check_circle,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
