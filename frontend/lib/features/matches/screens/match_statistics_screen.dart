import 'package:flutter/material.dart';

class MatchStatisticsScreen extends StatelessWidget {
  final String teamA;
  final String teamB;
  final List<Map<String, dynamic>> teamABatting;
  final List<Map<String, dynamic>> teamABowling;
  final List<Map<String, dynamic>> teamBBatting;
  final List<Map<String, dynamic>> teamBBowling;

  const MatchStatisticsScreen({
    super.key,
    required this.teamA,
    required this.teamB,
    required this.teamABatting,
    required this.teamABowling,
    required this.teamBBatting,
    required this.teamBBowling,
  });

  // ✅ Builds a styled data table
  Widget _buildTable(String title, List<String> headers, List<List<String>> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF38e07b),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingTextStyle: const TextStyle(color: Colors.grey, fontSize: 12),
            dataTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
            columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
            rows: rows
                .map(
                  (row) => DataRow(
                    cells: row
                        .map((cell) => DataCell(Center(child: Text(cell.toString()))))
                        .toList(),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF122118),
      appBar: AppBar(
        backgroundColor: const Color(0xFF122118),
        title: const Text(
          "Match Statistics",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Team A Section
            _teamStatsCard(
              teamA,
              teamABatting
                  .map(
                    (p) => [
                      p['name']?.toString() ?? "",
                      p['runs']?.toString() ?? "0",
                      p['balls']?.toString() ?? "0",
                      p['fours']?.toString() ?? "0",
                      p['sixes']?.toString() ?? "0",
                      p['sr']?.toString() ?? "0.0",
                    ],
                  )
                  .toList(),
              teamABowling
                  .map(
                    (p) => [
                      p['name']?.toString() ?? "",
                      p['overs']?.toString() ?? "0",
                      p['maidens']?.toString() ?? "0",
                      p['runs']?.toString() ?? "0",
                      p['wickets']?.toString() ?? "0",
                      p['econ']?.toString() ?? "0.0",
                    ],
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),

            // 🔹 Team B Section
            _teamStatsCard(
              teamB,
              teamBBatting
                  .map(
                    (p) => [
                      p['name']?.toString() ?? "",
                      p['runs']?.toString() ?? "0",
                      p['balls']?.toString() ?? "0",
                      p['fours']?.toString() ?? "0",
                      p['sixes']?.toString() ?? "0",
                      p['sr']?.toString() ?? "0.0",
                    ],
                  )
                  .toList(),
              teamBBowling
                  .map(
                    (p) => [
                      p['name']?.toString() ?? "",
                      p['overs']?.toString() ?? "0",
                      p['maidens']?.toString() ?? "0",
                      p['runs']?.toString() ?? "0",
                      p['wickets']?.toString() ?? "0",
                      p['econ']?.toString() ?? "0.0",
                    ],
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Team stats card builder
  Widget _teamStatsCard(String teamName, List<List<String>> batting, List<List<String>> bowling) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2C22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            teamName,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildTable("Batting", ["Player", "R", "B", "4s", "6s", "SR"], batting),
          _buildTable("Bowling", ["Player", "O", "M", "R", "W", "Econ"], bowling),
        ],
      ),
    );
  }
}
