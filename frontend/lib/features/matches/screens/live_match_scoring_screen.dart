// lib/features/matches/screens/live_match_scoring_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/api_client.dart';
import '../../../core/error_handler.dart';
import '../../../core/websocket_service.dart';
import 'post_match_screen.dart';

class LiveMatchScoringScreen extends StatefulWidget {
  final String teamA;
  final String teamB;
  final String matchId;
  final int? teamAId;
  final int? teamBId;

  const LiveMatchScoringScreen({
    super.key,
    required this.teamA,
    required this.teamB,
    required this.matchId,
    this.teamAId,
    this.teamBId,
  });

  @override
  State<LiveMatchScoringScreen> createState() => _LiveMatchScoringScreenState();
}

class _LiveMatchScoringScreenState extends State<LiveMatchScoringScreen> {
  String score = "0/0";
  String overs = "0.0";
  String crr = "0.00";
  String? currentInningId;
  bool isLoading = false;
  int? teamAId;
  int? teamBId;
  int? currentBatsmanId;
  int? currentBowlerId;

  // Real data from API
  List<Map<String, dynamic>> teamAPlayers = [];
  List<Map<String, dynamic>> teamBPlayers = [];
  Map<String, dynamic>? currentInning;
  List<Map<String, dynamic>> playerStats = [];

  // Over/ball state is now authoritative from server

  final List<Map<String, String>> ballByBall = [];

  @override
  void initState() {
    super.initState();
    // Initialize team IDs from widget parameters
    teamAId = widget.teamAId;
    teamBId = widget.teamBId;
    _setupWebSocket();
    _loadMatchData();
    _loadPlayers();
  }

  @override
  void dispose() {
    WebSocketService.instance.disconnect();
    super.dispose();
  }

