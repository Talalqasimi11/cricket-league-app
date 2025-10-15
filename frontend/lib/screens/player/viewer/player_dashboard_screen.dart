import 'package:flutter/material.dart';
import '../../../widgets/bottom_nav.dart';

class PlayerDashboardScreen extends StatelessWidget {
  final String playerName;
  final String role;
  final String teamName;
  final String imageUrl;
  final int runs;
  final double battingAvg;
  final double strikeRate;
  final int wickets;

  const PlayerDashboardScreen({
    super.key,
    required this.playerName,
    required this.role,
    required this.teamName,
    required this.imageUrl,
    required this.runs,
    required this.battingAvg,
    required this.strikeRate,
    required this.wickets,
  });

  Widget _statCard(
    IconData icon,
    String label,
    String value,
    Color primary,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: primary.withValues(alpha: 0.12),
            radius: 26,
            child: Icon(icon, size: 30, color: primary),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF16A34A);
    const background = Color(0xFFF8FAFC);
    const textPrimary = Color(0xFF1E293B);
    const textSecondary = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.85),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Player Dashboard',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          children: [
            CircleAvatar(radius: 64, backgroundImage: NetworkImage(imageUrl)),
            const SizedBox(height: 12),
            Text(
              playerName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text('$role • $teamName', style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 20),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: [
                _statCard(
                  Icons.sports_cricket,
                  'Runs',
                  runs.toString(),
                  primary,
                  textPrimary,
                  textSecondary,
                ),
                _statCard(
                  Icons.leaderboard,
                  'Batting Avg',
                  battingAvg.toStringAsFixed(2),
                  primary,
                  textPrimary,
                  textSecondary,
                ),
                _statCard(
                  Icons.trending_up,
                  'Strike Rate',
                  strikeRate.toStringAsFixed(2),
                  primary,
                  textPrimary,
                  textSecondary,
                ),
                _statCard(
                  Icons.sports_cricket_sharp,
                  'Wickets',
                  wickets.toString(),
                  primary,
                  textPrimary,
                  textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
        onTap: (i) {
          if (i == 0) Navigator.popUntil(context, (r) => r.isFirst);
          // other tabs: placeholder actions or navigation to those tabs
        },
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        selectedColor: primary,
        unselectedColor: textSecondary,
      ),
    );
  }
}
