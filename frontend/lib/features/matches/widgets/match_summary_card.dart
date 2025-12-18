import 'package:flutter/material.dart';

class MatchSummaryCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const MatchSummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final tournament = data['tournament'] ?? 'Tournament';
    final matchDate = _formatDate(data['match_date']);
    final teams = data['teams'] ?? {};
    final scores = data['scores'] ?? {};
    final result = data['result'] ?? '';
    final mom = data['mom'];

    return Container(
      width: 350, // Fixed width for consistent image generation
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black45)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Text(
            tournament.toString().toUpperCase(),
            style: const TextStyle(
              color: Colors.white54,
              letterSpacing: 2,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            matchDate,
            style: const TextStyle(color: Colors.white30, fontSize: 10),
          ),
          const SizedBox(height: 24),

          // Scores
          _buildTeamRow(teams['home'], scores['inn1'], true),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          _buildTeamRow(teams['away'], scores['inn2'], false),

          const SizedBox(height: 32),

          // Result Highlight
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.greenAccent.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              result,
              style: const TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Man of the Match
          if (mom != null) ...[
            const SizedBox(height: 24),
            const Text(
              "PLAYER OF THE MATCH",
              style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mom['name'] ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              mom['performance'] ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],

          const SizedBox(height: 24),
          // Branding
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports_cricket, color: Colors.white24, size: 16),
              SizedBox(width: 6),
              Text(
                "CricLeague",
                style: TextStyle(
                  color: Colors.white24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRow(String? name, String? score, bool isHome) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            name ?? 'Team',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          score ?? 'Yet to bat',
          style: TextStyle(
            color: score == null ? Colors.white24 : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Monospace',
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return '';
    }
  }
}