  void _setupWebSocket() {
    // Set up WebSocket callbacks
    WebSocketService.instance.onScoreUpdate = (data) {
      if (mounted) {
        _handleLiveUpdate(data);
      }
    };

    WebSocketService.instance.onInningsEnded = (data) {
      if (mounted) {
        _handleInningsEnded(data);
      }
    };

    WebSocketService.instance.onConnected = () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connected to live scoring'),
            backgroundColor: Colors.green,
          ),
        );
      }
    };

    WebSocketService.instance.onDisconnected = () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disconnected from live scoring'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    };

    WebSocketService.instance.onError = (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('WebSocket error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    };

    // Connect to WebSocket
    WebSocketService.instance.connect(widget.matchId);
  }

  void _handleLiveUpdate(Map<String, dynamic> data) {
    try {
      // Update innings data
      if (data['inning'] != null) {
        final inning = data['inning'] as Map<String, dynamic>;
        final runs = (inning['runs'] ?? 0).toString();
        final wkts = (inning['wickets'] ?? 0).toString();
        final ov = (inning['overs'] ?? 0).toString();

        setState(() {
          score = '$runs/$wkts';
          overs = ov;
          // Compute CRR from runs and overs
          final runsInt = int.tryParse(runs) ?? 0;
          final oversDecimal = double.tryParse(ov) ?? 0.0;
          crr = oversDecimal > 0
              ? (runsInt / oversDecimal).toStringAsFixed(2)
              : '0.00';
        });
      }

      // Update ball-by-ball data
      if (data['allBalls'] != null) {
        final balls = data['allBalls'] as List?;
        if (balls != null) {
        final mapped = balls.map<Map<String, String>>((b) {
          final m = b as Map<String, dynamic>?;
          if (m == null) return {};
          final overNo = (m['over_number'] ?? '').toString();
          final ballNo = (m['ball_number'] ?? '').toString();
          final runs = (m['runs'] ?? '').toString();
          final wicketType = (m['wicket_type'] ?? '').toString();
          final extras = (m['extras'] as String?) ?? '';

            // Build display over with extras suffix
            String overDisplay = '$overNo.$ballNo';
            if (extras == 'wide') {
              overDisplay += 'wd';
            } else if (extras == 'no-ball') {
              overDisplay += 'nb';
            } else if (extras == 'bye') {
              overDisplay += 'b';
            } else if (extras == 'leg-bye') {
              overDisplay += 'lb';
            }

            final result = wicketType.isNotEmpty ? 'W' : runs;
            final bowler = (m['bowler_name'] ?? '').toString();
            final batsman = (m['batsman_name'] ?? '').toString();

            String commentary;
            if (wicketType.isNotEmpty) {
              commentary = 'Wicket: $wicketType';
            } else if (extras == 'wide') {
              commentary = 'Wide + $runs runs';
            } else if (extras == 'no-ball') {
              commentary = 'No ball + $runs runs';
            } else if (extras == 'bye') {
              commentary = 'Byes: $runs';
            } else if (extras == 'leg-bye') {
              commentary = 'Leg byes: $runs';
            } else {
              commentary = 'Runs: $runs';
            }

            return {
              'over': overDisplay,
              'bowler': bowler,
              'batsman': batsman,
              'commentary': commentary,
              'result': result,
              'extras': extras,
            };
          }).toList();

          setState(() {
            ballByBall.clear();
            ballByBall.addAll(mapped);
          });
        }
      }
    } catch (e) {
      debugPrint('Error handling live update: $e');
    }
  }

  void _handleInningsEnded(Map<String, dynamic> data) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Innings ended'),
        duration: Duration(seconds: 3),
      ),
    );
    _loadMatchData(); // Refresh all data
  }

  Future<void> _loadPlayers() async {
    if (teamAId == null || teamBId == null) return;

    try {
      // Load team A players
      final teamAResponse = await ApiClient.instance.get('/api/teams/$teamAId');
      if (teamAResponse.statusCode == 200) {
        final teamAData = jsonDecode(teamAResponse.body);
        // Assuming the response has a players array
        setState(() {
          teamAPlayers =
              (teamAData['players'] as List?)
                  ?.map((p) => p as Map<String, dynamic>)
                  .toList() ??
              [];
        });
      }

      // Load team B players
      final teamBResponse = await ApiClient.instance.get('/api/teams/$teamBId');
      if (teamBResponse.statusCode == 200) {
        final teamBData = jsonDecode(teamBResponse.body);
        setState(() {
          teamBPlayers =
              (teamBData['players'] as List?)
                  ?.map((p) => p as Map<String, dynamic>)
                  .toList() ??
              [];
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _loadMatchData() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiClient.instance.get(
        '/api/live/${widget.matchId}',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Extract team IDs from match data if not already set
        if (teamAId == null && data['team1_id'] != null) {
          teamAId = data['team1_id'] as int;
        }
        if (teamBId == null && data['team2_id'] != null) {
          teamBId = data['team2_id'] as int;
        }

        final innings = data['innings'] as List?;
        if (innings != null && innings.isNotEmpty) {
          final lastInning = innings.last as Map<String, dynamic>;
          setState(() {
            currentInningId = lastInning['id'].toString();
            currentInning = lastInning;
            score = '${lastInning['runs']}/${lastInning['wickets']}';
            overs = lastInning['overs'].toString();
          });
        }
      } else {
        throw response;
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _startInnings() async {
    if (currentInningId != null) return; // Innings already started

    // Validate team IDs are available
    if (teamAId == null || teamBId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Team information not available. Please refresh and try again.',
          ),
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await ApiClient.instance.post(
        '/api/live/start-innings',
        body: {
          'match_id': widget.matchId,
          'batting_team_id': teamAId,
          'bowling_team_id': teamBId,
          'inning_number': 1,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          currentInningId = data['inning_id']?.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Innings started successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting innings: $e')));
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addBall({
    required int runs,
    String? extras,
    String? wicketType,
    int? outPlayerId,
  }) async {
    if (currentInningId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please start innings first')),
      );
      return;
    }

    if (currentBatsmanId == null || currentBowlerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select batsman and bowler before scoring'),
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await ApiClient.instance.post(
        '/api/live/ball',
        body: {
          'match_id': widget.matchId,
          'inning_id': currentInningId,
          'batsman_id': currentBatsmanId,
          'bowler_id': currentBowlerId,
          'runs': runs,
          'extras': extras,
          'wicket_type': wicketType,
          'out_player_id': outPlayerId,
        },
      );

      if (response.statusCode == 200) {
        await _loadMatchData(); // Refresh data to get updated over/ball from server
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding ball: $e')));
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _endInnings() async {
    if (currentInningId == null) return;

    setState(() => isLoading = true);
    try {
      final response = await ApiClient.instance.post(
        '/api/live/end-innings',
        body: {'inning_id': currentInningId},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Innings ended successfully')),
        );
        setState(() {
          currentInningId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error ending innings: $e')));
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "${widget.teamA} vs ${widget.teamB}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          // 🔹 Score Summary
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2C22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$score ($overs)",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "CRR: $crr",
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text(
                      "Partnership",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      "45 (23)",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 🔹 Batters + Bowler + Ball by Ball
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _battersCard(),
                const SizedBox(height: 12),
                _bowlerCard(),
                const SizedBox(height: 12),
                _ballByBallFeed(),
              ],
            ),
          ),
        ],
      ),

      // 🔹 Bottom Controls
      bottomNavigationBar: _bottomControls(),
    );
  }

  Widget _battersCard() {
    // Find current batsmen from player stats
    final currentBatsmen = playerStats
        .where(
          (p) =>
              p['player_id'] == currentBatsmanId ||
              (currentBatsmanId != null &&
                  p['player_id'] != currentBatsmanId), // Show top 2 batsmen
        )
        .take(2)
        .toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2C22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Batters",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          if (currentBatsmen.isEmpty)
            const Text(
              "No batsman data available",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            )
          else
            ...currentBatsmen.map((batter) {
              final name = (batter['player_name'] as String?) ?? 'Unknown';
              final isOnStrike = batter['player_id'] == currentBatsmanId;
              final displayName = isOnStrike ? '$name*' : name;
              final runs = (batter['runs'] ?? 0).toString();
              final balls = (batter['balls_faced'] ?? 0).toString();
              // Calculate fours and sixes from runs (simplified)
              final fours = ((batter['runs'] ?? 0) ~/ 4).toString();
              final sixes = ((batter['runs'] ?? 0) ~/ 6).toString();
              return _batterRow(displayName, runs, balls, fours, sixes);
            }),
        ],
      ),
    );
  }

  Widget _batterRow(
    String name,
    String runs,
    String balls,
    String fours,
    String sixes,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name, style: const TextStyle(color: Colors.white)),
        Row(
          children: [
            Text("$runs ($balls)", style: const TextStyle(color: Colors.white)),
            const SizedBox(width: 8),
            Text("4s: $fours", style: const TextStyle(color: Colors.white70)),
            const SizedBox(width: 8),
            Text("6s: $sixes", style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ],
    );
  }

  Widget _bowlerCard() {
    // Find current bowler from player stats
    final currentBowler = playerStats.firstWhere(
      (p) => p['player_id'] == currentBowlerId,
      orElse: () => <String, dynamic>{},
    );

    final bowlerName =
        (currentBowler['player_name'] as String?) ?? 'Unknown Bowler';
    final overs = (currentBowler['balls_bowled'] ?? 0) / 6.0;
    final maidens = '0'; // Not tracked in current schema
    final runs = (currentBowler['runs_conceded'] ?? 0).toString();
    final wickets = (currentBowler['wickets'] ?? 0).toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2C22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            bowlerName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            "O: ${overs.toStringAsFixed(1)}  M: $maidens  R: $runs  W: $wickets",
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _ballByBallFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ball by Ball",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...ballByBall.map((ball) {
          final overStr = ball["over"] ?? "";
          final hasWide = overStr.contains('wd');
          final hasNoBall = overStr.contains('nb');
          final hasBye = overStr.contains('b') && !overStr.contains('nb');
          final hasLegBye = overStr.contains('lb');
          final hasExtras = hasWide || hasNoBall || hasBye || hasLegBye;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2C22),
              borderRadius: BorderRadius.circular(12),
              // Add border for extras
              border: hasExtras
                  ? Border.all(
                      color: Colors.orange.withValues(alpha: 0.5),
                      width: 1.5,
                    )
                  : null,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: ball["result"] == "W"
                      ? Colors.red.withValues(alpha: 0.2)
                      : hasExtras
                      ? Colors.orange.withValues(alpha: 0.2)
                      : const Color(0xFF264532),
                  child: Text(
                    ball["over"]!,
                    style: TextStyle(
                      fontSize: 10,
                      color: ball["result"] == "W"
                          ? Colors.red
                          : hasExtras
                          ? Colors.orange
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ball["commentary"] ?? "Ball",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          // Extras badge
                          if (hasWide)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'WD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (hasNoBall)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'NB',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ball["result"] == "W" ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ball["result"]!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _bottomControls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF122118),
        border: Border(top: BorderSide(color: Color(0xFF264532))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Runs buttons
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            childAspectRatio: 2.5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            physics: const NeverScrollableScrollPhysics(),
            children: ["0", "1", "2", "3", "4", "5", "6", "W"]
                .map(
                  (val) => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: val == "W"
                          ? Colors.red
                          : Colors.green[700],
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (val == "W") {
                              // ignore: use_build_context_synchronously
                              final ctx = context;
                              _showWicketDialog(ctx);
                              // Use batting team players for wicket replacement
                              final battingTeamId =
                                  currentInning?['batting_team_id'];
                              final battingTeamPlayers =
                                  battingTeamId == teamAId
                                  ? teamAPlayers
                                  : teamBPlayers;
                              final batsman = await showNewBatsmanPopup(
                                ctx, // ignore: use_build_context_synchronously
                                battingTeamPlayers,
                              );
                              if (batsman != null) {
                                setState(() => currentBatsmanId = batsman);
                                await _addBall(runs: 0, wicketType: "bowled");
                              }
                            } else {
                              await _addBall(runs: int.parse(val));
                            }
                          },
                    child: Text(
                      val,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),

          // Extras + Overthrow
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                  ),
                  onPressed: () => _showExtrasBottomSheet(context),
                  child: const Text(
                    "Extras",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Overthrow",
                    hintStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.blue[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Start Innings button if not started
          if (currentInningId == null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: isLoading ? null : _startInnings,
                child: const Text(
                  "Start Innings",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Bottom Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _actionButton("Undo"),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            // Use current bowling team players for next bowler
                            final bowlingTeamId =
                                currentInning?['bowling_team_id'];
                            final bowlingTeamPlayers = bowlingTeamId == teamAId
                                ? teamAPlayers
                                : teamBPlayers;
                            final ctx = context; // ignore: use_build_context_synchronously
                            final nextBowler = await showEndOverPopup(
                              ctx, // ignore: use_build_context_synchronously
                              bowlingTeamPlayers,
                            );
                            if (nextBowler != null) {
                              setState(() => currentBowlerId = nextBowler);
                              // Over transition is handled by backend when balls are added
                            }
                          },
                    child: const Text(
                      "End Over",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
              _actionButton("End Innings", onPressed: _endInnings),

              // end match button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  // ✅ Collect stats (replace these with your real data from scoring logic)
                  final teamABatting = [
                    {
                      "name": "Player A1",
                      "runs": 45,
                      "balls": 30,
                      "fours": 6,
                      "sixes": 2,
                      "sr": 150.0,
                    },
                    {
                      "name": "Player A2",
                      "runs": 10,
                      "balls": 15,
                      "fours": 1,
                      "sixes": 0,
                      "sr": 66.7,
                    },
                  ];
                  final teamABowling = [
                    {
                      "name": "Player A3",
                      "overs": 4,
                      "maidens": 0,
                      "runs": 25,
                      "wickets": 2,
                      "econ": 6.25,
                    },
                  ];
                  final teamBBatting = [
                    {
                      "name": "Player B1",
                      "runs": 60,
                      "balls": 40,
                      "fours": 8,
                      "sixes": 1,
                      "sr": 150.0,
                    },
                  ];
                  final teamBBowling = [
                    {
                      "name": "Player B2",
                      "overs": 4,
                      "maidens": 1,
                      "runs": 20,
                      "wickets": 3,
                      "econ": 5.0,
                    },
                  ];

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostMatchScreen(
                        teamA: widget.teamA,
                        teamB: widget.teamB,
                        teamABatting: teamABatting,
                        teamABowling: teamABowling,
                        teamBBatting: teamBBatting,
                        teamBBowling: teamBBowling,

                        // 🔹 later these will come from user login/session
                        isCaptain: true,
                        isRegisteredTeam: true,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "End Match",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    String text, {
    bool isDanger = false,
    VoidCallback? onPressed,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDanger
                ? Colors.red[800]
                : const Color(0xFF1A2C22),
          ),
          onPressed:
              onPressed ??
              () {
                debugPrint("Action: $text");
              },
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// Show extras selection bottom sheet
  void _showExtrasBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        String? selectedExtra;
        final TextEditingController runsController = TextEditingController(
          text: '1',
        );

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Extras",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _extraButton("wide", "Wide", selectedExtra == "wide", () {
                        setState(() => selectedExtra = "wide");
                      }),
                      _extraButton(
                        "no-ball",
                        "No Ball",
                        selectedExtra == "no-ball",
                        () {
                          setState(() => selectedExtra = "no-ball");
                        },
                      ),
                      _extraButton("bye", "Bye", selectedExtra == "bye", () {
                        setState(() => selectedExtra = "bye");
                      }),
                      _extraButton(
                        "leg-bye",
                        "Leg Bye",
                        selectedExtra == "leg-bye",
                        () {
                          setState(() => selectedExtra = "leg-bye");
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF264532),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Extra Runs",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: runsController,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: "1",
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedExtra != null
                          ? Colors.green
                          : Colors.grey,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: selectedExtra != null
                        ? () async {
                            final runs = int.tryParse(runsController.text) ?? 1;
                            Navigator.pop(context);
                            await _addBall(runs: runs, extras: selectedExtra);
                          }
                        : null,
                    child: const Text(
                      "Add Extra",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _extraButton(
    String value,
    String text,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.orange : Colors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}

// ✅ Updated to use real player data and return player ID
Future<int?> showNewBatsmanPopup(
  BuildContext context,
  List<Map<String, dynamic>> teamPlayers,
) async {
  int? selectedPlayerId;

  return await showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Select New Batsman",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                if (teamPlayers.isEmpty)
                  const Text(
                    "No players available",
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    itemCount: teamPlayers.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemBuilder: (context, index) {
                      final player = teamPlayers[index];
                      final playerId = player['id'] as int;
                      final playerName =
                          player['player_name'] as String? ?? 'Unknown Player';

                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedPlayerId == playerId
                              ? Colors.green
                              : const Color(0xFF264532),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () =>
                            setState(() => selectedPlayerId = playerId),
                        child: Text(
                          playerName,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: selectedPlayerId != null
                            ? () => Navigator.pop(context, selectedPlayerId)
                            : null,
                        child: const Text(
                          "Confirm",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

// ✅ Updated to use real player data and return player ID
Future<int?> showEndOverPopup(
  BuildContext context,
  List<Map<String, dynamic>> bowlers,
) async {
  int? selectedBowlerId;
  bool confirm = false;

  return await showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "End Over",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (bowlers.isEmpty)
                  const Text(
                    "No bowlers available",
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  DropdownButtonFormField<int>(
                    dropdownColor: const Color(0xFF264532),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Select Next Bowler",
                      labelStyle: TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Color(0xFF264532),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    initialValue: selectedBowlerId,
                    items: bowlers.map((bowler) {
                      final bowlerId = bowler['id'] as int;
                      final bowlerName =
                          bowler['player_name'] as String? ?? 'Unknown Bowler';
                      return DropdownMenuItem<int>(
                        value: bowlerId,
                        child: Text(
                          bowlerName,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedBowlerId = val),
                  ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Checkbox(
                      value: confirm,
                      activeColor: Colors.green,
                      onChanged: (val) =>
                          setState(() => confirm = val ?? false),
                    ),
                    const Text(
                      "Confirm end of over",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: confirm && selectedBowlerId != null
                            ? () => Navigator.pop(context, selectedBowlerId)
                            : null,
                        child: const Text(
                          "Confirm",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

// ✅ Keep wicket + extras dialogs same as you had

// wicket popup
void _showWicketDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Wicket Options",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _wicketOption("Bowled"),
                _wicketOption("Caught"),
                _wicketOption("LBW"),
                _wicketOption("Run Out"),
                _wicketOption("Stumped"),
                _wicketOption("Hit Wicket"),
                _wicketOption("Retired Hurt", fullWidth: true),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _wicketOption(String text, {bool fullWidth = false}) {
  return SizedBox(
    width: fullWidth ? double.infinity : 120,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        // ✅ handle wicket type selection
      },
      child: Text(text, style: const TextStyle(color: Colors.white)),
    ),
  );
}

// end over popup
