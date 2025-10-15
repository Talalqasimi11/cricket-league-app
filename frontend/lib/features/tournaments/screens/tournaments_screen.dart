// lib/features/tournaments/screens/tournaments_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/api_client.dart';
import 'tournament_create_screen.dart';
import 'tournament_draws_screen.dart' as draws; // ✅ alias to avoid conflicts
import '../widgets/tournament_card.dart';
import '../widgets/tournament_filter_tabs.dart';
import '../models/tournament_model.dart';
import 'tournament_details_viewer_screen.dart';

class TournamentsScreen extends StatefulWidget {
  final bool isCaptain; // pass true for captain, false for viewer

  const TournamentsScreen({super.key, this.isCaptain = false});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  int selectedTab = 0;

  bool _loading = false;
  List<Map<String, dynamic>> _tournaments = [];
  int? _userId; // decoded from JWT for "My Tournaments" filter

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _fetchTournaments();
  }

  Future<void> _loadUserId() async {
    try {
      final token = await ApiClient.instance.token;
      if (token == null) return;
      final parts = token.split('.');
      if (parts.length != 3) return;
      String normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      final payload = jsonDecode(utf8.decode(base64.decode(normalized))) as Map<String, dynamic>;
      setState(() {
        _userId = int.tryParse(payload['id']?.toString() ?? '') ?? (_userId ?? 0);
      });
    } catch (_) {
      // ignore decode errors
    }
  }

  Future<void> _fetchTournaments() async {
    setState(() => _loading = true);
    try {
      final resp = await http.get(Uri.parse('${ApiClient.baseUrl}/api/tournaments/'));
      if (resp.statusCode == 200) {
        final List<dynamic> list = List<dynamic>.from(jsonDecode(resp.body));
        setState(() {
          _tournaments = list.cast<Map<String, dynamic>>();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load tournaments (${resp.statusCode})')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tournaments: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openTournament(Map<String, dynamic> t) async {
    final id = t['id'];
    try {
final matchesResp = await http.get(Uri.parse('${ApiClient.baseUrl}/api/tournament-matches/$id'));
      List<MatchModel> matches = [];
      if (matchesResp.statusCode == 200) {
        final List<dynamic> rows = List<dynamic>.from(jsonDecode(matchesResp.body));
        matches = rows.map((r) {
          final m = r as Map<String, dynamic>;
          DateTime? dt;
          final md = m['match_date'];
          if (md != null && md.toString().isNotEmpty) {
            // attempt to parse; backend may return ISO or SQL date string
            try { dt = DateTime.parse(md.toString()); } catch (_) { dt = null; }
          }
          return MatchModel(
            id: (m['id'] ?? '').toString(),
            teamA: (m['team1_name'] ?? 'TBD').toString(),
            teamB: (m['team2_name'] ?? 'TBD').toString(),
            scheduledAt: dt,
            status: (m['status'] ?? 'upcoming').toString(),
          );
        }).toList();
      }

      final model = TournamentModel(
        id: t['id'].toString(),
        name: (t['tournament_name'] ?? 'Tournament').toString(),
        status: 'upcoming',
        type: 'Knockout',
        dateRange: (t['start_date'] ?? '').toString(),
        location: (t['location'] ?? '').toString(),
        overs: 20,
        teams: const [],
        matches: matches,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TournamentDetailsViewerScreen(tournament: model),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tournament details: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tournaments"),
        centerTitle: true,
        backgroundColor: Colors.green[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // 🔹 Filter tabs (All / My Tournaments / Past)
            TournamentFilterTabs(
              selectedIndex: selectedTab,
              onChanged: (index) {
                setState(() => selectedTab = index);
              },
            ),
            const SizedBox(height: 16),

            // 🔹 Tournament list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Builder(builder: (context) {
                      List<Map<String, dynamic>> data = List.from(_tournaments);
                      if (selectedTab == 1 && _userId != null && _userId! > 0) {
                        data = data.where((t) => t['created_by']?.toString() == _userId.toString()).toList();
                      } else if (selectedTab == 2) {
                        final now = DateTime.now();
                        data = data.where((t) {
                          final sd = t['start_date']?.toString();
                          if (sd == null || sd.isEmpty) return false;
                          try {
                            final dt = DateTime.parse(sd);
                            return dt.isBefore(now);
                          } catch (_) {
                            return false;
                          }
                        }).toList();
                      }

                      if (data.isEmpty) {
                        return const Center(child: Text('No tournaments to show'));
                      }

                      return ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final t = data[index];
                          final name = (t['tournament_name'] ?? 'Tournament').toString();
                          final date = (t['start_date'] ?? '').toString();
                          final loc = (t['location'] ?? '').toString();
                          final model = TournamentModel(
                            id: t['id'].toString(),
                            name: name,
                            status: 'upcoming',
                            type: 'Knockout',
                            dateRange: date,
                            location: loc,
                            overs: 20,
                            teams: const [],
                          );
                          return GestureDetector(
                            onTap: () => _openTournament(t),
                            child: TournamentCard(tournament: model),
                          );
                        },
                      );
                    }),
            ),

            // 🔹 Captain-only action (Create Tournament → Draws screen)
            if (widget.isCaptain) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  // Navigate to Create Tournament
                  final createdTournament = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CreateTournamentScreen()), // ✅ removed const
                  );

                  if (createdTournament != null) {
                    // ✅ Immediately open Draws screen for the creator
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => draws.TournamentDrawsScreen(
                          tournamentName: createdTournament.name,
                          tournamentId: createdTournament.id,
                          teams: createdTournament.teams,
                          isCreator: true,
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text("Create Tournament"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
