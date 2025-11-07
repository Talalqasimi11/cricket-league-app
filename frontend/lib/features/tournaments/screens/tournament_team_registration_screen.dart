<<<<<<< Local
<<<<<<< Local
import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/api_client.dart';
import 'tournament_draws_screen.dart';

class RegisterTeamsScreen extends StatefulWidget {
  final String tournamentName;
  final String? tournamentId;

  const RegisterTeamsScreen({
    super.key,
    required this.tournamentName,
    this.tournamentId,
  });

  @override
  State<RegisterTeamsScreen> createState() => _RegisterTeamsScreenState();
}

class _RegisterTeamsScreenState extends State<RegisterTeamsScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> teams = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.tournamentId != null) _fetchTeams();
  }

  Future<void> _fetchTeams() async {
    setState(() => _loading = true);
    try {
      // Fetch all available teams
      final resp = await ApiClient.instance.get('/api/teams');
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        List<dynamic> list;
        if (decoded is Map && decoded.containsKey('data')) {
          list = decoded['data'] as List<dynamic>;
        } else if (decoded is List) {
          list = decoded;
        } else {
          list = [];
        }
        setState(() {
          teams = list.map((e) => e as Map<String, dynamic>).toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final selectedTeams = teams
        .where((t) => t["selected"] == true)
        .map((t) => t["name"] as String)
        .toList();
    final selectedCount = selectedTeams.length;

    return Scaffold(
      backgroundColor: const Color(0xFF122118),
      appBar: AppBar(
        backgroundColor: const Color(0xFF122118),
        elevation: 0,
        title: Text(
          "Add Teams to ${widget.tournamentName}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
                  borderSide: const BorderSide(
                    color: Color(0xFF20DF6C),
                    width: 2,
                  ),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // ➕ Add unregistered team button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: InkWell(
              onTap: () async {
                if (widget.tournamentId == null) return;
                // Prompt team name and location and add to tournament
                final nameController = TextEditingController();
                final locController = TextEditingController();
                final added = await showDialog<Map<String, String>>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: const Color(0xFF1A2C22),
                    title: const Text(
                      'Add Team',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Team name',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: locController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Location',
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, {
                          'name': nameController.text.trim(),
                          'location': locController.text.trim(),
                        }),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                );
                final name = added?['name'] ?? '';
                final loc = added?['location'] ?? '';
                if (name.isEmpty) return;
                try {
                  final resp = await ApiClient.instance.post(
                    '/api/tournament-teams',
                    body: {
                      'tournament_id': widget.tournamentId,
                      'temp_team_name': name,
                      'temp_team_location': loc.isEmpty ? 'Unknown' : loc,
                    },
                  );
                  if (resp.statusCode == 200 || resp.statusCode == 201) {
                    _fetchTeams();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to add team (${resp.statusCode})',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF366348)),
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
                      child: const Icon(
                        Icons.add,
                        size: 30,
                        color: Color(0xFF20DF6C),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Add unregistered team",
                          style: TextStyle(
                            color: Color(0xFF20DF6C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "Quickly add a team's basic details",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF95C6A9),
                          ),
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: teams.length,
                    itemBuilder: (context, index) {
                      final team = teams[index];
                      final teamName =
                          (team["team_name"] ??
                                  team["temp_team_name"] ??
                                  team["name"] ??
                                  "")
                              .toString();

                      if (_searchController.text.isNotEmpty &&
                          !teamName.toLowerCase().contains(
                            _searchController.text.toLowerCase(),
                          )) {
                        return const SizedBox.shrink();
                      }

                      // mark selected field consistently
                      team["selected"] = (team["selected"] as bool?) ?? false;

                      return GestureDetector(
                        onTap: () {
                          setState(
                            () =>
                                team["selected"] = !(team["selected"] as bool),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: team["selected"]
                                ? const Color(0xFF1A3826)
                                : const Color(0xFF1A2C22),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: team["selected"]
                                  ? const Color(0xFF20DF6C)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 56,
                                width: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A2C22),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.shield,
                                  color: Color(0xFF20DF6C),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      teamName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Text(
                                      "Registered",
                                      style: TextStyle(
                                        color: Color(0xFF95C6A9),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Checkbox(
                                value: team["selected"] as bool,
                                onChanged: (val) {
                                  setState(
                                    () => team["selected"] = val ?? false,
                                  );
                                },
                                activeColor: const Color(0xFF20DF6C),
                                side: const BorderSide(
                                  color: Color(0xFF366348),
                                ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: selectedCount >= 2 && !_loading
                ? () async {
                    // Persist selected teams to backend
                    final selectedTeamObjects = teams.where((t) => t["selected"] == true).toList();
                    bool allAdded = true;

                    for (final team in selectedTeamObjects) {
                      try {
                        final resp = await ApiClient.instance.post(
                          '/api/tournament-teams',
                          body: {
                            'tournament_id': widget.tournamentId,
                            'team_id': team['id'], // Use team_id for registered teams
                          },
                        );
                        if (resp.statusCode != 200 && resp.statusCode != 201) {
                          allAdded = false;
                          break;
                        }
                      } catch (e) {
                        allAdded = false;
                        break;
                      }
                    }

                    if (!allAdded) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to add some teams. Please try again.')),
                      );
                      return;
                    }

                    // After successful persistence, fetch updated tournament teams and navigate
                    try {
                      final resp = await ApiClient.instance.get(
                        '/api/tournament-teams/${widget.tournamentId}',
                      );
                      if (resp.statusCode == 200) {
                        final decoded = jsonDecode(resp.body);
                        List<dynamic> tournamentTeams = [];
                        if (decoded is Map && decoded.containsKey('data')) {
                          tournamentTeams = decoded['data'] as List<dynamic>;
                        } else if (decoded is List) {
                          tournamentTeams = decoded;
                        }

                        // Extract team names from tournament teams
                        final registeredTeamNames = tournamentTeams.map((t) {
                          return (t["team_name"] ?? t["temp_team_name"] ?? "").toString();
                        }).where((name) => name.isNotEmpty).toList();

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TournamentDrawsScreen(
                              tournamentName: widget.tournamentName,
                              tournamentId: widget.tournamentId!,
                              teams: registeredTeamNames,
                              isCreator: true,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to fetch updated teams. Please try again.')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                : null,
            child: Text("Add Selected Teams ($selectedCount)"),
          ),
        ),
      ),
    );
  }
}
=======
import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/api_client.dart';
import 'tournament_draws_screen.dart';

class RegisterTeamsScreen extends StatefulWidget {
  final String tournamentName;
  final String? tournamentId;

  const RegisterTeamsScreen({
    super.key,
    required this.tournamentName,
    this.tournamentId,
  });

  @override
  State<RegisterTeamsScreen> createState() => _RegisterTeamsScreenState();
}

class _RegisterTeamsScreenState extends State<RegisterTeamsScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> teams = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.tournamentId != null) _fetchTeams();
  }

  Future<void> _fetchTeams() async {
    setState(() => _loading = true);
    try {
      // Fetch all available teams
      final resp = await ApiClient.instance.get('/api/teams');
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        List<dynamic> list;
        if (decoded is Map && decoded.containsKey('data')) {
          list = decoded['data'] as List<dynamic>;
        } else if (decoded is List) {
          list = decoded;
        } else {
          list = [];
        }
        setState(() {
          teams = list.map((e) => e as Map<String, dynamic>).toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final selectedTeams = teams
        .where((t) => t["selected"] == true)
        .map((t) => t["name"] as String)
        .toList();
    final selectedCount = selectedTeams.length;

    return Scaffold(
      backgroundColor: const Color(0xFF122118),
      appBar: AppBar(
        backgroundColor: const Color(0xFF122118),
        elevation: 0,
        title: Text(
          "Add Teams to ${widget.tournamentName}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
                  borderSide: const BorderSide(
                    color: Color(0xFF20DF6C),
                    width: 2,
                  ),
                ),
              ),
              // Trigger filtering when search text changes
              onChanged: (value) {
                setState(() {
                  // The rebuild will cause the ListView.builder to filter teams
                  // based on _searchController.text
                });
              },
            ),
          ),

          // ➕ Add unregistered team button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: InkWell(
              onTap: () async {
                if (widget.tournamentId == null) return;
                // Prompt team name and location and add to tournament
                final nameController = TextEditingController();
                final locController = TextEditingController();
                final added = await showDialog<Map<String, String>>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: const Color(0xFF1A2C22),
                    title: const Text(
                      'Add Team',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Team name',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: locController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Location',
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, {
                          'name': nameController.text.trim(),
                          'location': locController.text.trim(),
                        }),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                );
                final name = added?['name'] ?? '';
                final loc = added?['location'] ?? '';
                if (name.isEmpty) return;
                try {
                  final resp = await ApiClient.instance.post(
                    '/api/tournament-teams',
                    body: {
                      'tournament_id': widget.tournamentId,
                      'temp_team_name': name,
                      'temp_team_location': loc.isEmpty ? 'Unknown' : loc,
                    },
                  );
                  if (resp.statusCode == 200 || resp.statusCode == 201) {
                    _fetchTeams();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to add team (${resp.statusCode})',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF366348)),
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
                      child: const Icon(
                        Icons.add,
                        size: 30,
                        color: Color(0xFF20DF6C),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Add unregistered team",
                          style: TextStyle(
                            color: Color(0xFF20DF6C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "Quickly add a team's basic details",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF95C6A9),
                          ),
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: teams.length,
                    itemBuilder: (context, index) {
                      final team = teams[index];
                      final teamName =
                          (team["team_name"] ??
                                  team["temp_team_name"] ??
                                  team["name"] ??
                                  "")
                              .toString();

                      if (_searchController.text.isNotEmpty &&
                          !teamName.toLowerCase().contains(
                            _searchController.text.toLowerCase(),
                          )) {
                        return const SizedBox.shrink();
                      }

                      // mark selected field consistently
                      team["selected"] = (team["selected"] as bool?) ?? false;

                      return GestureDetector(
                        onTap: () {
                          setState(
                            () =>
                                team["selected"] = !(team["selected"] as bool),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: team["selected"]
                                ? const Color(0xFF1A3826)
                                : const Color(0xFF1A2C22),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: team["selected"]
                                  ? const Color(0xFF20DF6C)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 56,
                                width: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A2C22),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.shield,
                                  color: Color(0xFF20DF6C),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      teamName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Text(
                                      "Registered",
                                      style: TextStyle(
                                        color: Color(0xFF95C6A9),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Checkbox(
                                value: team["selected"] as bool,
                                onChanged: (val) {
                                  setState(
                                    () => team["selected"] = val ?? false,
                                  );
                                },
                                activeColor: const Color(0xFF20DF6C),
                                side: const BorderSide(
                                  color: Color(0xFF366348),
                                ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: selectedCount >= 2 && !_loading
                ? () async {
                    // Persist selected teams to backend
                    final selectedTeamObjects = teams.where((t) => t["selected"] == true).toList();
                    bool allAdded = true;

                    for (final team in selectedTeamObjects) {
                      try {
                        final resp = await ApiClient.instance.post(
                          '/api/tournament-teams',
                          body: {
                            'tournament_id': widget.tournamentId,
                            'team_id': team['id'], // Use team_id for registered teams
                          },
                        );
                        if (resp.statusCode != 200 && resp.statusCode != 201) {
                          allAdded = false;
                          break;
                        }
                      } catch (e) {
                        allAdded = false;
                        break;
                      }
                    }

                    if (!allAdded) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to add some teams. Please try again.')),
                      );
                      return;
                    }

                    // After successful persistence, fetch updated tournament teams and navigate
                    try {
                      final resp = await ApiClient.instance.get(
                        '/api/tournament-teams/${widget.tournamentId}',
                      );
                      if (resp.statusCode == 200) {
                        final decoded = jsonDecode(resp.body);
                        List<dynamic> tournamentTeams = [];
                        if (decoded is Map && decoded.containsKey('data')) {
                          tournamentTeams = decoded['data'] as List<dynamic>;
                        } else if (decoded is List) {
                          tournamentTeams = decoded;
                        }

                        // Extract team names from tournament teams
                        final registeredTeamNames = tournamentTeams.map((t) {
                          return (t["team_name"] ?? t["temp_team_name"] ?? "").toString();
                        }).where((name) => name.isNotEmpty).toList();

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TournamentDrawsScreen(
                              tournamentName: widget.tournamentName,
                              tournamentId: widget.tournamentId!,
                              teams: registeredTeamNames,
                              isCreator: true,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to fetch updated teams. Please try again.')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                : null,
            child: Text("Add Selected Teams ($selectedCount)"),
          ),
        ),
      ),
    );
  }
}
>>>>>>> Remote
=======
import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/api_client.dart';
import 'tournament_draws_screen.dart';

class RegisterTeamsScreen extends StatefulWidget {
  final String tournamentName;
  final String? tournamentId;

  const RegisterTeamsScreen({
    super.key,
    required this.tournamentName,
    this.tournamentId,
  });

  @override
  State<RegisterTeamsScreen> createState() => _RegisterTeamsScreenState();
}

class _RegisterTeamsScreenState extends State<RegisterTeamsScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> teams = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.tournamentId != null) _fetchTeams();
  }

  Future<void> _fetchTeams() async {
    setState(() => _loading = true);
    try {
      // Fetch all available teams
      final resp = await ApiClient.instance.get('/api/teams');
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        List<dynamic> list;
        if (decoded is Map && decoded.containsKey('data')) {
          list = decoded['data'] as List<dynamic>;
        } else if (decoded is List) {
          list = decoded;
        } else {
          list = [];
        }
        setState(() {
          teams = list.map((e) => e as Map<String, dynamic>).toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final selectedTeams = teams
        .where((t) => t["selected"] == true)
        .map((t) => t["name"] as String)
        .toList();
    final selectedCount = selectedTeams.length;

    return Scaffold(
      backgroundColor: const Color(0xFF122118),
      appBar: AppBar(
        backgroundColor: const Color(0xFF122118),
        elevation: 0,
        title: Text(
          "Add Teams to ${widget.tournamentName}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
                  borderSide: const BorderSide(
                    color: Color(0xFF20DF6C),
                    width: 2,
                  ),
                ),
              ),
              // Trigger filtering when search text changes
              onChanged: (value) {
                setState(() {
                  // The rebuild will cause the ListView.builder to filter teams
                  // based on _searchController.text
                });
              },
            ),
          ),

          // ➕ Add unregistered team button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: InkWell(
              onTap: () async {
                if (widget.tournamentId == null) return;
                // Prompt team name and location and add to tournament
                final nameController = TextEditingController();
                final locController = TextEditingController();
                final added = await showDialog<Map<String, String>>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: const Color(0xFF1A2C22),
                    title: const Text(
                      'Add Team',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Team name',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: locController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Location',
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, {
                          'name': nameController.text.trim(),
                          'location': locController.text.trim(),
                        }),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                );
                final name = added?['name'] ?? '';
                final loc = added?['location'] ?? '';
                if (name.isEmpty) return;
                try {
                  final resp = await ApiClient.instance.post(
                    '/api/tournament-teams',
                    body: {
                      'tournament_id': widget.tournamentId,
                      'temp_team_name': name,
                      'temp_team_location': loc.isEmpty ? 'Unknown' : loc,
                    },
                  );
                  if (resp.statusCode == 200 || resp.statusCode == 201) {
                    _fetchTeams();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to add team (${resp.statusCode})',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF366348)),
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
                      child: const Icon(
                        Icons.add,
                        size: 30,
                        color: Color(0xFF20DF6C),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Add unregistered team",
                          style: TextStyle(
                            color: Color(0xFF20DF6C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "Quickly add a team's basic details",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF95C6A9),
                          ),
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: teams.length,
                    itemBuilder: (context, index) {
                      final team = teams[index];
                      final teamName =
                          (team["team_name"] ??
                                  team["temp_team_name"] ??
                                  team["name"] ??
                                  "")
                              .toString();

                      if (_searchController.text.isNotEmpty &&
                          !teamName.toLowerCase().contains(
                            _searchController.text.toLowerCase(),
                          )) {
                        return const SizedBox.shrink();
                      }

                      // mark selected field consistently
                      team["selected"] = (team["selected"] as bool?) ?? false;

                      return GestureDetector(
                        onTap: () {
                          setState(
                            () =>
                                team["selected"] = !(team["selected"] as bool),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: team["selected"]
                                ? const Color(0xFF1A3826)
                                : const Color(0xFF1A2C22),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: team["selected"]
                                  ? const Color(0xFF20DF6C)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 56,
                                width: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A2C22),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.shield,
                                  color: Color(0xFF20DF6C),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      teamName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Text(
                                      "Registered",
                                      style: TextStyle(
                                        color: Color(0xFF95C6A9),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Checkbox(
                                value: team["selected"] as bool,
                                onChanged: (val) {
                                  setState(
                                    () => team["selected"] = val ?? false,
                                  );
                                },
                                activeColor: const Color(0xFF20DF6C),
                                side: const BorderSide(
                                  color: Color(0xFF366348),
                                ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: selectedCount >= 2 && !_loading
                ? () async {
                    // Persist selected teams to backend
                    final selectedTeamObjects = teams.where((t) => t["selected"] == true).toList();
                    bool allAdded = true;

                    for (final team in selectedTeamObjects) {
                      try {
                        final resp = await ApiClient.instance.post(
                          '/api/tournament-teams',
                          body: {
                            'tournament_id': widget.tournamentId,
                            'team_id': team['id'], // Use team_id for registered teams
                          },
                        );
                        if (resp.statusCode != 200 && resp.statusCode != 201) {
                          allAdded = false;
                          break;
                        }
                      } catch (e) {
                        allAdded = false;
                        break;
                      }
                    }

                    if (!allAdded) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to add some teams. Please try again.')),
                      );
                      return;
                    }

                    // After successful persistence, fetch updated tournament teams and navigate
                    try {
                      final resp = await ApiClient.instance.get(
                        '/api/tournament-teams/${widget.tournamentId}',
                      );
                      if (resp.statusCode == 200) {
                        final decoded = jsonDecode(resp.body);
                        List<dynamic> tournamentTeams = [];
                        if (decoded is Map && decoded.containsKey('data')) {
                          tournamentTeams = decoded['data'] as List<dynamic>;
                        } else if (decoded is List) {
                          tournamentTeams = decoded;
                        }

                        // Extract team names from tournament teams
                        final registeredTeamNames = tournamentTeams.map((t) {
                          return (t["team_name"] ?? t["temp_team_name"] ?? "").toString();
                        }).where((name) => name.isNotEmpty).toList();

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TournamentDrawsScreen(
                              tournamentName: widget.tournamentName,
                              tournamentId: widget.tournamentId!,
                              teams: registeredTeamNames,
                              isCreator: true,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to fetch updated teams. Please try again.')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                : null,
            child: Text("Add Selected Teams ($selectedCount)"),
          ),
        ),
      ),
    );
  }
}
>>>>>>> Remote
