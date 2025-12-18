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

  // -------- Helpers: parsing and formatting --------

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  // [Fixed] Removed unused helper '_toDouble'

  String _fmt(num n, {int digits = 1}) => n.toStringAsFixed(digits);

  // overs like "3.5" => total balls (3 overs, 5 balls) = 23
  int _oversStringToBalls(String s) {
    if (s.isEmpty) return 0;
    final parts = s.split('.');
    final o = int.tryParse(parts[0]) ?? 0;
    final b = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final balls = b.clamp(0, 5);
    return (o * 6) + balls;
  }

  // total balls => "O.B" format, e.g., 23 => "3.5"
  String _ballsToOversString(int totalBalls) {
    if (totalBalls <= 0) return '0.0';
    final o = totalBalls ~/ 6;
    final b = totalBalls % 6;
    return '$o.$b';
  }

  // -------- Build rows with totals --------

  List<List<String>> _buildBattingRows(List<Map<String, dynamic>> batting) {
    final List<List<String>> rows = [];
    int tRuns = 0, tBalls = 0, tFours = 0, tSixes = 0;

    for (final p in batting) {
      final name = p['name']?.toString() ?? '';
      final runs = _toInt(p['runs']);
      final balls = _toInt(p['balls']);
      final fours = _toInt(p['fours']);
      final sixes = _toInt(p['sixes']);
      final givenSr = p['sr']?.toString();
      final sr = (givenSr != null && givenSr.isNotEmpty)
          ? givenSr
          : (balls > 0 ? _fmt((runs * 100) / balls, digits: 1) : '0.0');

      tRuns += runs;
      tBalls += balls;
      tFours += fours;
      tSixes += sixes;

      rows.add([
        name,
        runs.toString(),
        balls.toString(),
        fours.toString(),
        sixes.toString(),
        sr,
      ]);
    }

    // Totals row
    final teamSr = tBalls > 0 ? _fmt((tRuns * 100) / tBalls, digits: 1) : '0.0';
    rows.add([
      'TOTAL',
      tRuns.toString(),
      tBalls.toString(),
      tFours.toString(),
      tSixes.toString(),
      teamSr,
    ]);

    return rows;
  }

  List<List<String>> _buildBowlingRows(List<Map<String, dynamic>> bowling) {
    final List<List<String>> rows = [];
    int tBalls = 0, tMaidens = 0, tRuns = 0, tWkts = 0;

    for (final p in bowling) {
      final name = p['name']?.toString() ?? '';
      final oversStr = p['overs']?.toString() ?? '0.0';
      final maidens = _toInt(p['maidens']);
      final runs = _toInt(p['runs']);
      final wkts = _toInt(p['wickets']);

      // econ: prefer given, else compute from runs / overs
      String econStr;
      final givenEcon = p['econ']?.toString();
      if (givenEcon != null && givenEcon.isNotEmpty) {
        econStr = givenEcon;
      } else {
        final balls = _oversStringToBalls(oversStr);
        econStr = balls > 0 ? _fmt(runs / (balls / 6.0), digits: 1) : '0.0';
      }

      tBalls += _oversStringToBalls(oversStr);
      tMaidens += maidens;
      tRuns += runs;
      tWkts += wkts;

      rows.add([
        name,
        oversStr,
        maidens.toString(),
        runs.toString(),
        wkts.toString(),
        econStr,
      ]);
    }

    // Totals row
    final tOversStr = _ballsToOversString(tBalls);
    final tEcon = tBalls > 0 ? _fmt(tRuns / (tBalls / 6.0), digits: 1) : '0.0';
    rows.add([
      'TOTAL',
      tOversStr,
      tMaidens.toString(),
      tRuns.toString(),
      tWkts.toString(),
      tEcon,
    ]);

    return rows;
  }

  // -------- Styled DataTable builder --------

  Widget _buildTable(
    String title,
    List<String> headers,
    List<List<String>> rows,
  ) {
    final isEmpty = rows.isEmpty;

    final List<List<String>> displayRows = isEmpty
        ? const [
            ["No data", "-", "-", "-", "-", "-"],
          ]
        : rows;

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
            headingRowColor: WidgetStateProperty.resolveWith(
              (states) => const Color(0xFF22352A),
            ),
            dataRowMinHeight: 40,
            dataRowMaxHeight: 44,
            columnSpacing: 18,
            horizontalMargin: 12,
            dividerThickness: 0.6,
            headingTextStyle:
                const TextStyle(color: Colors.grey, fontSize: 12),
            dataTextStyle:
                const TextStyle(color: Colors.white, fontSize: 13),
            columns: headers
                .map(
                  (h) => DataColumn(
                    label: Text(h),
                  ),
                )
                .toList(),
            rows: displayRows
                .map(
                  (row) {
                    final isTotalRow =
                        row.isNotEmpty && row.first.toUpperCase() == 'TOTAL';
                    return DataRow(
                      color: isTotalRow
                          ? WidgetStateProperty.resolveWith(
                              // [Fixed] Replaced deprecated withOpacity
                              (states) => Colors.white.withValues(alpha: 0.04),
                            )
                          : null,
                      cells: row
                          .map(
                            (cell) => DataCell(
                              Center(child: Text(cell.toString())),
                            ),
                          )
                          .toList(),
                    );
                  },
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // -------- Team card --------

  Widget _teamStatsCard(
    String teamName,
    List<Map<String, dynamic>> batting,
    List<Map<String, dynamic>> bowling,
  ) {
    final battingRows = _buildBattingRows(batting);
    final bowlingRows = _buildBowlingRows(bowling);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2C22),
        borderRadius: BorderRadius.circular(12),
        // [Fixed] Replaced deprecated withOpacity
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Team header
          Row(
            children: [
              const Icon(Icons.flag, color: Color(0xFF38e07b), size: 18),
              const SizedBox(width: 6),
              Text(
                teamName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Batting Table
          _buildTable(
            "Batting",
            const ["Player", "R", "B", "4s", "6s", "SR"],
            battingRows,
          ),

          // Bowling Table
          _buildTable(
            "Bowling",
            const ["Player", "O", "M", "R", "W", "Econ"],
            bowlingRows,
          ),
        ],
      ),
    );
  }

  // -------- Screen --------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.green[700],
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
            _teamStatsCard(teamA, teamABatting, teamABowling),
            const SizedBox(height: 20),
            _teamStatsCard(teamB, teamBBatting, teamBBowling),
          ],
        ),
      ),
    );
  }
}