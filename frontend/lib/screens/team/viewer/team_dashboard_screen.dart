import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/api_client.dart';
import '../../../widgets/bottom_nav.dart';

class TeamDashboardScreen extends StatefulWidget {
  final int teamId;
  final String? teamName;
  const TeamDashboardScreen({super.key, required this.teamId, this.teamName});

  @override
  State<TeamDashboardScreen> createState() => _TeamDashboardScreenState();
}

class _TeamDashboardScreenState extends State<TeamDashboardScreen> {
  bool _loading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String teamName = '';
  String imageUrl = '';
  int trophies = 0;
  List<Map<String, dynamic>> players = [];

  @override
  void initState() {
    super.initState();
    teamName = widget.teamName ?? '';
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final teamResp = await ApiClient.instance.get(
        '/api/teams/${widget.teamId}',
      );

      if (teamResp.statusCode == 200) {
        final t = jsonDecode(teamResp.body) as Map<String, dynamic>;
        teamName = (t['team_name'] ?? teamName).toString();
        trophies = (t['trophies'] ?? 0) is int
            ? t['trophies']
            : int.tryParse(t['trophies'].toString()) ?? 0;
        imageUrl = (t['team_logo_url'] ?? '').toString();
      } else if (teamResp.statusCode == 404) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Team not found';
        });
        return;
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load team data (${teamResp.statusCode})';
        });
        return;
      }

      final pResp = await ApiClient.instance.get(
        '/api/players/team/${widget.teamId}',
      );

      if (pResp.statusCode == 200) {
        players = List<Map<String, dynamic>>.from(jsonDecode(pResp.body));
      } else {
        // Players are optional, so we don't treat this as a fatal error
        players = [];
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Network error: ${e.toString()}';
      });
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _fetch();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Go Back',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use players fetched from backend
    final players = this.players;

    return Scaffold(
      backgroundColor: const Color(0xFF122118),
      appBar: AppBar(
        backgroundColor: const Color(0xFF122118),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Team Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? _buildErrorState()
          : SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Team header
                    Column(
                      children: [
                        Stack(
                          children: [
                            SizedBox(
                              height: 112,
                              width: 112,
                              child: ClipOval(
                                child: Image.network(
                                  imageUrl.isNotEmpty
                                      ? imageUrl
                                      : 'https://picsum.photos/200',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) {
                                    return Container(
                                      color: const Color(0xFF2A3C32),
                                      child: const Icon(
                                        Icons.shield,
                                        color: Colors.white54,
                                        size: 44,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF122118),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.shield,
                                  color: Color(0xFF20DF6C),
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          teamName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$trophies Trophies',
                          style: const TextStyle(color: Color(0xFF95C6A9)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Players title
                    Row(
                      children: const [
                        Text(
                          'Players',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Player list
                    Column(
                      children: players.map((p) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1a2c22),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/player/view',
                                arguments: {
                                  'playerName':
                                      (p['player_name'] ?? p['name'] ?? '')
                                          .toString(),
                                  'role': (p['player_role'] ?? p['role'] ?? '')
                                      .toString(),
                                  'teamName': teamName,
                                  'imageUrl':
                                      (p['image'] ??
                                              'https://picsum.photos/200')
                                          .toString(),
                                  'runs':
                                      int.tryParse(
                                        p['runs']?.toString() ?? '',
                                      ) ??
                                      0,
                                  'battingAvg':
                                      double.tryParse(
                                        p['batting_average']?.toString() ??
                                            p['avg']?.toString() ??
                                            '',
                                      ) ??
                                      0,
                                  'strikeRate':
                                      double.tryParse(
                                        p['strike_rate']?.toString() ??
                                            p['sr']?.toString() ??
                                            '',
                                      ) ??
                                      0,
                                  'wickets':
                                      int.tryParse(
                                        p['wickets']?.toString() ?? '',
                                      ) ??
                                      0,
                                },
                              );
                            },
                            leading: const CircleAvatar(
                              radius: 20,
                              child: Icon(Icons.person),
                            ),
                            title: Text(
                              (p['player_name'] ?? p['name'] ?? '').toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              (p['player_role'] ?? p['role'] ?? '').toString(),
                              style: const TextStyle(color: Color(0xFF95C6A9)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 18),
                    // Start match button (viewer should not start — but placed visually as in HTML)
                    const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (i) {
          // keep local behaviour: pop on Home tap
          if (i == 0) Navigator.popUntil(context, (route) => route.isFirst);
        },
        backgroundColor: const Color(0xFF1B3224),
        selectedColor: const Color(0xFF20DF6C),
        unselectedColor: const Color(0xFF95C6A9),
      ),
    );
  }
}
