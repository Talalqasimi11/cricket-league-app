import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/api_client.dart';

class ScorecardScreen extends StatefulWidget {
  final String matchId;
  const ScorecardScreen({super.key, required this.matchId});

  @override
  State<ScorecardScreen> createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends State<ScorecardScreen> {
  bool _loading = true;
  Map<String, dynamic>? matchData;
  List<dynamic>? scorecardData;

  @override
  void initState() {
    super.initState();
    _fetchScorecard();
  }

  Future<void> _fetchScorecard() async {
    setState(() => _loading = true);
    try {
      final resp = await ApiClient.instance.get(
        '/api/viewer/scorecard/${widget.matchId}',
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        matchData = data['match'] as Map<String, dynamic>?;
        scorecardData = data['scorecard'] as List<dynamic>?;
      } else {
        debugPrint('Failed to fetch scorecard: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching scorecard: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF122118),
      appBar: AppBar(
        backgroundColor: const Color(0xFF122118),
        title: const Text(
          'Match Scorecard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF36e27b)))
          : matchData == null
              ? const Center(
                  child: Text(
                    'No scorecard data available',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchScorecard,
                  color: const Color(0xFF36e27b),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildMatchSummary(),
                      const SizedBox(height: 20),
                      if (scorecardData != null && scorecardData!.isNotEmpty)
                        ...scorecardData!.map((innings) => _buildInningsCard(innings)),
                      if (scorecardData == null || scorecardData!.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'No innings data available yet',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMatchSummary() {
    final team1Name = matchData?['team1_name'] ?? 'Team 1';
    final team2Name = matchData?['team2_name'] ?? 'Team 2';
    final status = matchData?['status'] ?? 'unknown';
    final winnerName = matchData?['winner_team_name'];
    final overs = matchData?['overs'] ?? 20;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3D27), Color(0xFF122118)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF36e27b).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$team1Name vs $team2Name',
                  style: const TextStyle(
                    color: Color(0xFF36e27b),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$overs Overs Match',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (winnerName != null && status == 'completed') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF36e27b).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: Color(0xFF36e27b),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$winnerName won the match',
                      style: const TextStyle(
                        color: Color(0xFF36e27b),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (winnerName == null && status == 'completed') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.handshake,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Match Tied',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInningsCard(dynamic innings) {
    final inningNumber = innings['inning_number'] ?? 0;
    final battingTeam = innings['batting_team'] ?? 'Team';
    final bowlingTeam = innings['bowling_team'] ?? 'Team';
    final runs = innings['runs'] ?? 0;
    final wickets = innings['wickets'] ?? 0;
    final overs = innings['overs'] ?? 0;
    final battingList = innings['batting'] as List<dynamic>? ?? [];
    final bowlingList = innings['bowling'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2C22),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Innings Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Innings $inningNumber',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        battingTeam,
                        style: const TextStyle(
                          color: Color(0xFF36e27b),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$runs/$wickets',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '($overs overs)',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Batting Section
              const Text(
                'BATTING',
                style: TextStyle(
                  color: Color(0xFF36e27b),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              if (battingList.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'No batting data available',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                )
              else
                _buildBattingTable(battingList),

              const SizedBox(height: 24),

              // Bowling Section
              const Text(
                'BOWLING',
                style: TextStyle(
                  color: Color(0xFF36e27b),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              if (bowlingList.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'No bowling data available',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                )
              else
                _buildBowlingTable(bowlingList),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBattingTable(List<dynamic> battingList) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(
          const Color(0xFF264532).withOpacity(0.3),
        ),
        dataRowColor: MaterialStateProperty.all(Colors.transparent),
        headingTextStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        dataTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
        columns: const [
          DataColumn(label: Text('Player')),
          DataColumn(label: Text('R'), numeric: true),
          DataColumn(label: Text('B'), numeric: true),
          DataColumn(label: Text('4s'), numeric: true),
          DataColumn(label: Text('6s'), numeric: true),
          DataColumn(label: Text('SR'), numeric: true),
        ],
        rows: battingList.map((player) {
          final name = player['player_name'] ?? 'Unknown';
          final runs = player['runs'] ?? 0;
          final balls = player['balls_faced'] ?? 0;
          final fours = player['fours'] ?? 0;
          final sixes = player['sixes'] ?? 0;
          final strikeRate = balls > 0 ? (runs / balls * 100).toStringAsFixed(1) : '0.0';

          return DataRow(
            cells: [
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text(runs.toString())),
              DataCell(Text(balls.toString())),
              DataCell(Text(fours.toString())),
              DataCell(Text(sixes.toString())),
              DataCell(Text(strikeRate)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBowlingTable(List<dynamic> bowlingList) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(
          const Color(0xFF264532).withOpacity(0.3),
        ),
        dataRowColor: MaterialStateProperty.all(Colors.transparent),
        headingTextStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        dataTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
        columns: const [
          DataColumn(label: Text('Bowler')),
          DataColumn(label: Text('O'), numeric: true),
          DataColumn(label: Text('R'), numeric: true),
          DataColumn(label: Text('W'), numeric: true),
          DataColumn(label: Text('Econ'), numeric: true),
        ],
        rows: bowlingList.map((player) {
          final name = player['player_name'] ?? 'Unknown';
          final ballsBowled = player['balls_bowled'] ?? 0;
          final runs = player['runs_conceded'] ?? 0;
          final wickets = player['wickets'] ?? 0;

          final overs = ballsBowled ~/ 6;
          final balls = ballsBowled % 6;
          final oversStr = '$overs.$balls';

          final economy = ballsBowled > 0
              ? (runs / (ballsBowled / 6)).toStringAsFixed(2)
              : '0.00';

          return DataRow(
            cells: [
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text(oversStr)),
              DataCell(Text(runs.toString())),
              DataCell(Text(wickets.toString())),
              DataCell(Text(economy)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'live':
        return Colors.red;
      case 'completed':
        return Colors.green;
      case 'not_started':
      case 'upcoming':
        return Colors.blue;
      case 'abandoned':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
