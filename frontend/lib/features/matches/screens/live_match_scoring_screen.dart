import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/api_client.dart';
import '../../../core/websocket_service.dart';
import '../../../core/error_handler.dart';
import '../../../core/database/hive_service.dart'; // [Added] Import HiveService
import '../models/ball_model.dart';
import '../services/ball_sequence_service.dart';
import 'scorecard_screen.dart';
import 'package:provider/provider.dart';
import '../providers/match_provider.dart';
import '../models/match_model.dart';

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
  String rrr = "0.00";
  Map<String, dynamic>? currentPartnership;
  String? currentInningId;
  bool isLoading = false;

  int? teamAId;
  int? teamBId;
  int? selectedBattingTeamId;

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
  List<dynamic> allInnings = []; // [Added] Track all innings

  // Logic Service
  final BallSequenceService _ballService = BallSequenceService();
  bool _matchEndDialogShown = false;
  String? winnerName;
  String? resultMessage;
  String? targetScore;

  @override
  void initState() {
    super.initState();
    teamAId = widget.teamAId;
    teamBId = widget.teamBId;
    _setupWebSocket();
    _init();
  }

  Future<void> _init() async {
    setState(() => isLoading = true);
    try {
      await _loadMatchData();
      if (teamAId != null && teamBId != null) {
        await _loadPlayers();
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
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

    WebSocketService.instance.onError = (error) {
      debugPrint('WebSocket Error in Scoring Screen: $error');
      // We don't show a snackbar here to avoid annoying the user if the socket reconnects,
      // as scoring actions are HTTP-based and we force refresh data after each action.
    };

    WebSocketService.instance.connect(widget.matchId);
  }

  void _handleLiveUpdate(Map<String, dynamic> data) {
    debugPrint('[_handleLiveUpdate] Received data keys: ${data.keys.toList()}');
    try {
      String? nextInningId = currentInningId;
      String? nextScore = score;
      Map<String, dynamic>? nextInning = currentInning;
      List<Map<String, dynamic>> nextPlayerStats = List.of(playerStats);

      int? nextStriker = strikerId;
      int? nextNonStriker = nonStrikerId;
      int? nextBowler = currentBowlerId;
      String? nextCrr = crr;
      String? nextRrr = "0.00";
      Map<String, dynamic>? nextPartnership;
      String? nextWinnerName;
      String? nextResultMessage;

      if (data['winner_name'] != null) {
        nextWinnerName = data['winner_name'].toString();
      }
      if (data['result_message'] != null) {
        nextResultMessage = data['result_message'].toString();
      }

      if (data['stats'] != null) {
        nextCrr = data['stats']['crr']?.toString() ?? nextCrr;
        nextRrr = data['stats']['rrr']?.toString() ?? "0.00";
        nextPartnership = data['stats']['partnership'] as Map<String, dynamic>?;
      }

      if (data['player_stats'] != null) {
        debugPrint(
          "LiveUpdate player_stats raw count: ${(data['player_stats'] as List).length}",
        );
      }

      if (data['player_stats'] != null) {
        final statsList = data['player_stats'] as List;
        debugPrint(
          "[_handleLiveUpdate] player_stats raw count: ${statsList.length}",
        );
        if (statsList.isNotEmpty) {
          debugPrint("[_handleLiveUpdate] Sample Stat: ${statsList[0]}");
        }
      }

      if (data['allBalls'] != null) {
        final ballsList = data['allBalls'] as List;
        debugPrint(
          "[_handleLiveUpdate] allBalls raw count: ${ballsList.length}",
        );
      }

      if (data['inning'] != null) {
        final inning = data['inning'] as Map<String, dynamic>;
        final runs = (inning['runs'] ?? 0) as int;
        final wkts = (inning['wickets'] ?? 0) as int;
        nextScore = '$runs/$wkts';
        nextInningId = inning['id']?.toString() ?? nextInningId;
        nextInning = inning;

        nextStriker = inning['current_striker_id'] as int?;
        nextNonStriker = inning['current_non_striker_id'] as int?;
        nextBowler = inning['current_bowler_id'] as int?;
      } else if (data['innings'] != null &&
          (data['innings'] as List).isNotEmpty) {
        final inningsList = data['innings'] as List;
        allInnings = inningsList; // [Added] Update local cache

        final active = inningsList.firstWhere(
          (i) => i['status'] == 'in_progress',
          orElse: () => null,
        );

        if (active != null) {
          final activeMap = active as Map<String, dynamic>;
          final runs = (activeMap['runs'] ?? 0) as int;
          final wkts = (activeMap['wickets'] ?? 0) as int;
          nextScore = '$runs/$wkts';
          nextInningId = activeMap['id']?.toString();
          nextInning = activeMap;
          nextStriker = activeMap['current_striker_id'] as int?;
          nextNonStriker = activeMap['current_non_striker_id'] as int?;
          nextBowler = activeMap['current_bowler_id'] as int?;
        } else {
          // No active inning - but we might have a completed inning that was just updated
          // Try to find the inning corresponding to currentInningId to get its latest status
          if (currentInningId != null) {
            final updatedInning = inningsList.firstWhere(
              (i) => i['id'].toString() == currentInningId,
              orElse: () => null,
            );

            if (updatedInning != null) {
              nextInning = updatedInning as Map<String, dynamic>;
              debugPrint(
                'Updated currentInning (completed) status: ${nextInning['status']}',
              );
            }

            // Keep using last known inning ID for ball display
            nextInningId = currentInningId;
            debugPrint(
              'No active inning, preserving (and updating) inningId: $nextInningId',
            );
          } else {
            // Truly no inning data yet
            nextInningId = null;
          }
        }
      }

      if (data['player_stats'] != null && data['player_stats'] is List) {
        try {
          nextPlayerStats = (data['player_stats'] as List).map((item) {
            return Map<String, dynamic>.from(item as Map);
          }).toList();
        } catch (e) {
          debugPrint("Error parsing player_stats: $e");
        }
      }

      // [Added] Robut Sync from currentContext
      if (data['currentContext'] != null) {
        try {
          final ctx = data['currentContext'];
          // Sync Batsmen
          if (ctx['batsmen'] != null && ctx['batsmen'] is List) {
            for (var b in ctx['batsmen']) {
              final bMap = Map<String, dynamic>.from(b);
              final idx = nextPlayerStats.indexWhere(
                (p) =>
                    p['player_id']?.toString() == bMap['player_id']?.toString(),
              );
              if (idx >= 0) {
                nextPlayerStats[idx] = bMap;
              } else {
                nextPlayerStats.add(bMap);
              }
            }
          }
          // Sync Bowler
          if (ctx['bowler'] != null) {
            final bMap = Map<String, dynamic>.from(ctx['bowler']);
            final idx = nextPlayerStats.indexWhere(
              (p) =>
                  p['player_id']?.toString() == bMap['player_id']?.toString(),
            );
            if (idx >= 0) {
              nextPlayerStats[idx] = bMap;
            } else {
              nextPlayerStats.add(bMap);
            }
          }
        } catch (e) {
          debugPrint("Error parsing currentContext: $e");
        }
      }

      if (data['allBalls'] != null && data['allBalls'] is List) {
        debugPrint(
          "[_handleLiveUpdate] Syncing ${data['allBalls'].length} balls for inning $nextInningId",
        );
        _syncBallService(
          (data['allBalls'] as List),
          targetInningId: nextInningId,
        );
      }

      final t1 = data['team1_players'] as List?;
      final t2 = data['team2_players'] as List?;
      final serviceOvers = _ballService.getCurrentOverNotation();

      if (nextInningId != currentInningId) {
        debugPrint(
          "Inning changed from $currentInningId to $nextInningId. Performing strict state reset.",
        );
        // Strict Reset
        score = "0/0";
        // _ballService.clear(); // [Fix] Already handled in _syncBallService with new ID
        // ballByBall.clear(); // [Fix] Already handled in _syncBallService with new ID

        // Ensure we sync balls with the NEW inning ID
        currentInningId = nextInningId;
      }

      setState(() {
        if (t1 != null) {
          teamAPlayers = List<Map<String, dynamic>>.from(t1);
        }
        if (t2 != null) {
          teamBPlayers = List<Map<String, dynamic>>.from(t2);
        }
        currentInningId = nextInningId;
        currentInning = nextInning;
        score = nextScore ?? score;
        overs = serviceOvers;
        crr = nextCrr ?? "0.00";
        rrr = nextRrr ?? "0.00";
        currentPartnership = nextPartnership;
        playerStats = nextPlayerStats;

        winnerName = nextWinnerName ?? winnerName;
        resultMessage = nextResultMessage ?? resultMessage;
        targetScore = data['target_score']?.toString() ?? targetScore;

        strikerId = nextStriker;
        nonStrikerId = nextNonStriker;
        currentBowlerId = nextBowler;
      });

      if (data['matchEnded'] == true && !_matchEndDialogShown) {
        _matchEndDialogShown = true;
        _showMatchCompletedDialog();
      } else if (data['autoEnded'] == true && !_matchEndDialogShown) {
        // Just show a snackbar for inning auto-end, don't block flow
        // We don't set _matchEndDialogShown = true here because we want to allow future match end dialogs
        _showSnack(
          "Inning Ended (Overs/Wickets limit reached)",
          isError: false,
        );
      }
      //...
    } catch (e) {
      debugPrint('Error handling live update: $e');
    }
  }

  void _syncBallService(List<dynamic> rawBalls, {String? targetInningId}) {
    _ballService.clear();
    final displayList = <Map<String, String>>[];
    // Use targetInningId if provided, otherwise fallback to current
    final filterId = targetInningId ?? currentInningId?.toString();

    debugPrint(
      '[_syncBallService] Syncing ${rawBalls.length} balls for inning $filterId. currentInningId=$currentInningId',
    );

    if (rawBalls.isNotEmpty) {
      debugPrint("[_syncBallService] First ball data: ${rawBalls[0]}");
      debugPrint(
        "[_syncBallService] First ball inning_id type: ${rawBalls[0]['inning_id'].runtimeType}",
      );
    }

    if (filterId == null) {
      // Nothing to show if we don't know the inning
      debugPrint('[_syncBallService] No inning ID, clearing ball list');
      setState(() {
        ballByBall = [];
      });
      return;
    }

    for (var b in rawBalls) {
      try {
        final m = b as Map<String, dynamic>;
        // Filter balls by current inning - USE STRING COMPARISON FOR ROBUSTNESS
        if (m['inning_id']?.toString() != filterId.toString()) continue;

        final ball = Ball.fromJson(b);
        _ballService.addBall(ball);

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
    // Note: Calling setState(isLoading=true) here might cause flickering if called from _init
    // We only set it if it's not already loading
    bool setLocalLoading = !isLoading;
    if (setLocalLoading) setState(() => isLoading = true);

    try {
      // [Senior Dev Fix] Explicitly clear any local Hive cache for this match to prevent rogue data
      try {
        final box = HiveService().getBox(HiveService.boxMatches);
        final matchIdInt = int.tryParse(widget.matchId);
        if (matchIdInt != null) {
          if (box.containsKey(matchIdInt)) {
            debugPrint(
              "[Cache] Deleting stale match $matchIdInt from Hive cache.",
            );
            await box.delete(matchIdInt);
          }
        }
      } catch (e) {
        debugPrint("[Cache] Error clearing local cache: $e");
      }

      // Force network fetch to avoid stale Hive data on resume
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

        _handleLiveUpdate(data);
      }
    } catch (e) {
      debugPrint('Error loading match data: $e');
    } finally {
      if (mounted && setLocalLoading) setState(() => isLoading = false);
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

    // [Fix] Do not show End Over dialog if the inning/match is completed or dialog already shown
    if (_matchEndDialogShown) return;
    if (currentInning != null && currentInning!['status'] == 'completed') {
      debugPrint('Inning completed, skipping End Over dialog');
      return;
    }

    final lastBowlerId = _ballService.balls.isNotEmpty
        ? _ballService.balls.last.bowlerId
        : null;

    if (_ballService.isOverComplete() && currentBowlerId == lastBowlerId) {
      _showEndOverDialog();
    }
  }

  Future<void> _startInnings() async {
    debugPrint('[_startInnings] Requesting to start innings...');
    setState(() => isLoading = true);
    try {
      // Determine next inning number and teams
      int nextInningNumber = 1;
      int? battingTeam = teamAId;
      int? bowlingTeam = teamBId;

      if (currentInning != null) {
        nextInningNumber = (currentInning!['inning_number'] ?? 0) + 1;
        // Correctly swap based on who batted in the current (likely 1st) inning
        if (currentInning!['batting_team_id']?.toString() ==
            teamAId?.toString()) {
          battingTeam = teamBId;
          bowlingTeam = teamAId;
        } else {
          battingTeam = teamAId;
          bowlingTeam = teamBId;
        }
      } else if (allInnings.isNotEmpty) {
        // [Added] Calculate from history if currentInning is null
        final last = allInnings.last as Map<String, dynamic>;
        nextInningNumber = (last['inning_number'] ?? 0) + 1;

        debugPrint(
          '[_startInnings] Last Inning Batting Team: ${last['batting_team_id']} vs TeamA: $teamAId',
        );

        if (last['batting_team_id']?.toString() == teamAId?.toString()) {
          battingTeam = teamBId;
          bowlingTeam = teamAId;
        } else {
          battingTeam = teamAId;
          bowlingTeam = teamBId;
        }
      }

      debugPrint(
        '[_startInnings] Calculated: Batting=$battingTeam, Bowling=$bowlingTeam',
      );

      if (battingTeam == null) {
        // Failsafe: If logic fails, try to infer from match data or default
        if (teamAId != null && teamBId != null) {
          // Assume Team A batted first if we can't tell, so Team B bats next?
          // Better to default to TeamB if TeamA was seemingly 1st.
          // But let's rely on what we have. If null, show error.
          _showSnack('Error determining teams. Please restart.');
          return;
        }
      }

      if (nextInningNumber > 2) {
        _showSnack('Match already has 2 innings completed');
        return;
      }

      final response = await ApiClient.instance.post(
        '/api/live/start-innings',
        body: {
          'match_id': widget.matchId,
          'batting_team_id': battingTeam,
          'bowling_team_id': bowlingTeam,
          'inning_number': nextInningNumber,
          'striker_id': null,
          'non_striker_id': null,
          'bowler_id': null,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          // Clear previous inning data to prevent ghosting
          score = "0/0";
          overs = "0.0";
          crr = "0.00";
          rrr = "0.00";
          ballByBall.clear();
          _ballService.clear();
          playerStats.clear();
          strikerId = null;
          nonStrikerId = null;
          currentBowlerId = null;
          currentPartnership = null;

          currentInningId = data['inning_id']?.toString();

          // [Fix] Optimistic Update to force UI navigation immediately
          currentInning = {
            'id': int.tryParse(currentInningId ?? '0'),
            'match_id': int.tryParse(widget.matchId),
            'inning_number': nextInningNumber,
            'batting_team_id': battingTeam,
            'bowling_team_id': bowlingTeam,
            'status': 'in_progress',
            'runs': 0,
            'wickets': 0,
            'overs': 0,
            'legal_balls': 0,
          };
        });
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
    debugPrint(
      '[_addBall] Adding ball: runs=$runs, extras=$extras, wicket=$wicketType',
    );
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
      isLoading = true; // [Added] Set loading during network action
      final parts = score.split('/');
      int currentRuns = int.tryParse(parts[0]) ?? 0;
      int currentWickets = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      currentRuns += runs;
      if (wicketType != null) currentWickets += 1;
      score = '$currentRuns/$currentWickets';

      ballByBall.insert(0, {
        'over': _ballService.getCurrentOverNotation(),
        'bowler': _getPlayerName(currentBowlerId),
        'batsman': _getPlayerName(facingBatsmanId),
        'commentary': 'Sending...',
        'result': wicketType != null ? 'W' : runs.toString(),
        'extras': extras ?? '',
      });

      // [Added] Optimistic Player Stats Update
      // If player doesn't exist in stats yet (startup or first ball), create them.

      // -- Striker --
      int strikerIndex = playerStats.indexWhere(
        (p) => p['player_id']?.toString() == facingBatsmanId.toString(),
      );

      Map<String, dynamic> oldStat;
      if (strikerIndex != -1) {
        oldStat = playerStats[strikerIndex];
      } else {
        // Create new entry
        oldStat = {
          'player_id': facingBatsmanId,
          'runs': 0,
          'balls_faced': 0,
          'fours': 0,
          'sixes': 0,
          'is_out': 0,
          'match_id': int.tryParse(widget.matchId),
        };
        playerStats.add(oldStat);
        strikerIndex = playerStats.length - 1;
      }

      final newRuns =
          (oldStat['runs'] ?? 0) +
          (extras == null
              ? runs
              : (extras == 'no-ball' ? (runs > 0 ? runs - 1 : 0) : 0));
      final newBalls =
          (oldStat['balls_faced'] ?? 0) + (extras == 'wide' ? 0 : 1);
      final newFours = (oldStat['fours'] ?? 0) + (runs == 4 ? 1 : 0);
      final newSixes = (oldStat['sixes'] ?? 0) + (runs == 6 ? 1 : 0);

      playerStats[strikerIndex] = {
        ...oldStat,
        'runs': newRuns,
        'balls_faced': newBalls,
        'fours': newFours,
        'sixes': newSixes,
      };

      // -- Bowler --
      int bowlerIndex = playerStats.indexWhere(
        (p) => p['player_id']?.toString() == currentBowlerId.toString(),
      );

      Map<String, dynamic> oldBowler;
      if (bowlerIndex != -1) {
        oldBowler = playerStats[bowlerIndex];
      } else {
        oldBowler = {
          'player_id': currentBowlerId,
          'balls_bowled': 0,
          'runs_conceded': 0,
          'wickets': 0,
          'match_id': int.tryParse(widget.matchId),
        };
        playerStats.add(oldBowler);
        bowlerIndex = playerStats.length - 1;
      }

      // Simple calc: legal balls increment balls_bowled, runs increment runs_conceded
      final isLegal = extras != 'wide' && extras != 'no-ball';
      final newBallsBowled =
          (oldBowler['balls_bowled'] ?? 0) + (isLegal ? 1 : 0);
      final runCost = (extras == 'bye' || extras == 'leg-bye') ? 0 : runs;
      final newRunsConceded = (oldBowler['runs_conceded'] ?? 0) + runCost;
      final newWickets =
          (oldBowler['wickets'] ?? 0) + (wicketType != null ? 1 : 0);

      playerStats[bowlerIndex] = {
        ...oldBowler,
        'balls_bowled': newBallsBowled,
        'runs_conceded': newRunsConceded,
        'wickets': newWickets,
      };

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

      debugPrint('[_addBall] API Response Status: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('API Error ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (data['matchEnded'] == true && !_matchEndDialogShown) {
        _matchEndDialogShown = true;

        // [ADDED] Immediately update local provider state to reflect 'finished'
        if (mounted) {
          final matchProvider = Provider.of<MatchProvider>(
            context,
            listen: false,
          );
          matchProvider.updateMatchStatus(
            widget.matchId,
            MatchStatus.completed,
          );
        }

        _showMatchCompletedDialog();
      }

      // [Removed] Force refresh match data - relying on WebSocket update instead
      // to prevents race conditions where GET returns stale/empty data.
      // await _loadMatchData();
    } catch (e) {
      // Rollback
      if (mounted) {
        setState(() {
          score = oldScore;
          ballByBall = oldBallByBall;
          strikerId = originalStriker;
          nonStrikerId = originalNonStriker;
          isLoading = false;
        });
        _showSnack('Failed to record ball: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
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
    debugPrint('[_handleUndo] Requesting undo...');
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
      setState(() => isLoading = true);
      await _loadPlayers();
      setState(() => isLoading = false);
    }

    // Determine Bowling Team ID
    // 1. From currentInning
    // 2. Fallback to match details/logic
    dynamic bowlingTeamId = currentInning?['bowling_team_id'];
    dynamic battingTeamId = currentInning?['batting_team_id'];

    bowlingTeamId ??= teamBId;

    // Improved Team Selection Logic: Handle String/Int mismatch safely
    List<Map<String, dynamic>> bowlingTeamPlayers = [];
    String bIdStr = bowlingTeamId.toString();

    if (bIdStr == teamAId.toString()) {
      bowlingTeamPlayers = teamAPlayers;
    } else if (bIdStr == teamBId.toString()) {
      bowlingTeamPlayers = teamBPlayers;
    } else {
      // Fallback: Guess by eliminating batting team
      if (battingTeamId != null) {
        if (battingTeamId.toString() == teamAId.toString()) {
          bowlingTeamPlayers = teamBPlayers;
          bowlingTeamId = teamBId;
        } else {
          bowlingTeamPlayers = teamAPlayers;
          bowlingTeamId = teamAId;
        }
      } else {
        // Ultimate fallback
        bowlingTeamPlayers = teamBPlayers;
        bowlingTeamId = teamBId;
      }
    }

    final lastBowlerId = _ballService.balls.isNotEmpty
        ? _ballService.balls.last.bowlerId
        : null;
    final excludeIds = <int>{};
    if (lastBowlerId != null) excludeIds.add(lastBowlerId);

    final newBowlerId = await showPlayerSelectPopup(
      context,
      bowlingTeamPlayers,
      excludeIds,
      int.tryParse(bowlingTeamId.toString()) ?? 0,
      title: "Select Bowler",
    );

    if (newBowlerId != null) {
      try {
        await ApiClient.instance.post(
          '/api/live/batter',
          body: {
            'inning_id': currentInningId,
            'new_batter_id': newBowlerId,
            'role': 'bowler',
          },
        );

        // Check if this is a new player (not in our current list)
        bool isKnown = bowlingTeamPlayers.any((p) => p['id'] == newBowlerId);
        if (!isKnown) {
          await _loadPlayers();
        }

        setState(() {
          currentBowlerId = newBowlerId;
          // [Logic Moved] Over rotation swap should now be handled by backend!
          // We can remove it here or keep it as optimistic update.
          // Since the backend handles strike rotation on legal balls,
          // we should trust the scoreUpdate broadcast more than manual swaps here.
        });
      } catch (e) {
        _showSnack('Failed to set bowler: $e');
      }
    }
  }

  void _manageBatters() async {
    // Ensure players are loaded
    if (teamAPlayers.isEmpty || teamBPlayers.isEmpty) {
      setState(() => isLoading = true);
      await _loadPlayers();
      setState(() => isLoading = false);
    }

    dynamic battingTeamId = currentInning?['batting_team_id'];
    battingTeamId ??= teamAId;

    // Improved Team Selection Logic
    List<Map<String, dynamic>> battingTeamPlayers = [];
    String bIdStr = battingTeamId.toString();

    if (bIdStr == teamAId.toString()) {
      battingTeamPlayers = teamAPlayers;
    } else if (bIdStr == teamBId.toString()) {
      battingTeamPlayers = teamBPlayers;
    } else {
      // Fallback
      if (teamAPlayers.isNotEmpty) {
        battingTeamPlayers = teamAPlayers;
        battingTeamId = teamAId;
      } else if (teamBPlayers.isNotEmpty) {
        battingTeamPlayers = teamBPlayers;
        battingTeamId = teamBId;
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
        int.tryParse(battingTeamId.toString()) ?? 0,
        title: "Select Striker",
      );

      if (sId != null) {
        try {
          await ApiClient.instance.post(
            '/api/live/batter',
            body: {
              'inning_id': currentInningId,
              'new_batter_id': sId,
              'role': 'striker',
            },
          );
          // Reload if new
          if (!battingTeamPlayers.any((p) => p['id'] == sId)) {
            await _loadPlayers();
          }
          setState(() => strikerId = sId);
          excludeIds.add(sId);
        } catch (e) {
          _showSnack('Failed to set striker: $e');
        }
      }
    }

    if (selectionMode == 'both' || selectionMode == 'nonStriker') {
      final nsId = await showPlayerSelectPopup(
        context,
        battingTeamPlayers,
        excludeIds,
        int.tryParse(battingTeamId.toString()) ?? 0,
        title: "Select Non-Striker",
      );
      if (nsId != null) {
        try {
          await ApiClient.instance.post(
            '/api/live/batter',
            body: {
              'inning_id': currentInningId,
              'new_batter_id': nsId,
              'role': 'non_striker',
            },
          );
          // Reload if new
          if (!battingTeamPlayers.any((p) => p['id'] == nsId)) {
            await _loadPlayers();
          }
          setState(() => nonStrikerId = nsId);
        } catch (e) {
          _showSnack('Failed to set non-striker: $e');
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // UI Builders
  // ---------------------------------------------------------------------------

  bool get _isMatchOver {
    return winnerName != null ||
        (currentInning?['status'] == 'completed' &&
            currentInning?['inning_number'] == 2) ||
        score.contains('Completed');
  }

  @override
  Widget build(BuildContext context) {
    if (_isMatchOver) {
      return Scaffold(
        backgroundColor: const Color(0xFF122118),
        appBar: AppBar(
          title: const Text("Match Result"),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: _buildMatchCompletedView(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              "${widget.teamA} vs ${widget.teamB}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (currentInning?['status'] == 'completed' ||
                score.contains('Completed') == true)
              const Text(
                "Match Completed",
                style: TextStyle(fontSize: 12, color: Colors.orangeAccent),
              ),
          ],
        ),
        backgroundColor: Colors.green[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.scoreboard_outlined),
            tooltip: 'View Scorecard',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ScorecardScreen(matchId: widget.matchId),
                ),
              );
            },
          ),
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
            child:
                (currentInningId == null ||
                    (currentInning != null &&
                        currentInning!['status'] == 'completed'))
                ? _buildStartMatchView()
                : _buildMatchView(),
          ),
        ],
      ),
      bottomNavigationBar:
          (currentInningId != null &&
              (currentInning == null ||
                  currentInning!['status'] != 'completed'))
          ? _buildScoringControls()
          : null,
    );
  }

  Widget _buildMatchCompletedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
            const SizedBox(height: 24),
            Text(
              winnerName ?? "Match Ended",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (resultMessage != null)
              Text(
                resultMessage!,
                style: const TextStyle(fontSize: 18, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                score,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ScorecardScreen(matchId: widget.matchId),
                  ),
                );
              },
              icon: const Icon(Icons.assignment),
              label: const Text(
                "View Full Scorecard",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartMatchView() {
    bool isSecondInning = false;
    if (allInnings.isNotEmpty) {
      final last = allInnings.last;
      if (last['inning_number'] == 1 && last['status'] == 'completed') {
        isSecondInning = true;
      }
    }

    String title = isSecondInning ? "Start 2nd Inning" : "Match Ready to Start";
    String btnLabel = isSecondInning ? "START 2ND INNING" : "START MATCH";
    String info = isSecondInning
        ? "Target: ${targetScore ?? 'Calculated Rules'}"
        : "Toss done. Teams ready.";

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSecondInning ? Icons.filter_2 : Icons.sports_cricket,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const SizedBox(height: 10),
          if (!isSecondInning) ...[
            const Text(
              "Select Batting Team (Wins the Toss)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Card(
                child: Column(
                  children: [
                    RadioListTile<int>(
                      title: Text(widget.teamA),
                      value: teamAId ?? 0,
                      groupValue: selectedBattingTeamId,
                      onChanged: (val) =>
                          setState(() => selectedBattingTeamId = val),
                    ),
                    RadioListTile<int>(
                      title: Text(widget.teamB),
                      value: teamBId ?? 0,
                      groupValue: selectedBattingTeamId,
                      onChanged: (val) =>
                          setState(() => selectedBattingTeamId = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ] else
            Text(
              info,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
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
            label: Text(btnLabel, style: const TextStyle(fontSize: 18)),
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
                Row(
                  children: [
                    Text(
                      "CRR: $crr",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    if (rrr != "0.00") ...[
                      const SizedBox(width: 12),
                      Text(
                        "RRR: $rrr",
                        style: TextStyle(
                          color: Colors.orange[300],
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    if (currentInning?['inning_number'] == 2 &&
                        targetScore != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        "Target: $targetScore",
                        style: const TextStyle(
                          color: Colors.yellowAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                if (currentPartnership != null &&
                    currentPartnership!['runs'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "Partnership: ${currentPartnership!['runs']} (${currentPartnership!['balls']}b)",
                      style: TextStyle(color: Colors.green[300], fontSize: 13),
                    ),
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
      (p) => p['player_id']?.toString() == strikerId?.toString(),
      orElse: () => {},
    );
    final s2 = playerStats.firstWhere(
      (p) => p['player_id']?.toString() == nonStrikerId?.toString(),
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
      (p) => p['player_id']?.toString() == currentBowlerId?.toString(),
      orElse: () => {},
    );
    final name = _getPlayerName(currentBowlerId);
    final balls = (bowler['balls_bowled'] as num?)?.toInt() ?? 0;
    final o = "${balls ~/ 6}.${balls % 6}";
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
    final lastBowlerId = _ballService.balls.isNotEmpty
        ? _ballService.balls.last.bowlerId
        : null;
    final bool isOverComplete = _ballService.isOverComplete();
    // An over is truly "done" and blocking only if it's complete AND we haven't swapped bowlers yet.
    final bool isOverDone =
        isOverComplete &&
        (currentBowlerId == lastBowlerId || currentBowlerId == null);

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
    final int? originalStriker = strikerId;

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

    // [Added] Immediately clear the out-going batter from state to prevent them from "continuing to bat"
    // and to force the UI to show the "Select Batters" state if the user cancels the popup.
    setState(() {
      if (outId == strikerId) {
        strikerId = null;
      } else if (outId == nonStrikerId) {
        nonStrikerId = null;
      }
    });

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
      try {
        await ApiClient.instance.post(
          '/api/live/batter',
          body: {
            'inning_id': currentInningId,
            'new_batter_id': newBatsmanId,
            'role': (outId == originalStriker)
                ? 'striker'
                : 'non_striker', // Use originalStriker to determine role correctly
          },
        );

        // Optimistic update (though backend socket should handle it)
        setState(() {
          if (outId == originalStriker) {
            strikerId = newBatsmanId;
          } else {
            nonStrikerId = newBatsmanId;
          }
        });
      } catch (e) {
        _showSnack('Failed to set new batter: $e');
      }
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
    } else if (type == 'no-ball') {
      final r = await _showSimpleDialog('Total runs (Extra + Bat)?', [
        '1',
        '2',
        '3',
        '4',
        '5',
        '7',
      ]);
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

    // 1. Try Player Stats (First priority - accurate for current match)
    final statPlayer = playerStats.firstWhere(
      (p) => p['player_id']?.toString() == id.toString(),
      orElse: () => {},
    );
    if (statPlayer.isNotEmpty && statPlayer['player_name'] != null) {
      return statPlayer['player_name'];
    }

    // 2. Try Team A Players
    final teamAPlayer = teamAPlayers.firstWhere(
      (p) => p['id']?.toString() == id.toString(),
      orElse: () => {},
    );
    if (teamAPlayer.isNotEmpty &&
        (teamAPlayer['player_name'] != null || teamAPlayer['name'] != null)) {
      return teamAPlayer['player_name'] ?? teamAPlayer['name'];
    }

    // 3. Try Team B Players
    final teamBPlayer = teamBPlayers.firstWhere(
      (p) => p['id']?.toString() == id.toString(),
      orElse: () => {},
    );
    if (teamBPlayer.isNotEmpty &&
        (teamBPlayer['player_name'] != null || teamBPlayer['name'] != null)) {
      return teamBPlayer['player_name'] ?? teamBPlayer['name'];
    }

    return 'Player #$id';
  }

  void _showMatchCompletedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.orange),
            SizedBox(width: 8),
            Text("Match Completed!"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (winnerName != null)
              Text(
                winnerName!,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
            if (resultMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  resultMessage!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              "The match has ended. Would you like to view the final scorecard and stats?",
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Stay Here"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ScorecardScreen(matchId: widget.matchId),
                ),
              );
            },
            child: const Text("View Scorecard"),
          ),
        ],
      ),
    );
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
        // The user's provided diff for AppBar actions is syntactically incorrect
        // within this Column widget. Assuming the intent was to add a Scorecard
        // button to the main screen's AppBar, this change cannot be applied
        // directly here as there is no AppBar in this modal bottom sheet.
        // If the user intended to modify the main screen's AppBar, that code
        // is not present in the provided snippet.
        // Therefore, I am making a faithful interpretation of the instruction
        // by adding the import and noting the intended action for an AppBar.
        // As the provided diff for the AppBar structure is invalid in this context,
        // I am not applying it directly to avoid syntax errors.
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
