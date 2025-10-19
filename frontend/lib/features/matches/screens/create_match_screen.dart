// lib/features/matches/screens/create_match_screen.dart
import 'package:flutter/material.dart';
import 'select_lineup_screen.dart';
import 'live_match_scoring_screen.dart';

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  String? matchType;
  String? overs;
  String? selectedTeamA;
  String? selectedTeamB;

  final TextEditingController teamAController = TextEditingController();
  final TextEditingController teamBController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // ✅ Dummy registered teams (replace with DB fetch later)
  final List<String> registeredTeams = [
    "Custom Team",
    "Warriors",
    "Titans",
    "Strikers",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Set Up Match",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔹 Match Type
              DropdownButtonFormField<String>(
                decoration: _inputDecoration("Select Match Type", Icons.sports),
                initialValue: matchType,
                items: const [
                  DropdownMenuItem(
                    value: "Show Match",
                    child: Text("Show Match"),
                  ),
                  DropdownMenuItem(
                    value: "Tournament Match",
                    child: Text("Tournament Match"),
                  ),
                  DropdownMenuItem(
                    value: "Series Match",
                    child: Text("Series Match"),
                  ),
                ],
                onChanged: (val) => setState(() => matchType = val),
                dropdownColor: const Color(0xFF1E2E2A),
                style: const TextStyle(color: Colors.white),
                validator: (val) => val == null ? "Select a match type" : null,
              ),
              const SizedBox(height: 24),

              // 🔹 Teams Section
              Row(
                children: [
                  Expanded(
                    child: _teamCard("Team A", teamAController, isTeamA: true),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      "VS",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _teamCard("Team B", teamBController, isTeamA: false),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 🔹 Lineup Buttons
              Row(
                children: [
                  Expanded(
                    child: _lineupButton("Team A Lineup", teamAController.text),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _lineupButton("Team B Lineup", teamBController.text),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 🔹 Match Overs
              DropdownButtonFormField<String>(
                decoration: _inputDecoration("Match Overs", Icons.timelapse),
                initialValue: overs,
                items: const [
                  DropdownMenuItem(value: "10", child: Text("10 Overs")),
                  DropdownMenuItem(value: "20", child: Text("20 Overs")),
                  DropdownMenuItem(value: "50", child: Text("50 Overs")),
                ],
                onChanged: (val) => setState(() => overs = val),
                dropdownColor: const Color(0xFF1E2E2A),
                style: const TextStyle(color: Colors.white),
                validator: (val) => val == null ? "Select overs" : null,
              ),
              const SizedBox(height: 20),

              // 🔹 Start Match
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF36e27b),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LiveMatchScoringScreen(
                          teamA: teamAController.text,
                          teamB: teamBController.text,
                          matchId:
                              'temp_match_${DateTime.now().millisecondsSinceEpoch}',
                        ),
                      ),
                    );
                  }
                },
                child: const Text(
                  "Start Match",
                  style: TextStyle(
                    color: Color(0xFF122118),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Input Decoration
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF95c6a9)),
      prefixIcon: Icon(icon, color: const Color(0xFF95c6a9)),
      filled: true,
      fillColor: const Color(0xFF1E2E2A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  // 🔹 Team Card with Dropdown + TextField
  Widget _teamCard(
    String title,
    TextEditingController controller, {
    required bool isTeamA,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2E2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // ✅ Registered Teams Dropdown
          DropdownButtonFormField<String>(
            decoration: _inputDecoration("Select Team", Icons.group),
            initialValue: isTeamA ? selectedTeamA : selectedTeamB,
            items: registeredTeams
                .map((team) => DropdownMenuItem(value: team, child: Text(team)))
                .toList(),
            onChanged: (val) {
              setState(() {
                if (isTeamA) {
                  selectedTeamA = val;
                  teamAController.text = val == "Custom Team" ? "" : val!;
                } else {
                  selectedTeamB = val;
                  teamBController.text = val == "Custom Team" ? "" : val!;
                }
              });
            },
            dropdownColor: const Color(0xFF1E2E2A),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),

          // ✅ Team Name TextField (for custom input)
          TextFormField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Team Name",
              hintStyle: TextStyle(color: Color(0xFF95c6a9), fontSize: 14),
              filled: true,
              fillColor: Color(0xFF121212),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (val) =>
                val == null || val.isEmpty ? "Enter team name" : null,
          ),
        ],
      ),
    );
  }

  // 🔹 Lineup Button
  Widget _lineupButton(String text, String teamName) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2C4A44),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () async {
        final lineup = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SelectLineupScreen(teamName: teamName),
          ),
        );
        if (lineup != null) {
          print("✅ Selected Players for $teamName: $lineup");
        }
      },
      icon: const Icon(Icons.groups, color: Color(0xFF95c6a9)),
      label: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
