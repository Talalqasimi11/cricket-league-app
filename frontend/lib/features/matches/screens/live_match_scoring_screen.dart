// lib/features/matches/screens/live_match_scoring_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/api_client.dart';
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
  int currentOver = 0;
  int currentBall = 0;
  bool isLoading = false;
  int? teamAId;
  int? teamBId;
  int? currentBatsmanId;
  int? currentBowlerId;

  final List<Map<String, String>> ballByBall = [];

  @override
  void initState() {
    super.initState();
    // Initialize team IDs from widget parameters
    teamAId = widget.teamAId;
    teamBId = widget.teamBId;
    _loadMatchData();
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
            score = '${lastInning['runs']}/${lastInning['wickets']}';
            overs = lastInning['overs'].toString();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading match data: $e')));
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _startInnings() async {
    if (currentInningId != null) return; // Innings already started

    setState(() => isLoading = true);
    try {
      final response = await ApiClient.instance.post(
        '/api/live/start-innings',
        body: {
          'match_id': widget.matchId,
          'batting_team_id': teamAId ?? 1, // Use actual team ID or fallback
          'bowling_team_id': teamBId ?? 2, // Use actual team ID or fallback
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

    setState(() => isLoading = true);
    try {
      // Increment ball number
      currentBall++;
      if (currentBall > 6) {
        currentBall = 1;
        currentOver++;
      }

      final response = await ApiClient.instance.post(
        '/api/live/ball',
        body: {
          'match_id': widget.matchId,
          'inning_id': currentInningId,
          'over_number': currentOver,
          'ball_number': currentBall,
          'batsman_id':
              currentBatsmanId ?? 1, // Use actual batsman ID or fallback
          'bowler_id': currentBowlerId ?? 2, // Use actual bowler ID or fallback
          'runs': runs,
          'extras': extras,
          'wicket_type': wicketType,
          'out_player_id': outPlayerId,
        },
      );

      if (response.statusCode == 200) {
        await _loadMatchData(); // Refresh data
        _addBallToLog(runs, wicketType);
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
          currentOver = 0;
          currentBall = 0;
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

  void _addBallToLog(int runs, String? wicketType) {
    final result = wicketType != null ? 'W' : runs.toString();
    final description = wicketType != null
        ? 'Wicket: $wicketType'
        : 'Runs: $runs';

    setState(() {
      ballByBall.insert(0, {
        'over': '$currentOver.$currentBall',
        'desc': description,
        'result': result,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF122118),
      appBar: AppBar(
        backgroundColor: const Color(0xFF122118),
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
          _batterRow("Virat Kohli*", "48", "30", "5", "2"),
          _batterRow("Dinesh Karthik", "12", "8", "1", "1"),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2C22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            "Jasprit Bumrah",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          Text(
            "O: 3.3  M: 0  R: 25  W: 1",
            style: TextStyle(color: Colors.white70),
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
        ...ballByBall.map(
          (ball) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2C22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF264532),
                  child: Text(
                    ball["over"]!,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ball["desc"]!,
                    style: const TextStyle(color: Colors.white),
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
          ),
        ),
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
                              _showWicketDialog(context);
                              final batsman = await showNewBatsmanPopup(
                                context,
                                ["Kohli", "Faf", "Maxwell"],
                              );
                              if (batsman != null) {
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
                            final nextBowler = await showEndOverPopup(context, [
                              "Hardik",
                              "Bumrah",
                              "Shami",
                            ]);
                            if (nextBowler != null) {
                              // End over logic - just increment over
                              currentOver++;
                              currentBall = 0;
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
                print("Action: $text");
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
}

// ✅ Fix: make these return Future<String?>
Future<String?> showNewBatsmanPopup(
  BuildContext context,
  List<String> teamPlayers,
) async {
  TextEditingController batsmanController = TextEditingController();
  String? selectedPlayer;

  return await showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF1A2C22),
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
                  "New Batsman",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                GridView.builder(
                  shrinkWrap: true,
                  itemCount: teamPlayers.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final player = teamPlayers[index];
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedPlayer == player
                            ? Colors.green
                            : const Color(0xFF264532),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => setState(() => selectedPlayer = player),
                      child: Text(
                        player,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),
                const Divider(color: Colors.grey),
                const SizedBox(height: 12),

                TextField(
                  controller: batsmanController,
                  decoration: InputDecoration(
                    hintText: "Enter batsman's name",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF264532),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
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
                        onPressed: () {
                          final batsman =
                              selectedPlayer ?? batsmanController.text.trim();
                          Navigator.pop(context, batsman);
                        },
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

// ✅ Fix: return Future<String?>
Future<String?> showEndOverPopup(
  BuildContext context,
  List<String> bowlers,
) async {
  String? selectedBowler;
  TextEditingController newBowlerController = TextEditingController();
  bool confirm = false;

  return await showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF1A2C22),
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

                DropdownButtonFormField<String>(
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
                  initialValue: selectedBowler,
                  items: bowlers
                      .map(
                        (bowler) => DropdownMenuItem(
                          value: bowler,
                          child: Text(
                            bowler,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => selectedBowler = val),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: newBowlerController,
                  decoration: InputDecoration(
                    hintText: "Enter new bowler",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF264532),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
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
                        onPressed: confirm
                            ? () {
                                final bowler =
                                    selectedBowler ??
                                    newBowlerController.text.trim();
                                Navigator.pop(context, bowler);
                              }
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
      backgroundColor: const Color(0xFF1A2C22),
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
        backgroundColor: const Color(0xFF264532),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        // ✅ handle wicket type selection
      },
      child: Text(text, style: const TextStyle(color: Colors.white)),
    ),
  );
}

// extras popup
void _showExtrasBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A2C22),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      final TextEditingController overthrowController = TextEditingController();
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
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _extraButton("Wide"),
                _extraButton("No Ball"),
                _extraButton("Bye"),
                _extraButton("Leg Bye"),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF264532),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Overthrow Runs",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: overthrowController,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: "0",
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
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // ✅ Handle selected extras + overthrowController.text
                Navigator.pop(context);
              },
              child: const Text("Done"),
            ),
          ],
        ),
      );
    },
  );
}

Widget _extraButton(String text) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    onPressed: () {
      // ✅ handle extras selection
    },
    child: Text(text, style: const TextStyle(color: Colors.white)),
  );
}

// end over popup
