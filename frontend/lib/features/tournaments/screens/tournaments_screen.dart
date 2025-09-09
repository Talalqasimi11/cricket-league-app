// lib/features/tournaments/screens/tournaments_screen.dart
import 'package:flutter/material.dart';
import 'tournament_create_screen.dart';
import 'tournament_draws_screen.dart';
import '../widgets/tournament_card.dart';
import '../widgets/tournament_filter_tabs.dart';
import '../models/tournament_model.dart';

class TournamentsScreen extends StatefulWidget {
  final bool isCaptain; // pass true for captain, false for viewer

  const TournamentsScreen({super.key, this.isCaptain = false});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  int selectedTab = 0;

  final List<TournamentModel> tournaments = [
    TournamentModel(
      id: "1",
      name: "Premier League 2024",
      status: "ongoing",
      type: "Knockout",
      dateRange: "Mar 15 - Apr 20, 2024",
      location: "City Stadium",
      overs: 20,
      teams: ["Titans XI", "Warriors CC"],
    ),
    TournamentModel(
      id: "2",
      name: "Summer Cup 2024",
      status: "upcoming",
      type: "Knockout",
      dateRange: "May 10 - June 5, 2024",
      location: "Green Park",
      overs: 10,
      teams: ["Strikers United", "Raptors CC"],
    ),
  ];

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
            // 🔹 Filter tabs (Upcoming / Ongoing / Completed)
            TournamentFilterTabs(
              selectedIndex: selectedTab,
              onChanged: (index) {
                setState(() => selectedTab = index);
              },
            ),
            const SizedBox(height: 16),

            // 🔹 Tournament list
            Expanded(
              child: ListView.builder(
                itemCount: tournaments.length,
                itemBuilder: (context, index) {
                  final tournament = tournaments[index];
                  return GestureDetector(
                    onTap: () {
                      // Navigate to Draws screen (Viewer mode)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TournamentDrawsScreen(
                            tournamentName: tournament.name,
                            teams: ["Titans XI", "Warriors CC", "Gladiators", "Raptors"],
                            isCreator: widget.isCaptain, // captains can manage draws
                          ),
                        ),
                      );
                    },
                    child: TournamentCard(tournament: tournament),
                  );
                },
              ),
            ),

            // 🔹 Captain-only action
            if (widget.isCaptain) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  // Navigate to Create Tournament → then to Register Teams
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateTournamentScreen()),
                  );
                  // After returning, refresh state if needed
                  setState(() {});
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
