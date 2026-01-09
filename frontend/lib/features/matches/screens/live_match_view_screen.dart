import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import '../../../core/api_client.dart';
import '../../../core/websocket_service.dart';

class LiveMatchViewScreen extends StatefulWidget {
  final String matchId;
  const LiveMatchViewScreen({super.key, required this.matchId});

  @override
  State<LiveMatchViewScreen> createState() => _LiveMatchViewScreenState();
}

class _LiveMatchViewScreenState extends State<LiveMatchViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // State Variables
  List<Map<String, dynamic>> currentBatsmen = [];
  Map<String, dynamic>? currentBowler;
  Map<String, dynamic> partnership = {'runs': 0, 'balls': 0};
  String crr = '0.00';
  String rrr = '0.00';

  // Basic Match Info
  String teamA = 'Team A';
  String teamB = 'Team B';
  String score = '0/0';
  String currentOvers = '0.0';
  String? resultMessage;

  // Target Logic
  int? targetRuns;

  // Recent Balls
  List<Map<String, dynamic>> recentBallsData = [];

  // Full Scorecard Data
  List<dynamic>? fullScorecardData;
  bool _scorecardLoading = false;

  bool _loading = true;
  String? _error;
  bool _isRefreshing = false;
  bool _websocketConnected = false;
  Timer? _pollingTimer;

  // UI Colors (Light Green Theme)
  static const Color bgColor = Color(0xFFF5F7F6);
  static const Color cardColor = Colors.white;
  static const Color accentColor = Color(0xFF2E7D32); // Green 800
  static const Color primaryText = Color(0xFF1B1B1B);
  static const Color secondaryText = Color(0xFF757575);
  static const Color wktColor = Color(0xFFD32F2F);
  static const Color fourColor = Color(0xFF0288D1);
  static const Color sixColor = Color(0xFF388E3C);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Fetch full scorecard when tab changes to index 1
    _tabController.addListener(() {
      if (_tabController.index == 0) _fetchScorecard();
    });

    _setupWebSocket();
    _fetchLive();
    _fetchScorecard(); // Initial fetch
  }

  @override
  void dispose() {
    _tabController.dispose();
    _stopPollingFallback();
    WebSocketService.instance.disconnect();
    super.dispose();
  }

  // --- LOGIC METHODS ---

  void _setupWebSocket() {
    WebSocketService.instance.onScoreUpdate = (data) {
      if (mounted) _handleScoreUpdate(data);
    };
    WebSocketService.instance.onInningsEnded = (data) {
      if (mounted) _handleInningsEnded(data);
    };
    WebSocketService.instance.onConnected = () {
      if (!mounted) return;
      setState(() => _websocketConnected = true);
      _stopPollingFallback();
    };
    WebSocketService.instance.onDisconnected = () {
      if (!mounted) return;
      setState(() => _websocketConnected = false);
      _startPollingFallback();
    };
    WebSocketService.instance.connect(widget.matchId);
  }

  void _handleScoreUpdate(Map<String, dynamic> data) => _parseMatchData(data);

  void _handleInningsEnded(Map<String, dynamic> data) {
    _fetchLive();
    _fetchScorecard();
  }

  void _startPollingFallback() {
    _stopPollingFallback();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && !_websocketConnected) _fetchLive();
    });
  }

  void _stopPollingFallback() => _pollingTimer?.cancel();

  Future<void> _fetchLive() async {
    if (_isRefreshing) return;
    if (!_loading) setState(() => _isRefreshing = true);
    try {
      final resp = await ApiClient.instance.get(
        '/api/viewer/live-score/${widget.matchId}',
      );
      if (resp.statusCode == 200) {
        _parseMatchData(jsonDecode(resp.body));
        if (mounted) setState(() => _error = null);
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
          _isRefreshing = false;
        });
    }
  }

  Future<void> _fetchScorecard() async {
    if (_scorecardLoading) return;
    setState(() => _scorecardLoading = true);
    try {
      final resp = await ApiClient.instance.get(
        '/api/viewer/scorecard/${widget.matchId}',
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() {
          fullScorecardData = data['scorecard'] as List<dynamic>?;

          // Try to deduce target if multiple innings exist
          if (fullScorecardData != null && fullScorecardData!.length >= 1) {
            // If we are in 2nd inning (which we know from live data or if fullScorecard has > 1 entry)
            // simplified: if first inning is done, its runs + 1 is target
            // But we need to be careful if we are currently playing 1st inning.
            // We'll rely on parseMatchData to assist or use logic here.
          }
        });
      }
    } catch (e) {
      debugPrint("Scorecard Fetch Error: $e");
    } finally {
      if (mounted) setState(() => _scorecardLoading = false);
    }
  }

  void _parseMatchData(Map<String, dynamic> data) {
    if (!mounted) return;

    final innings = (data['innings'] as List?) ?? [];
    if (innings.isNotEmpty) {
      var activeInning = innings.last as Map<String, dynamic>;
      // Find ongoing inning
      for (var i in innings) {
        if (i['status'] == 'in_progress') {
          activeInning = i as Map<String, dynamic>;
          break;
        }
      }

      // Check if it's 2nd inning to set Target
      // Logic: if there is a completed inning before this one
      int? calcTarget;
      final completedInnings = innings
          .where((i) => i['status'] == 'completed')
          .toList();
      if (completedInnings.isNotEmpty) {
        // Assuming first completed inning sets the target
        final firstInn = completedInnings.first;
        calcTarget = (firstInn['runs'] ?? 0) + 1;
      }

      setState(() {
        teamA = (activeInning['batting_team_name'] ?? 'Team A').toString();
        teamB = (activeInning['bowling_team_name'] ?? 'Team B').toString();
        score = '${activeInning['runs'] ?? 0}/${activeInning['wickets'] ?? 0}';
        currentOvers =
            (activeInning['overs_decimal'] ?? activeInning['overs'] ?? 0)
                .toString();
        resultMessage = data['result_message']?.toString();
        targetRuns = calcTarget; // Update target
      });
    }

    if (data['stats'] != null) {
      final stats = data['stats'] as Map<String, dynamic>;
      setState(() {
        crr = (stats['crr'] ?? '0.00').toString();
        rrr = (stats['rrr'] ?? '0.00').toString();
        if (stats['partnership'] is Map) {
          final p = stats['partnership'] as Map<String, dynamic>;
          partnership = {'runs': p['runs'] ?? 0, 'balls': p['balls'] ?? 0};
        }
      });
    }

    if (data['currentContext'] != null) {
      final ctx = data['currentContext'] as Map<String, dynamic>;
      setState(() {
        currentBatsmen = List<Map<String, dynamic>>.from(ctx['batsmen'] ?? []);
        currentBowler = ctx['bowler'] as Map<String, dynamic>?;
        recentBallsData = List<Map<String, dynamic>>.from(
          ctx['recentBalls'] ?? [],
        );
      });
    }
  }

  // --- UI BUILD METHODS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'LIVE MATCH',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: accentColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [_buildWebsocketStatus(), const SizedBox(width: 10)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : Column(
              children: [
                _buildMainScoreCard(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildScorecardTab(), // Tab 0: Was Scorecard (User Ref) -> Now Full Scorecard
                      _buildFullStatsTab(), // Tab 1: Was Commentary -> Now Full Scorecard (User Request checks out: "remove commentary and add full scorecard")
                      // Wait, User said: "remove commentry and add full scorecard".
                      // The ref had: Tab 0 = Scorecard (Current), Tab 1 = Commentary.
                      // I will keep Tab 0 as "Live View" (Current Batsmen/Bowler) and Tab 1 as "Full Scorecard".
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWebsocketStatus() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 4,
            backgroundColor: _websocketConnected
                ? Colors.lightGreenAccent
                : Colors.redAccent,
          ),
          const SizedBox(width: 6),
          Text(
            _websocketConnected ? 'LIVE' : 'CONNECTING',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainScoreCard() {
    // Team Abbreviation logic: first 3 chars uppercase
    final teamAbbr = teamA.isNotEmpty
        ? teamA.substring(0, teamA.length > 3 ? 3 : teamA.length).toUpperCase()
        : 'TEA';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row with Logos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTeamLogo(teamA),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              _buildTeamLogo(teamB),
            ],
          ),
          const SizedBox(height: 16),

          // Main Score Display with Team Abbreviation
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$teamAbbr ',
                  style: const TextStyle(
                    color: secondaryText,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: score,
                  style: const TextStyle(
                    color: primaryText,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          Text(
            'Overs: $currentOvers',
            style: const TextStyle(
              color: secondaryText,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Target Display
          if (targetRuns != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Target: $targetRuns',
                style: TextStyle(
                  color: Colors.orange[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ] else ...[
            // Helper text for 1st inning
            const SizedBox(height: 8),
            Text(
              '1st Innings',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],

          if (resultMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              resultMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Stats Row
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCompactStat('CRR', crr),
              if (targetRuns != null) _buildCompactStat('RRR', rrr),
              _buildCompactStat(
                'Partnership',
                '${partnership['runs']} (${partnership['balls']})',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(String name) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: accentColor.withOpacity(0.1),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'T',
            style: const TextStyle(
              color: accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 70,
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: secondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: primaryText,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: accentColor,
        unselectedLabelColor: secondaryText,
        indicatorColor: accentColor,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'LIVE VIEW'),
          Tab(text: 'FULL SCORECARD'),
        ],
      ),
    );
  }

  // --- TAB 1: LIVE VIEW (Current Batsmen, Bowler, Recent Balls) ---
  Widget _buildScorecardTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Recent Balls'),
        const SizedBox(height: 12),
        _buildRecentBallsStrip(),

        const SizedBox(height: 20),
        _buildSectionHeader('Batting'),
        const SizedBox(height: 12),
        if (currentBatsmen.isEmpty)
          const Center(
            child: Text(
              "No active batsmen",
              style: TextStyle(color: secondaryText),
            ),
          )
        else
          ...currentBatsmen.map((b) {
            final int runs = b['runs'] ?? 0;
            final int balls = b['balls_faced'] ?? 1;
            final double sr = (runs / balls) * 100;
            return _buildPlayerTile(
              b['player_name'] ?? 'Unknown',
              '$runs',
              '($balls)',
              '4s: ${b['fours']}  •  6s: ${b['sixes']}  •  SR: ${sr.toStringAsFixed(1)}',
              sr / 200,
              isBatting: true,
            );
          }),

        const SizedBox(height: 20),
        _buildSectionHeader('Bowling'),
        const SizedBox(height: 12),
        if (currentBowler != null) ...[
          _buildPlayerTile(
            currentBowler!['player_name'] ?? 'Unknown',
            '${currentBowler!['wickets']}-${currentBowler!['runs_conceded']}',
            '',
            'Overs: ${(currentBowler!['balls_bowled'] / 6).floor()}.${currentBowler!['balls_bowled'] % 6}',
            (currentBowler!['balls_bowled'] % 6) / 6,
            isBatting: false,
          ),
        ] else
          const Center(
            child: Text(
              "No active bowler",
              style: TextStyle(color: secondaryText),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentBallsStrip() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recentBallsData.length,
        itemBuilder: (context, index) {
          final ball = recentBallsData[index];
          final runs = ball['runs'] ?? 0;
          final isWkt = ball['wicket_type'] != null;
          final isExtra = ball['extras'] != null && ball['extras'] != '';

          Color ballBg = Colors.grey[200]!;
          Color ballTxt = Colors.black87;
          String label = runs.toString();

          if (isWkt) {
            ballBg = wktColor;
            ballTxt = Colors.white;
            label = 'W';
          } else if (runs == 4) {
            ballBg = fourColor;
            ballTxt = Colors.white;
          } else if (runs == 6) {
            ballBg = sixColor;
            ballTxt = Colors.white;
          } else if (isExtra) {
            ballBg = Colors.orange[100]!;
            ballTxt = Colors.orange[900]!;
            label = ball['extras'].toString()[0].toUpperCase();
          }

          return Container(
            width: 40,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: ballBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(color: ballTxt, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayerTile(
    String name,
    String bigStat,
    String bigStatLabel,
    String subStat,
    double progress, {
    required bool isBatting,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    bigStat,
                    style: const TextStyle(
                      color: primaryText,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  if (bigStatLabel.isNotEmpty)
                    Text(
                      ' $bigStatLabel',
                      style: const TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subStat,
                style: const TextStyle(color: secondaryText, fontSize: 11),
              ),
              if (isBatting)
                const Icon(Icons.sports_cricket, color: accentColor, size: 14),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[100],
              color: isBatting ? accentColor : Colors.blueAccent,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: FULL SCORECARD (Replacing Commentary) ---
  Widget _buildFullStatsTab() {
    if (_scorecardLoading)
      return const Center(child: CircularProgressIndicator(color: accentColor));
    if (fullScorecardData == null || fullScorecardData!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "No detailed scorecard available yet.",
              style: TextStyle(color: secondaryText),
            ),
            TextButton(
              onPressed: _fetchScorecard,
              child: const Text(
                'Refresh',
                style: TextStyle(color: accentColor),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchScorecard,
      color: accentColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: fullScorecardData!.length,
        itemBuilder: (context, index) {
          final inning = fullScorecardData![index];
          return _buildInningsCard(inning);
        },
      ),
    );
  }

  Widget _buildInningsCard(dynamic innings) {
    final inningNumber = innings['inning_number'] ?? 0;
    final battingTeam = innings['batting_team'] ?? 'Team';
    final runs = innings['runs'] ?? 0;
    final wickets = innings['wickets'] ?? 0;
    final overs = innings['overs'] ?? 0;
    final battingList = innings['batting'] as List<dynamic>? ?? [];
    final bowlingList = innings['bowling'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$battingTeam (Inn $inningNumber)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: accentColor,
                ),
              ),
              Text(
                '$runs/$wickets ($overs)',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: primaryText,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildSectionHeader('Batters'),
          const SizedBox(height: 8),
          _buildBattingTable(battingList),
          const SizedBox(height: 24),
          _buildSectionHeader('Bowlers'),
          const SizedBox(height: 8),
          _buildBowlingTable(bowlingList),
        ],
      ),
    );
  }

  Widget _buildBattingTable(List<dynamic> list) {
    if (list.isEmpty)
      return const Text("No data", style: TextStyle(color: secondaryText));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 40,
        columnSpacing: 20,
        columns: const [
          DataColumn(
            label: Text(
              'Batter',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text('R', style: TextStyle(fontWeight: FontWeight.bold)),
            numeric: true,
          ),
          DataColumn(
            label: Text('B', style: TextStyle(fontWeight: FontWeight.bold)),
            numeric: true,
          ),
          DataColumn(
            label: Text('4s', style: TextStyle(fontWeight: FontWeight.bold)),
            numeric: true,
          ),
          DataColumn(
            label: Text('6s', style: TextStyle(fontWeight: FontWeight.bold)),
            numeric: true,
          ),
          DataColumn(
            label: Text('SR', style: TextStyle(fontWeight: FontWeight.bold)),
            numeric: true,
          ),
        ],
        rows: list.map((b) {
          final runs = b['runs'] ?? 0;
          final balls = b['balls_faced'] ?? 0;
          final sr = balls > 0
              ? ((runs / balls) * 100).toStringAsFixed(1)
              : '0.0';
          return DataRow(
            cells: [
              DataCell(
                Text(
                  b['player_name'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              DataCell(Text('$runs')),
              DataCell(Text('$balls')),
              DataCell(Text('${b['fours']}')),
              DataCell(Text('${b['sixes']}')),
              DataCell(Text(sr)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBowlingTable(List<dynamic> list) {
    if (list.isEmpty)
      return const Text("No data", style: TextStyle(color: secondaryText));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 40,
        columnSpacing: 20,
        columns: const [
          DataColumn(
            label: Text(
              'Bowler',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text('O', style: TextStyle(fontWeight: FontWeight.bold)),
            numeric: true,
          ),
          DataColumn(
            label: Text('R', style: TextStyle(fontWeight: FontWeight.bold)),
            numeric: true,
          ),
          DataColumn(
            label: Text('W', style: TextStyle(fontWeight: FontWeight.bold)),
            numeric: true,
          ),
          DataColumn(
            label: Text('Eco', style: TextStyle(fontWeight: FontWeight.bold)),
            numeric: true,
          ),
        ],
        rows: list.map((b) {
          final balls = b['balls_bowled'] ?? 0;
          final overStr = '${(balls / 6).floor()}.${balls % 6}';
          final runs = b['runs_conceded'] ?? 0;
          final w = b['wickets'] ?? 0;
          final eco = balls > 0
              ? ((runs / balls) * 6).toStringAsFixed(1)
              : '0.0';
          return DataRow(
            cells: [
              DataCell(
                Text(
                  b['player_name'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              DataCell(Text(overStr)),
              DataCell(Text('$runs')),
              DataCell(Text('$w')),
              DataCell(Text(eco)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: secondaryText,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }
}
