import 'package:flutter/material.dart';

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
      messageColor = Colors.greenAccent.shade700;
    } else {
      message = "You are not a registered user, your data will not be saved.";
      messageColor = Colors.redAccent.shade700;
    }

    // Tabs: Scorecard + Stats
    final List<Widget> screens = [
      _ScorecardTab(
        teamA: widget.teamA,
        teamB: widget.teamB,
        teamABatting: widget.teamABatting,
        teamABowling: widget.teamABowling,
        teamBBatting: widget.teamBBatting,
        teamBBowling: widget.teamBBowling,
      ),
      _StatsTab(
        teamA: widget.teamA,
        teamB: widget.teamB,
        teamABatting: widget.teamABatting,
        teamABowling: widget.teamABowling,
        teamBBatting: widget.teamBBatting,
        teamBBowling: widget.teamBBowling,
      ),
    ];

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
          const SizedBox(height: 16),
          _buildMessage(message, messageColor),
          const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), // FIXED: withOpacity -> withValues
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            color == Colors.redAccent ? Icons.warning : Icons.check_circle,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 14,
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
  final List<Map<String, dynamic>> teamABatting;
  final List<Map<String, dynamic>> teamABowling;
  final List<Map<String, dynamic>> teamBBatting;
  final List<Map<String, dynamic>> teamBBowling;

  const _ScorecardTab({
    required this.teamA,
    required this.teamB,
    required this.teamABatting,
    required this.teamABowling,
    required this.teamBBatting,
    required this.teamBBowling,
  });

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  String _sr(dynamic runs, dynamic balls) {
    final r = _toInt(runs);
    final b = _toInt(balls);
    if (b <= 0) return '0.0';
    return ((r * 100) / b).toStringAsFixed(1);
  }

  String _econ(dynamic runs, dynamic overs) {
    final r = _toInt(runs);
    final oStr = overs?.toString() ?? '0';
    final parts = oStr.split('.');
    final o = int.tryParse(parts[0]) ?? 0;
    final b = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final balls = (o * 6) + b.clamp(0, 5);
    if (balls <= 0) return '0.0';
    return (r / (balls / 6.0)).toStringAsFixed(1);
  }

  Widget _buildTable(
    String title,
    List<String> headers,
    List<List<String>> rows, {
    bool showEmptyMessage = true,
  }) {
    final hasRows = rows.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2C22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)), // FIXED
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF38e07b),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (!hasRows && showEmptyMessage)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "No data",
                style: TextStyle(color: Colors.white70),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.resolveWith( // FIXED: MaterialStateProperty -> WidgetStateProperty
                  (states) => const Color(0xFF22352A),
                ),
                columnSpacing: 18,
                horizontalMargin: 12,
                headingTextStyle:
                    const TextStyle(color: Colors.grey, fontSize: 12),
                dataTextStyle:
                    const TextStyle(color: Colors.white, fontSize: 13),
                columns:
                    headers.map((h) => DataColumn(label: Text(h))).toList(),
                rows: rows
                    .map(
                      (row) => DataRow(
                        cells: row
                            .map((cell) =>
                                DataCell(Center(child: Text(cell))))
                            .toList(),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  List<List<String>> _battingRows(List<Map<String, dynamic>> list) {
    return list.map((p) {
      final name = p['name']?.toString() ?? '';
      final runs = _toInt(p['runs']).toString();
      final balls = _toInt(p['balls']).toString();
      final fours = _toInt(p['fours']).toString();
      final sixes = _toInt(p['sixes']).toString();
      final sr = p['sr']?.toString().isNotEmpty == true // FIXED: removed second ?.
          ? p['sr'].toString()
          : _sr(p['runs'], p['balls']);
      return [name, runs, balls, fours, sixes, sr];
    }).toList();
  }

  List<List<String>> _bowlingRows(List<Map<String, dynamic>> list) {
    return list.map((p) {
      final name = p['name']?.toString() ?? '';
      final overs = p['overs']?.toString() ?? '0';
      final maidens = _toInt(p['maidens']).toString();
      final runs = _toInt(p['runs']).toString();
      final wickets = _toInt(p['wickets']).toString();
      final econStr = p['econ']?.toString().isNotEmpty == true // FIXED: removed second ?.
          ? p['econ'].toString()
          : _econ(p['runs'], p['overs']);
      return [name, overs, maidens, runs, wickets, econStr];
    }).toList();
  }

  Widget _teamScorecard(
    String title, {
    required List<Map<String, dynamic>> batting,
    required List<Map<String, dynamic>> bowlingOpposition,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)), // FIXED
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
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Batting
          _buildTable(
            "Batting",
            const ["Player", "R", "B", "4s", "6s", "SR"],
            _battingRows(batting),
          ),

          // Bowling (opposition)
          _buildTable(
            "Bowling (Opposition)",
            const ["Player", "O", "M", "R", "W", "Econ"],
            _bowlingRows(bowlingOpposition),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            _teamScorecard(
              teamA,
              batting: teamABatting,
              bowlingOpposition: teamBBowling,
            ),
            _teamScorecard(
              teamB,
              batting: teamBBatting,
              bowlingOpposition: teamABowling,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  final String teamA;
  final String teamB;
  final List<Map<String, dynamic>> teamABatting;
  final List<Map<String, dynamic>> teamABowling;
  final List<Map<String, dynamic>> teamBBatting;
  final List<Map<String, dynamic>> teamBBowling;

  const _StatsTab({
    required this.teamA,
    required this.teamB,
    required this.teamABatting,
    required this.teamABowling,
    required this.teamBBatting,
    required this.teamBBowling,
  });

  // ---------- Helpers ----------
  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  // REMOVED: Unused _toDouble method

  String _fmt(num n, {int digits = 1}) => n.toStringAsFixed(digits);

  int _oversStringToBalls(String s) {
    if (s.isEmpty) return 0;
    final parts = s.split('.');
    final o = int.tryParse(parts[0]) ?? 0;
    final b = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final balls = b.clamp(0, 5);
    return (o * 6) + balls;
  }

  String _ballsToOversString(int totalBalls) {
    if (totalBalls <= 0) return '0.0';
    final o = totalBalls ~/ 6;
    final b = totalBalls % 6;
    return '$o.$b';
  }

  // ---------- Tables with totals ----------
  List<List<String>> _buildBattingRows(List<Map<String, dynamic>> batting) {
    final rows = <List<String>>[];
    int tRuns = 0, tBalls = 0, tFours = 0, tSixes = 0;

    for (final p in batting) {
      final name = p['name']?.toString() ?? '';
      final runs = _toInt(p['runs']);
      final balls = _toInt(p['balls']);
      final fours = _toInt(p['fours']);
      final sixes = _toInt(p['sixes']);
      final sr = p['sr']?.toString().isNotEmpty == true // FIXED: removed second ?.
          ? p['sr'].toString()
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
    final rows = <List<String>>[];
    int tBalls = 0, tMaidens = 0, tRuns = 0, tWkts = 0;

    for (final p in bowling) {
      final name = p['name']?.toString() ?? '';
      final oversStr = p['overs']?.toString() ?? '0.0';
      final maidens = _toInt(p['maidens']);
      final runs = _toInt(p['runs']);
      final wkts = _toInt(p['wickets']);

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

  Widget _buildTable(
    String title,
    List<String> headers,
    List<List<String>> rows,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2C22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)), // FIXED
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF38e07b),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.resolveWith( // FIXED: MaterialStateProperty -> WidgetStateProperty
                (states) => const Color(0xFF22352A),
              ),
              columnSpacing: 18,
              horizontalMargin: 12,
              dividerThickness: 0.6,
              headingTextStyle:
                  const TextStyle(color: Colors.grey, fontSize: 12),
              dataTextStyle:
                  const TextStyle(color: Colors.white, fontSize: 13),
              columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
              rows: rows
                  .map(
                    (row) {
                      final isTotal =
                          row.isNotEmpty && row.first.toUpperCase() == 'TOTAL';
                      return DataRow(
                        color: isTotal
                            ? WidgetStateProperty.resolveWith( // FIXED: MaterialStateProperty -> WidgetStateProperty
                                (states) =>
                                    Colors.white.withValues(alpha: 0.04), // FIXED
                              )
                            : null,
                        cells: row
                            .map((cell) =>
                                DataCell(Center(child: Text(cell))))
                            .toList(),
                      );
                    },
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamStatsCard(
    String teamName,
    List<Map<String, dynamic>> batting,
    List<Map<String, dynamic>> bowling,
  ) {
    final battingRows = _buildBattingRows(batting);
    final bowlingRows = _buildBowlingRows(bowling);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)), // FIXED
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
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          _buildTable(
            "Batting (with totals)",
            const ["Player", "R", "B", "4s", "6s", "SR"],
            battingRows,
          ),

          _buildTable(
            "Bowling (with totals)",
            const ["Player", "O", "M", "R", "W", "Econ"],
            bowlingRows,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            _teamStatsCard(teamA, teamABatting, teamABowling),
            _teamStatsCard(teamB, teamBBatting, teamBBowling),
          ],
        ),
      ),
    );
  }
}