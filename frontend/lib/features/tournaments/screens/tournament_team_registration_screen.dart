import 'package:flutter/material.dart';
import 'tournament_draws_screen.dart';

class RegisterTeamsScreen extends StatefulWidget {
  final String tournamentName;

  const RegisterTeamsScreen({super.key, required this.tournamentName});

  @override
  State<RegisterTeamsScreen> createState() => _RegisterTeamsScreenState();
}

class _RegisterTeamsScreenState extends State<RegisterTeamsScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> teams = [
    {
      "name": "Titans XI",
      "players": 12,
      "logo": "https://via.placeholder.com/80",
      "selected": false,
    },
    {
      "name": "Strikers United",
      "players": 11,
      "logo": "https://via.placeholder.com/80",
      "selected": false,
    },
    {
      "name": "Warriors CC",
      "players": 13,
      "logo": "https://via.placeholder.com/80",
      "selected": true,
    },
    {"name": "Raptors", "players": 10, "logo": "https://via.placeholder.com/80", "selected": false},
    {
      "name": "Gladiators",
      "players": 14,
      "logo": "https://via.placeholder.com/80",
      "selected": true,
    },
    {
      "name": "Avengers",
      "players": 11,
      "logo": "https://via.placeholder.com/80",
      "selected": false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final selectedCount = teams.where((t) => t["selected"]).length;
    final List<String> selectedTeams = teams
        .where((t) => t["selected"])
        .map<String>((t) => t["name"] as String)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF122118),
      appBar: AppBar(
        backgroundColor: const Color(0xFF122118),
        elevation: 0,
        title: const Text(
          "Add Teams",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search for a team...",
                hintStyle: const TextStyle(color: Color(0xFF95C6A9)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF95C6A9)),
                filled: true,
                fillColor: const Color(0xFF1A2C22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF366348)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF20DF6C), width: 2),
                ),
              ),
              onChanged: (query) => setState(() {}),
            ),
          ),

          // ➕ Add unregistered team button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: InkWell(
              onTap: () {
                // TODO: Implement add new team flow
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF366348), style: BorderStyle.solid),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2C22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, size: 30, color: Color(0xFF20DF6C)),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Add unregistered team",
                          style: TextStyle(color: Color(0xFF20DF6C), fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "Quickly add a team's basic details",
                          style: TextStyle(fontSize: 13, color: Color(0xFF95C6A9)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 📋 Team List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                if (_searchController.text.isNotEmpty &&
                    !team["name"].toLowerCase().contains(_searchController.text.toLowerCase())) {
                  return const SizedBox.shrink();
                }

                return GestureDetector(
                  onTap: () {
                    setState(() => team["selected"] = !team["selected"]);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: team["selected"] ? const Color(0xFF1A3826) : const Color(0xFF1A2C22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: team["selected"] ? const Color(0xFF20DF6C) : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            team["logo"],
                            height: 56,
                            width: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                team["name"],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "${team["players"]} players",
                                style: const TextStyle(color: Color(0xFF95C6A9), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Checkbox(
                          value: team["selected"],
                          onChanged: (val) {
                            setState(() => team["selected"] = val!);
                          },
                          activeColor: const Color(0xFF20DF6C),
                          side: const BorderSide(color: Color(0xFF366348)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // ✅ Footer button
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF122118),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF20DF6C),
              foregroundColor: const Color(0xFF122118),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: selectedCount > 0
                ? () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TournamentDrawsScreen(
                          tournamentName: widget.tournamentName,
                          teams: selectedTeams,
                          isCreator: true,
                        ),
                      ),
                    );
                  }
                : null,
            child: Text("Add Selected Teams ($selectedCount)"),
          ),
        ),
      ),
    );
  }
}
