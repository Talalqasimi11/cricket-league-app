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
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _teamLocationController = TextEditingController();

  List<Map<String, dynamic>> teams = [];
  List<Map<String, dynamic>> filteredTeams = [];
  bool _loading = false;
  bool _isAddingTeam = false;

  @override
  void initState() {
    super.initState();
    if (widget.tournamentId != null) {
      _fetchTeams();
    }
    _searchController.addListener(_filterTeams);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _teamNameController.dispose();
    _teamLocationController.dispose();
    super.dispose();
  }

  void _filterTeams() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredTeams = List.from(teams);
      } else {
        filteredTeams = teams.where((team) {
          final teamName = _getTeamName(team).toLowerCase();
          return teamName.contains(query);
        }).toList();
      }
    });
  }

  String _getTeamName(Map<String, dynamic> team) {
    return (team["team_name"] ?? team["temp_team_name"] ?? team["name"] ?? "")
        .toString();
  }

  Future<void> _fetchTeams() async {
    setState(() => _loading = true);
    try {
      final resp = await ApiClient.instance.get('/api/teams');
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        List<dynamic> teamList;

        if (decoded is Map && decoded.containsKey('data')) {
          teamList = decoded['data'] as List<dynamic>;
        } else if (decoded is List) {
          teamList = decoded;
        } else {
          teamList = [];
        }

        final teamMaps = teamList
            .map((e) => e as Map<String, dynamic>)
            .toList();

        // Initialize selected state for each team
        for (final team in teamMaps) {
          team["selected"] = false;
        }

        setState(() {
          teams = teamMaps;
          filteredTeams = List.from(teamMaps);
        });
      } else {
        _showErrorSnackBar('Failed to load teams');
      }
    } catch (e) {
      debugPrint('Error fetching teams: $e');
      _showErrorSnackBar('Error loading teams');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _showAddTeamDialog() async {
    _teamNameController.clear();
    _teamLocationController.clear();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Add New Team',
          style: TextStyle(color: Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _teamNameController,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                labelText: 'Team Name',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _teamLocationController,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                labelText: 'Location (Optional)',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
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
            onPressed: () {
              final name = _teamNameController.text.trim();
              final location = _teamLocationController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, {'name': name, 'location': location});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF20DF6C),
              foregroundColor: const Color(0xFF122118),
            ),
            child: const Text('Add Team'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _addUnregisteredTeam(result['name']!, result['location']!);
    }
  }

  Future<void> _addUnregisteredTeam(String name, String location) async {
    if (widget.tournamentId == null) return;

    setState(() => _isAddingTeam = true);

    try {
      final resp = await ApiClient.instance.post(
        '/api/tournament-teams',
        body: {
          'tournament_id': widget.tournamentId,
          'temp_team_name': name,
          'temp_team_location': location.isEmpty ? 'Unknown' : location,
        },
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        await _fetchTeams();
        _showSuccessSnackBar('Team added successfully');
      } else {
        _showErrorSnackBar('Failed to add team (${resp.statusCode})');
      }
    } catch (e) {
      debugPrint('Error adding team: $e');
      _showErrorSnackBar('Error adding team');
    } finally {
      if (mounted) setState(() => _isAddingTeam = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF20DF6C),
        ),
      );
    }
  }

  Future<void> _addSelectedTeams() async {
    if (widget.tournamentId == null) return;

    final selectedTeams = teams.where((t) => t["selected"] == true).toList();
    if (selectedTeams.length < 2) return;

    setState(() => _loading = true);

    try {
      bool allAdded = true;
      final errors = <String>[];

      for (final team in selectedTeams) {
        try {
          final resp = await ApiClient.instance.post(
            '/api/tournament-teams',
            body: {'tournament_id': widget.tournamentId, 'team_id': team['id']},
          );

          if (resp.statusCode != 200 && resp.statusCode != 201) {
            allAdded = false;
            errors.add('Failed to add ${_getTeamName(team)}');
          }
        } catch (e) {
          allAdded = false;
          errors.add('Error adding ${_getTeamName(team)}: $e');
        }
      }

      if (allAdded) {
        await _navigateToDraws();
      } else {
        _showErrorSnackBar('Some teams failed to add:\n${errors.join('\n')}');
      }
    } catch (e) {
      debugPrint('Error adding teams: $e');
      _showErrorSnackBar('Error adding teams');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _navigateToDraws() async {
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

        final registeredTeamNames = tournamentTeams
            .map(
              (t) => (t["team_name"] ?? t["temp_team_name"] ?? "").toString(),
            )
            .where((name) => name.isNotEmpty)
            .toList();

        if (mounted) {
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
        }
      } else {
        _showErrorSnackBar('Failed to fetch tournament teams');
      }
    } catch (e) {
      debugPrint('Error navigating to draws: $e');
      _showErrorSnackBar('Error loading tournament draws');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = teams.where((t) => t["selected"] == true).length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.green[700],
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
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search teams...",
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Add unregistered team button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: InkWell(
              onTap: _isAddingTeam ? null : _showAddTeamDialog,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF366348)),
                  color: _isAddingTeam
                      ? Color(0xFF1A2C22).withValues(alpha: 0.5)
                      : const Color(0xFF1A2C22),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: _isAddingTeam
                            ? Color(0xFF366348).withValues(alpha: 0.5)
                            : const Color(0xFF1A2C22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isAddingTeam
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF20DF6C),
                              ),
                            )
                          : const Icon(
                              Icons.add,
                              size: 30,
                              color: Color(0xFF20DF6C),
                            ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
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
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Team list
          Expanded(
            child: _loading && teams.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredTeams.isEmpty && !_loading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Color(0xFF95C6A9).withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'No teams available'
                              : 'No teams match your search',
                          style: const TextStyle(
                            color: Color(0xFF95C6A9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredTeams.length,
                    itemBuilder: (context, index) {
                      final team = filteredTeams[index];
                      final teamName = _getTeamName(team);
                      final isSelected = team["selected"] as bool? ?? false;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            team["selected"] = !isSelected;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1A3826)
                                : const Color(0xFF1A2C22),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
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
                                    Text(
                                      team.containsKey('temp_team_name')
                                          ? "Unregistered"
                                          : "Registered",
                                      style: const TextStyle(
                                        color: Color(0xFF95C6A9),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Checkbox(
                                value: isSelected,
                                onChanged: (val) {
                                  setState(() {
                                    team["selected"] = val ?? false;
                                  });
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

      // Footer button
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF122118),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedCount >= 2 && !_loading
                  ? const Color(0xFF20DF6C)
                  : const Color(0xFF366348),
              foregroundColor: const Color(0xFF122118),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: selectedCount >= 2 && !_loading
                ? _addSelectedTeams
                : null,
            child: _loading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF122118),
                    ),
                  )
                : Text("Add Selected Teams ($selectedCount)"),
          ),
        ),
      ),
    );
  }
}
