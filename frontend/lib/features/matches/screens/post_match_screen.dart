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

    // Ensure we always have screens to display to avoid index errors.
    final List<Widget> screens = [
      _ScorecardTab(teamA: widget.teamA, teamB: widget.teamB),
      _StatsTab(teamA: widget.teamA, teamB: widget.teamB),
    ];

    // Clamp index to valid range just in case.
    final int effectiveIndex =
        (_selectedIndex >= 0 && _selectedIndex < screens.length)
        ? _selectedIndex
        : 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.green[700],
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
          Expanded(child: screens[effectiveIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: effectiveIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF38e07b),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.scoreboard),
            label: "Scorecard",
          ),
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
        color: color.withValues(alpha: 0.1),
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
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorecardTab extends StatelessWidget {
  final String teamA;
  final String teamB;
  const _ScorecardTab({required this.teamA, required this.teamB});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.scoreboard, color: Colors.white70, size: 48),
          const SizedBox(height: 12),
          Text(
            'Scorecard',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$teamA vs $teamB',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  final String teamA;
  final String teamB;
  const _StatsTab({required this.teamA, required this.teamB});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.bar_chart, color: Colors.white70, size: 48),
          const SizedBox(height: 12),
          Text(
            'Match Stats',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$teamA vs $teamB',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
