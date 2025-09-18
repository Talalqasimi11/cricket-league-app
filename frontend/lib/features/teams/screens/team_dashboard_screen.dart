// lib/features/teams/screens/team_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'player_dashboard_screen.dart';

class TeamDashboardScreen extends StatelessWidget {
  final String teamName;
  final String teamLogoUrl;
  final int trophies;
  final List<Player> players;

  const TeamDashboardScreen({
    super.key,
    required this.teamName,
    required this.teamLogoUrl,
    required this.trophies,
    required this.players,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF122118), // dark green background
      appBar: AppBar(
        backgroundColor: const Color(0xFF122118),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context), // go back
        ),
        title: const Text(
          "Team Dashboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // TEAM LOGO + NAME + TROPHIES
            Column(
              children: [
                CircleAvatar(radius: 60, backgroundImage: NetworkImage(teamLogoUrl)),
                const SizedBox(height: 8),
                Text(
                  teamName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text("$trophies Trophies", style: const TextStyle(color: Colors.greenAccent)),
              ],
            ),
            const SizedBox(height: 20),

            // PLAYERS LIST
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final player = players[index];
                  return GestureDetector(
                    onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PlayerDashboardScreen(player: player), // ✅ send model directly
    ),
  );
},

                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2C22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(radius: 24, backgroundImage: NetworkImage(player.imageUrl)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  player.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  player.role,
                                  style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                                ),
                                Text(
                                  "Runs: ${player.runs} | Avg: ${player.battingAverage} | SR: ${player.strikeRate} | Wkts: ${player.wickets}",
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ACTION BUTTONS
            Column(
              children: [
                // ADD PLAYER BUTTON
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  label: const Text("Add Player"),
                  onPressed: () {
                    _showAddPlayerDialog(context);
                  },
                ),
                const SizedBox(height: 10),

                // EDIT + START MATCH ROW
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF15803D),
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text("Edit Team"),
                        onPressed: () {
                          _showEditTeamDialog(context, teamName, teamLogoUrl);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF20DF6C),
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.sports_cricket, color: Colors.black),
                        label: const Text("Start Match", style: TextStyle(color: Colors.black)),
                        onPressed: () {
                          _showCaptainSelectionDialog(context, players);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // DELETE TEAM WITH OTP VERIFICATION
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  icon: const Icon(Icons.delete),
                  label: const Text("Delete Team"),
                  onPressed: () {
                    _showDeleteOtpDialog(context, teamName);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog for adding a new player
  void _showAddPlayerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final roleController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2C22),
        title: const Text("Add Player", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Player Name"),
            ),
            TextField(
              controller: roleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Role"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              // TODO: add player to backend
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Player Added")));
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  /// Dialog for editing team details
  void _showEditTeamDialog(BuildContext context, String teamName, String logoUrl) {
    final nameController = TextEditingController(text: teamName);
    final logoController = TextEditingController(text: logoUrl);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2C22),
        title: const Text("Edit Team", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Team Name"),
            ),
            TextField(
              controller: logoController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Team Logo URL"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              // TODO: save changes to backend
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Team Updated")));
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  /// Captain selection dialog before starting a match
  void _showCaptainSelectionDialog(BuildContext context, List<Player> players) {
    Player? selectedCaptain;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A2C22),
            title: const Text("Select Captain", style: TextStyle(color: Colors.white)),
            content: DropdownButton<Player>(
              dropdownColor: const Color(0xFF1A2C22),
              value: selectedCaptain,
              hint: const Text("Choose a captain", style: TextStyle(color: Colors.white70)),
              isExpanded: true,
              items: players.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(p.name, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCaptain = value;
                });
              },
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  if (selectedCaptain != null) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Match started with ${selectedCaptain!.name} as captain"),
                      ),
                    );
                  }
                },
                child: const Text("Start Match"),
              ),
            ],
          );
        },
      ),
    );
  }

  /// OTP verification before deleting a team
  void _showDeleteOtpDialog(BuildContext context, String teamName) {
    final otpController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2C22),
        title: const Text("OTP Verification", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Enter OTP sent to your registered phone to delete the team.",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: otpController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "OTP Code"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              // TODO: verify OTP with backend before deleting
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Team $teamName deleted")));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}

/// Player model with full details for stats
class Player {
  final String name;
  final String role;
  final String imageUrl;
  final int runs;
  final double battingAverage;
  final double strikeRate;
  final int wickets;

  Player({
    required this.name,
    required this.role,
    required this.imageUrl,
    this.runs = 0,
    this.battingAverage = 0,
    this.strikeRate = 0,
    this.wickets = 0,
  });
}
