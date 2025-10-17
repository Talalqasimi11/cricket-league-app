import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/api_client.dart';

class LiveMatchViewScreen extends StatefulWidget {
  final String matchId;
  const LiveMatchViewScreen({super.key, required this.matchId});

  @override
  State<LiveMatchViewScreen> createState() => _LiveMatchViewScreenState();
}

class _LiveMatchViewScreenState extends State<LiveMatchViewScreen> {
  bool _loading = true;
  String teamA = 'Team A';
  String teamB = 'Team B';
  String overs = '0';
  String score = '0/0';
  String currentOvers = '0.0';
  List<Map<String, String>> ballByBall = const [];

  @override
  void initState() {
    super.initState();
    _fetchLive();
  }

  Future<void> _fetchLive() async {
    setState(() => _loading = true);
    try {
      final resp = await ApiClient.instance.get(
        '/api/viewer/live-score/${widget.matchId}',
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final innings = (data['innings'] as List?) ?? [];
        final balls = (data['balls'] as List?) ?? [];
        // pick last innings as current if any
        if (innings.isNotEmpty) {
          final last = innings.last as Map<String, dynamic>;
          final runs = (last['runs'] ?? 0).toString();
          final wkts = (last['wickets'] ?? 0).toString();
          final ov = (last['overs'] ?? 0).toString();
          final batName = (last['batting_team_name'] ?? 'Team A').toString();
          final bowlName = (last['bowling_team_name'] ?? 'Team B').toString();
          setState(() {
            teamA = batName;
            teamB = bowlName;
            score = '$runs/$wkts';
            currentOvers = ov;
            overs = ov; // if total overs not provided, show current overs
          });
        }
        // map balls into viewer log
        final mapped = balls.map<Map<String, String>>((b) {
          final m = b as Map<String, dynamic>;
          final overNo = (m['over_number'] ?? '').toString();
          final ballNo = (m['ball_number'] ?? '').toString();
          final runs = (m['runs'] ?? '').toString();
          final wicketType = (m['wicket_type'] ?? '').toString();
          final result = wicketType.isNotEmpty ? 'W' : runs;
          final bowler = (m['bowler_name'] ?? '').toString();
          final batsman = (m['batsman_name'] ?? '').toString();
          final commentary = wicketType.isNotEmpty
              ? 'Wicket: $wicketType'
              : 'Runs: $runs';
          return {
            'over': '$overNo.$ballNo',
            'bowler': bowler,
            'batsman': batsman,
            'commentary': commentary,
            'result': result,
          };
        }).toList();
        setState(() {
          ballByBall = mapped;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load live score (${resp.statusCode})'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading live score: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
        actions: [
          IconButton(
            tooltip: 'View Scorecard',
            icon: const Icon(Icons.scoreboard, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/matches/scorecard',
                arguments: {'matchId': widget.matchId},
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 🏏 Match Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a3d27),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.2),
                    ),
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
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
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

                      // Team Logos simplified (no network fetch for web safety)
                      Row(
                        children: const [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.shield, color: Colors.white),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              "vs",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.shield, color: Colors.white),
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
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Batting Team",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
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
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            color: Colors.grey.withValues(alpha: 0.3),
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
                              const Text(
                                "Overs",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_cricket),
            label: "Matches",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: "Tournaments",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.query_stats),
            label: "Stats",
          ),
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
        color: const Color(0xFF1a3d27).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Over bubble
          CircleAvatar(
            radius: 16,
            backgroundColor: result == "W"
                ? Colors.red.withValues(alpha: 0.2)
                : const Color(0xFF1a3d27),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  commentary,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
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
