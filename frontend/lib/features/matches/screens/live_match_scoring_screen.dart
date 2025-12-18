import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/api_client.dart';
import '../../../core/websocket_service.dart';
import '../../../core/error_handler.dart';
import '../models/ball_model.dart';
import '../services/ball_sequence_service.dart';

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
  // Scoreboard State
  String score = "0/0";
  String overs = "0.0";
  String crr = "0.00";
  String? currentInningId;
  bool isLoading = false;

  int? teamAId;
  int? teamBId;

  // Active Players
  int? strikerId;
  int? nonStrikerId;
  int? currentBowlerId;

  // Data Stores
  List<Map<String, dynamic>> teamAPlayers = [];
  List<Map<String, dynamic>> teamBPlayers = [];
  Map<String, dynamic>? currentInning;
  List<Map<String, dynamic>> playerStats = [];
  List<Map<String, String>> ballByBall = [];

  // Logic Service
  final BallSequenceService _ballService = BallSequenceService();

  @override
  void initState() {
    super.initState();
    teamAId = widget.teamAId;
    teamBId = widget.teamBId;
    _setupWebSocket();
    _init();
  }

  Future<void> _init() async {
    await _loadMatchData();
    if (teamAId != null && teamBId != null) {
      await _loadPlayers();
    }
  }

  @override
  void dispose() {
    WebSocketService.instance.disconnect();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // WebSocket & Data Management
  // ---------------------------------------------------------------------------

  void _setupWebSocket() {
    WebSocketService.instance.onScoreUpdate = (data) {
      if (mounted) {
        _handleLiveUpdate(data);
        WidgetsBinding.instance.addPostFrameCallback((_) => _checkEndOfOver());
      }
    };

    WebSocketService.instance.onInningsEnded = (data) {
      if (mounted) _handleInningsEnded(data);
    };

    WebSocketService.instance.connect(widget.matchId);
  }

  void _handleLiveUpdate(Map<String, dynamic> data) {
    try {
      String? nextInningId = currentInningId;
      String? nextScore = score;
      Map<String, dynamic>? nextInning = currentInning;
      List<Map<String, dynamic>> nextPlayerStats = List.of(playerStats);

      int? nextStriker = data['current_striker_id'] as int? ?? strikerId;
      int? nextNonStriker =
          data['current_non_striker_id'] as int? ?? nonStrikerId;
      int? nextBowler = data['current_bowler_id'] as int? ?? currentBowlerId;

      if (data['inning'] != null) {
        final inning = data['inning'] as Map<String, dynamic>;
        final runs = (inning['runs'] ?? 0) as int;
        final wkts = (inning['wickets'] ?? 0) as int;
        nextScore = '$runs/$wkts';
        nextInningId = inning['id']?.toString() ?? nextInningId;
        nextInning = inning;
      } else if (data['innings'] != null &&
          (data['innings'] as List).isNotEmpty) {
        final inningsList = data['innings'] as List;
        final active =
            inningsList.firstWhere(
                  (i) => i['status'] == 'in_progress',
                  orElse: () => inningsList.last,
                )
                as Map<String, dynamic>;

        final runs = (active['runs'] ?? 0) as int;
        final wkts = (active['wickets'] ?? 0) as int;
        nextScore = '$runs/$wkts';
        nextInningId = active['id']?.toString();
        nextInning = active;
      }

      if (data['player_stats'] != null && data['player_stats'] is List) {
        nextPlayerStats = (data['player_stats'] as List)
            .whereType<Map<String, dynamic>>()
            .toList();
      }

      if (data['allBalls'] != null && data['allBalls'] is List) {
        _syncBallService((data['allBalls'] as List));
      }

      final currentRuns = int.tryParse(nextScore.split('/').first ?? '0') ?? 0;
      final serviceOvers = _ballService.getCurrentOverNotation();

      setState(() {
        currentInningId = nextInningId;
        currentInning = nextInning;
        score = nextScore ?? score;
        overs = serviceOvers;
        crr = _crrFrom(currentRuns, serviceOvers);
        playerStats = nextPlayerStats;

        // Only update local pointers if we aren't currently loading a manual action
        if (!isLoading) {
          strikerId = nextStriker;
          nonStrikerId = nextNonStriker;
          currentBowlerId = nextBowler;
        }
      });
    } catch (e) {
      debugPrint('Error handling live update: $e');
    }
  }

  void _syncBallService(List<dynamic> rawBalls) {
    _ballService.clear();
    final displayList = <Map<String, String>>[];

    for (var b in rawBalls) {
      try {
        final ball = Ball.fromJson(b);
        _ballService.addBall(ball);

        final m = b as Map<String, dynamic>;
        final overNo = m['over_number']?.toString() ?? '';
        final ballNo = m['ball_number']?.toString() ?? '';
        final runs = m['runs']?.toString() ?? '0';
        final wicketType = m['wicket_type']?.toString() ?? '';
        final extras = m['extras']?.toString() ?? '';
        final bowler = m['bowler_name']?.toString() ?? '';
        final batsman = m['batsman_name']?.toString() ?? '';

        final result = wicketType.isNotEmpty ? 'W' : runs;
        String commentary;

        if (wicketType.isNotEmpty) {
          commentary = 'Wicket: $wicketType';
        } else if (extras == 'wide') {
          commentary = 'Wide + $runs';
        } else if (extras == 'no-ball') {
          commentary = 'No ball + $runs';
        } else if (extras.isNotEmpty) {
          commentary = '$extras: $runs';
        } else {
          commentary = 'Runs: $runs';
        }

        displayList.add({
          'over': '$overNo.$ballNo',
          'bowler': bowler,
          'batsman': batsman,
          'commentary': commentary,
          'result': result,
          'extras': extras,
        });
      } catch (e) {
        // Skip invalid
      }
    }

    setState(() {
      ballByBall = displayList.reversed.toList();
    });
  }

  void _handleInningsEnded(Map<String, dynamic> data) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Innings ended')));
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

        if (teamAId == null && data['team1_id'] != null) {
          teamAId = data['team1_id'] as int?;
        }
        if (teamBId == null && data['team2_id'] != null) {
          teamBId = data['team2_id'] as int?;
        }

        // If players aren't loaded yet, load them
        if (teamAPlayers.isEmpty || teamBPlayers.isEmpty) {
          await _loadPlayers();
        }

        _handleLiveUpdate(data);
      }
    } catch (e) {
      debugPrint('Error loading match data: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadPlayers() async {
    if (teamAId == null || teamBId == null) return;
    try {
      final results = await Future.wait([
        ApiClient.instance.get('/api/teams/$teamAId'),
        ApiClient.instance.get('/api/teams/$teamBId'),
      ]);

      if (mounted) {
        if (results[0].statusCode == 200) {
          final tA = jsonDecode(results[0].body);
          setState(
            () => teamAPlayers = List<Map<String, dynamic>>.from(
              tA['players'] ?? [],
            ),
          );
        }
        if (results[1].statusCode == 200) {
          final tB = jsonDecode(results[1].body);
          setState(
            () => teamBPlayers = List<Map<String, dynamic>>.from(
              tB['players'] ?? [],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading players: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Action Logic
  // ---------------------------------------------------------------------------

  void _checkEndOfOver() {
    if (isLoading) return;
    if (_ballService.isOverComplete()) {
      _showEndOverDialog();
    }
  }

  Future<void> _startInnings() async {
    if (teamAId == null || teamBId == null) return;

    setState(() => isLoading = true);
    try {
      final response = await ApiClient.instance.post(
        '/api/live/start-innings',
        body: {
          'match_id': widget.matchId,
          'batting_team_id': teamAId, // Logic: Assume Team A bats first for now
          'bowling_team_id': teamBId,
          'inning_number': 1,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() => currentInningId = data['inning_id']?.toString());
        _showSnack('Innings started successfully', isError: false);
        await _loadMatchData();
      } else {
        _showSnack('Failed to start innings (Status: ${response.statusCode})');
      }
    } on ApiHttpException catch (e) {
      if (e.statusCode == 403) {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Access Denied'),
              content: const Text(
                'You do not have permission to start this match. Only the match creator or an admin can start scoring.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        _showSnack('Error starting innings: ${e.message}');
      }
    } catch (e) {
      _showSnack('Error starting innings: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _addBall({
    required int runs,
    String? extras,
    String? wicketType,
    int? outPlayerId,
  }) async {
    // Validation
    if (currentInningId == null) return _showSnack('Start innings first');
    if (strikerId == null || currentBowlerId == null) {
      return _showSnack('Select batter and bowler first');
    }

    final int facingBatsmanId = strikerId!;
    final int? originalStriker = strikerId;
    final int? originalNonStriker = nonStrikerId;
    final bool isOddRuns = runs % 2 != 0;

    // Optimistic Update
    final oldScore = score;
    final oldBallByBall = List<Map<String, String>>.from(ballByBall);

    setState(() {
      final parts = score.split('/');
      int currentRuns = int.tryParse(parts[0]) ?? 0;
      int currentWickets = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      currentRuns += runs;
      if (wicketType != null) currentWickets += 1;
      score = '$currentRuns/$currentWickets';

      ballByBall.insert(0, {
        'over': _ballService.getCurrentOverNotation(),
        'bowler': '...',
        'batsman': '...',
        'commentary': 'Sending...',
        'result': wicketType != null ? 'W' : runs.toString(),
        'extras': extras ?? '',
      });

      // Simple strike rotation simulation
      if (isOddRuns && wicketType == null) {
        strikerId = originalNonStriker;
        nonStrikerId = originalStriker;
      }
    });

    try {
      final nextIndices = _ballService.getNextDeliveryIndices();

      final response = await ApiClient.instance.post(
        '/api/live/ball',
        body: {
          'match_id': widget.matchId,
          'inning_id': currentInningId,
          'batsman_id': facingBatsmanId,
          'bowler_id': currentBowlerId,
          'runs': runs,
          'extras': extras,
          'wicket_type': wicketType,
          'out_player_id': outPlayerId,
          'over_number': nextIndices['over_number'],
          'ball_number': nextIndices['ball_number'],
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('API Error ${response.statusCode}');
      }
    } catch (e) {
      // Rollback
      if (mounted) {
        setState(() {
          score = oldScore;
          ballByBall = oldBallByBall;
          strikerId = originalStriker;
          nonStrikerId = originalNonStriker;
        });
        _showSnack('Failed to record ball');
      }
    }
  }

  Future<void> _handleUndo() async {
    if (currentInningId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Undo Last Ball?'),
        content: const Text('This will delete the last ball and revert stats.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Undo', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);
    try {
      final response = await ApiClient.instance.post(
        '/api/live/undo',
        body: {'match_id': widget.matchId, 'inning_id': currentInningId},
      );
      if (response.statusCode == 200) {
        _showSnack('Undo successful', isError: false);
        await _loadMatchData();
      } else {
        _showSnack('Undo failed');
      }
    } catch (e) {
      _showSnack('Network error during undo');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Dialogs & Popups
  // ---------------------------------------------------------------------------

  void _showEndOverDialog() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: const Color(0xFF122118),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Over Complete!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  Navigator.pop(ctx);
                  _selectNextBowler();
                },
                child: const Text(
                  "Select Next Bowler",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectNextBowler() async {
    // Ensure players are loaded
    if (teamAPlayers.isEmpty || teamBPlayers.isEmpty) {
      await _loadPlayers();
    }

    final bowlingTeamId = currentInning?['bowling_team_id'];

    // Improved Team Selection Logic: Handle String/Int mismatch safely
    List<Map<String, dynamic>> bowlingTeamPlayers = [];
    if (bowlingTeamId.toString() == teamAId.toString()) {
      bowlingTeamPlayers = teamAPlayers;
    } else if (bowlingTeamId.toString() == teamBId.toString()) {
      bowlingTeamPlayers = teamBPlayers;
    } else {
      // Fallback: If logic fails (shouldn't), try to guess by eliminating batting team
      final battingId = currentInning?['batting_team_id'];
      if (battingId != null) {
        if (battingId.toString() == teamAId.toString())
          bowlingTeamPlayers = teamBPlayers;
        else
          bowlingTeamPlayers = teamAPlayers;
      }
    }

    final excludeIds = <int>{};
    if (currentBowlerId != null) excludeIds.add(currentBowlerId!);

    final newBowlerId = await showPlayerSelectPopup(
      context,
      bowlingTeamPlayers,
      excludeIds,
      bowlingTeamId ?? 0,
      title: "Select Bowler",
    );

    if (newBowlerId != null) {
      // Check if this is a new player (not in our current list)
      // If so, reload data to get their name
      bool isKnown = bowlingTeamPlayers.any((p) => p['id'] == newBowlerId);
      if (!isKnown) {
        await _loadPlayers();
      }

      setState(() {
        currentBowlerId = newBowlerId;
        // Swap batsmen at end of over
        final temp = strikerId;
        strikerId = nonStrikerId;
        nonStrikerId = temp;
      });
    }
  }

  void _manageBatters() async {
    // Ensure players are loaded
    if (teamAPlayers.isEmpty || teamBPlayers.isEmpty) {
      await _loadPlayers();
    }

    final battingTeamId = currentInning?['batting_team_id'];

    // Improved Team Selection Logic
    List<Map<String, dynamic>> battingTeamPlayers = [];
    if (battingTeamId.toString() == teamAId.toString()) {
      battingTeamPlayers = teamAPlayers;
    } else if (battingTeamId.toString() == teamBId.toString()) {
      battingTeamPlayers = teamBPlayers;
    } else {
      // Fallback
      if (battingTeamId != null) {
        debugPrint(
          "Warning: Batting Team ID $battingTeamId matches neither A:$teamAId nor B:$teamBId",
        );
        // Attempt generous fallback
        if (teamAPlayers.isNotEmpty)
          battingTeamPlayers = teamAPlayers;
        else if (teamBPlayers.isNotEmpty)
          battingTeamPlayers = teamBPlayers;
      }
    }

    // Determine who needs selection
    String? selectionMode;
    if (strikerId == null && nonStrikerId == null) {
      selectionMode = 'both';
    } else if (strikerId == null) {
      selectionMode = 'striker';
    } else if (nonStrikerId == null) {
      selectionMode = 'nonStriker';
    } else {
      // Both exist, ask user who to change
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Change Batter'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'striker'),
              child: Text('Striker: ${_getPlayerName(strikerId)}'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'nonStriker'),
              child: Text('Non-Striker: ${_getPlayerName(nonStrikerId)}'),
            ),
          ],
        ),
      );
      if (choice == null) return;
      selectionMode = choice;
    }

    final excludeIds = {strikerId, nonStrikerId}.whereType<int>().toSet();

    if (selectionMode == 'both' || selectionMode == 'striker') {
      final sId = await showPlayerSelectPopup(
        context,
        battingTeamPlayers,
        excludeIds,
        battingTeamId ?? 0,
        title: "Select Striker",
      );

      if (sId != null) {
        // Reload if new
        if (!battingTeamPlayers.any((p) => p['id'] == sId)) {
          await _loadPlayers();
        }
        setState(() => strikerId = sId);
        excludeIds.add(sId);
      }
    }

    if (selectionMode == 'both' || selectionMode == 'nonStriker') {
      final nsId = await showPlayerSelectPopup(
        context,
        battingTeamPlayers,
        excludeIds,
        battingTeamId ?? 0,
        title: "Select Non-Striker",
      );
      if (nsId != null) {
        // Reload if new
        if (!battingTeamPlayers.any((p) => p['id'] == nsId)) {
          await _loadPlayers();
        }
        setState(() => nonStrikerId = nsId);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // UI Builders
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("${widget.teamA} vs ${widget.teamB}"),
        backgroundColor: Colors.green[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: (!isLoading && currentInningId != null)
                ? _handleUndo
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildScoreHeader(),
          Expanded(
            child: currentInningId == null
                ? _buildStartMatchView()
                : _buildMatchView(),
          ),
        ],
      ),
      bottomNavigationBar: currentInningId != null
          ? _buildScoringControls()
          : null,
    );
  }

  Widget _buildStartMatchView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports_cricket, size: 80, color: Colors.green),
          const SizedBox(height: 20),
          const Text(
            "Match Ready to Start",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: isLoading ? null : _startInnings,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.play_arrow),
            label: const Text("START INNINGS", style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchView() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildBattersCard(),
        const SizedBox(height: 12),
        _buildBowlerCard(),
        const SizedBox(height: 12),
        _buildBallFeed(),
      ],
    );
  }

  Widget _buildScoreHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF1A2C22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "$score ($overs)",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  "CRR: $crr",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          if (currentInningId != null) const SizedBox(width: 8),
          if (currentInningId != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: () => _showEndInningsDialog(),
              child: const Text("End Innings", style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildBattersCard() {
    bool missingBatters = strikerId == null || nonStrikerId == null;

    if (missingBatters) {
      return Card(
        color: const Color(0xFF1A2C22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "Batters not selected",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text("Select Batters"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: _manageBatters,
              ),
            ],
          ),
        ),
      );
    }

    final s1 = playerStats.firstWhere(
      (p) => p['player_id'] == strikerId,
      orElse: () => {},
    );
    final s2 = playerStats.firstWhere(
      (p) => p['player_id'] == nonStrikerId,
      orElse: () => {},
    );

    return Card(
      color: const Color(0xFF1A2C22),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Batters",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.white70),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _manageBatters,
                ),
              ],
            ),
            const Divider(color: Colors.white24),
            _batterRow(strikerId, s1, isStriker: true),
            const SizedBox(height: 8),
            _batterRow(nonStrikerId, s2, isStriker: false),
          ],
        ),
      ),
    );
  }

  Widget _batterRow(
    int? playerId,
    Map<String, dynamic> stats, {
    required bool isStriker,
  }) {
    final name = _getPlayerName(playerId);
    final runs = stats['runs'] ?? 0;
    final balls = stats['balls_faced'] ?? 0;
    final fours = stats['fours'] ?? 0;
    final sixes = stats['sixes'] ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (isStriker)
              const Icon(Icons.play_arrow, color: Colors.green, size: 16),
            const SizedBox(width: 4),
            Text(
              name,
              style: TextStyle(
                color: isStriker ? Colors.white : Colors.white70,
                fontWeight: isStriker ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        Text(
          "$runs ($balls)  4s:$fours 6s:$sixes",
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBowlerCard() {
    if (currentBowlerId == null) {
      return Card(
        color: const Color(0xFF1A2C22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "Bowler not selected",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.sports_baseball),
                label: const Text("Select Bowler"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: _selectNextBowler,
              ),
            ],
          ),
        ),
      );
    }

    final bowler = playerStats.firstWhere(
      (p) => p['player_id'] == currentBowlerId,
      orElse: () => {},
    );
    final name = _getPlayerName(currentBowlerId);
    final balls = (bowler['balls_bowled'] as num?) ?? 0;
    final o = (balls / 6).toStringAsFixed(1);
    final r = bowler['runs_conceded'] ?? 0;
    final w = bowler['wickets'] ?? 0;

    return Card(
      color: const Color(0xFF1A2C22),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text(
          "Bowling now",
          style: TextStyle(color: Colors.greenAccent, fontSize: 12),
        ),
        trailing: Text(
          "O:$o R:$r W:$w",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        onTap: _selectNextBowler, // Allow changing bowler mid-over if needed
      ),
    );
  }

  Widget _buildBallFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Deliveries",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (ballByBall.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "No balls bowled yet.",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ...ballByBall.take(6).map((b) {
          final res = b['result'] ?? '';
          final isWicket = res == 'W';
          final isBoundary = res == '4' || res == '6';
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isWicket
                      ? Colors.red
                      : (isBoundary ? Colors.green : Colors.grey[700]),
                  child: Text(
                    b['result'] ?? '',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "${b['over']} - ${b['commentary']} (${b['bowler']} to ${b['batsman']})",
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildScoringControls() {
    final bool canScore =
        strikerId != null && nonStrikerId != null && currentBowlerId != null;
    final bool isOverDone = _ballService.isOverComplete();

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            childAspectRatio: 1.3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            physics: const NeverScrollableScrollPhysics(),
            children: ["0", "1", "2", "3", "4", "5", "6", "W"].map((val) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: val == "W"
                      ? Colors.red
                      : const Color(0xFF1A2C22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: (isLoading || isOverDone || !canScore)
                    ? null
                    : () => _handleScoringInput(val),
                child: Text(
                  val,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: (isLoading || isOverDone || !canScore)
                      ? null
                      : _showExtrasBottomSheet,
                  child: const Text("Extras (Wide/NB)"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange[800],
                  ),
                  onPressed: (isOverDone && !isLoading) ? _handleEndOver : null,
                  child: const Text("End Over"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Scoring Input Handlers
  // ---------------------------------------------------------------------------

  Future<void> _handleScoringInput(String val) async {
    if (val == "W") {
      await _handleWicket();
    } else {
      await _addBall(runs: int.parse(val));
    }
  }

  Future<void> _handleWicket() async {
    final type = await _showSimpleDialog('Wicket Type', [
      'Bowled',
      'Caught',
      'LBW',
      'Run Out',
      'Stumped',
      'Hit Wicket',
    ]);
    if (type == null) return;

    int runOutRuns = 0;
    if (type == 'Run Out') {
      final r = await _showSimpleDialog('Runs taken?', ['0', '1', '2', '3']);
      runOutRuns = int.parse(r ?? '0');
    }

    final outId = await _showWhoIsOutDialog();
    if (outId == null) return;

    await _addBall(
      runs: runOutRuns,
      wicketType: type.toLowerCase().replaceAll(' ', '-'),
      outPlayerId: outId,
    );

    if (!mounted) return;

    // Auto prompt for new batsman
    final battingTeamId = currentInning?['batting_team_id'];
    final battingTeamPlayers = battingTeamId == teamAId
        ? teamAPlayers
        : teamBPlayers;
    final excludeIds = {
      strikerId,
      nonStrikerId,
      outId,
    }.whereType<int>().toSet();

    final newBatsmanId = await showPlayerSelectPopup(
      context,
      battingTeamPlayers,
      excludeIds,
      battingTeamId ?? 0,
      title: "Who is the new batsman?",
    );

    if (newBatsmanId != null) {
      setState(() {
        if (outId == strikerId) {
          strikerId = newBatsmanId;
        } else {
          nonStrikerId = newBatsmanId;
        }
      });
    }
  }

  Future<void> _handleEndOver() async {
    _showEndOverDialog();
  }

  void _showExtrasBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: const Text('Wide'), onTap: () => _addExtra('wide')),
          ListTile(
            title: const Text('No Ball'),
            onTap: () => _addExtra('no-ball'),
          ),
          ListTile(title: const Text('Bye'), onTap: () => _addExtra('bye')),
          ListTile(
            title: const Text('Leg Bye'),
            onTap: () => _addExtra('leg-bye'),
          ),
        ],
      ),
    );
  }

  Future<void> _addExtra(String type) async {
    Navigator.pop(context);
    int runs = 1;
    if (type == 'bye' || type == 'leg-bye') {
      final r = await _showSimpleDialog('How many runs?', ['1', '2', '3', '4']);
      runs = int.parse(r ?? '1');
    }
    await _addBall(runs: runs, extras: type);
  }

  void _showEndInningsDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Innings?'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => isLoading = true);
    try {
      await ApiClient.instance.post(
        '/api/live/end-innings',
        body: {'inning_id': currentInningId},
      );
      setState(() => currentInningId = null);
      _showSnack('Innings Ended', isError: false);
    } catch (e) {
      _showSnack('Error ending innings');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _getPlayerName(int? id) {
    if (id == null) return 'None';

    // 1. Try Player Stats (Most active)
    final statPlayer = playerStats.firstWhere(
      (p) => p['player_id'] == id,
      orElse: () => {},
    );
    if (statPlayer.isNotEmpty && statPlayer['player_name'] != null) {
      return statPlayer['player_name'];
    }

    // 2. Try Team A
    final teamAPlayer = teamAPlayers.firstWhere(
      (p) => p['id'] == id,
      orElse: () => {},
    );
    if (teamAPlayer.isNotEmpty && teamAPlayer['player_name'] != null) {
      return teamAPlayer['player_name'];
    }

    // 3. Try Team B
    final teamBPlayer = teamBPlayers.firstWhere(
      (p) => p['id'] == id,
      orElse: () => {},
    );
    if (teamBPlayer.isNotEmpty && teamBPlayer['player_name'] != null) {
      return teamBPlayer['player_name'];
    }

    return 'Unknown';
  }

  String _crrFrom(int runs, String overs) {
    if (overs == "0.0") return "0.00";
    final parts = overs.split('.');
    final totalBalls = (int.parse(parts[0]) * 6) + int.parse(parts[1]);
    if (totalBalls == 0) return "0.00";
    return ((runs / totalBalls) * 6).toStringAsFixed(2);
  }

  void _showSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<String?> _showSimpleDialog(String title, List<String> options) {
    return showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(title),
        children: options
            .map(
              (o) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, o),
                child: Text(o),
              ),
            )
            .toList(),
      ),
    );
  }

  Future<int?> _showWhoIsOutDialog() {
    return showDialog<int>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Who is out?'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, strikerId),
            child: Text('Striker: ${_getPlayerName(strikerId)}'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, nonStrikerId),
            child: Text('Non-Striker: ${_getPlayerName(nonStrikerId)}'),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Shared Popup Widget
// -----------------------------------------------------------------------------

Future<int?> showPlayerSelectPopup(
  BuildContext context,
  List<Map<String, dynamic>> players,
  Set<int> excludeIds,
  int teamId, {
  required String title,
}) {
  final available = players
      .where((p) => !excludeIds.contains(p['id']))
      .toList();

  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.green,
            child: Icon(Icons.add, color: Colors.white),
          ),
          title: const Text(
            'Add New Player',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          onTap: () async {
            // Do not close the bottom sheet immediately.
            // Wait for the dialog to complete, then close the bottom sheet with the result.
            final newId = await _showAddPlayerDialog(context, teamId);
            if (newId != null && context.mounted) {
              Navigator.pop(ctx, newId);
            }
          },
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: available.length,
            itemBuilder: (ctx, i) {
              final p = available[i];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(p['player_name'] ?? 'Unknown'),
                onTap: () => Navigator.pop(ctx, p['id']),
              );
            },
          ),
        ),
      ],
    ),
  );
}

Future<int?> _showAddPlayerDialog(BuildContext context, int teamId) async {
  final nameController = TextEditingController();
  String role = 'Batsman';

  return showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Add New Player'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Player Name'),
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: role,
              isExpanded: true,
              items: [
                'Batsman',
                'Bowler',
                'All-rounder',
                'Wicket-keeper',
              ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (val) => setState(() => role = val!),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              try {
                final response = await ApiClient.instance.post(
                  '/api/players',
                  body: {
                    'player_name': nameController.text.trim(),
                    'player_role': role,
                    'team_id': teamId,
                    'is_temporary': true,
                  },
                );
                if (response.statusCode == 201) {
                  final data = jsonDecode(response.body);
                  if (context.mounted) Navigator.pop(ctx, data['id']);
                }
              } catch (e) {
                debugPrint('Error adding player: $e');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ),
  );
}
