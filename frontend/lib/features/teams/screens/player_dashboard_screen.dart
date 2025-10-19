// lib/features/teams/screens/player_dashboard_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api_client.dart';
import '../models/player.dart';

class PlayerDashboardScreen extends StatefulWidget {
  final Player player;

  const PlayerDashboardScreen({super.key, required this.player});

  @override
  State<PlayerDashboardScreen> createState() => _PlayerDashboardScreenState();
}

class _PlayerDashboardScreenState extends State<PlayerDashboardScreen> {
  final storage = const FlutterSecureStorage();
  late Player _player;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _player = widget.player;
  }

  /// Updates the player on the backend.
  /// NOTE: It's a better practice for the API to identify the player
  /// via the URL (e.g., PUT /api/players/{playerId}) rather than the body.
  Future<void> _updatePlayer(Player updatedPlayer) async {
    setState(() => _isLoading = true);
    final token = await storage.read(key: 'jwt_token');

    try {
      final response = await ApiClient.instance.put(
        // The player ID should ideally be in the URL.
        "/api/players/${_player.id}",
        headers: {"Authorization": "Bearer $token"},
        body: updatedPlayer.toJson(),
      );

      if (response.statusCode == 200) {
        // Update the local state with the successfully saved player data.
        setState(() {
          _player = Player.fromJson(jsonDecode(response.body)['player']);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Player info updated")),
          );
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Auth error - logout and redirect to login
        await storage.delete(key: 'jwt_token');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      } else {
        throw 'Failed to update player: ${response.body}';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () =>
              Navigator.pop(context, _player), // Return updated player
        ),
        title: const Text(
          "Player Dashboard",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildPlayerHeader(),
                  const SizedBox(height: 20),
                  _buildStatsGrid(),
                  const SizedBox(height: 20),
                  _buildEditButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildPlayerHeader() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 60,
          backgroundColor: Colors.green,
          child: Icon(Icons.person, size: 60, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Text(
          _player.playerName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          _player.playerRole,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(Icons.sports_cricket, "Runs", _player.runs.toString()),
        _buildStatCard(
          Icons.leaderboard,
          "Batting Avg",
          _player.battingAverage.toStringAsFixed(2),
        ),
        _buildStatCard(
          Icons.trending_up,
          "Strike Rate",
          _player.strikeRate.toStringAsFixed(2),
        ),
        _buildStatCard(Icons.sports, "Wickets", _player.wickets.toString()),
      ],
    );
  }

  Widget _buildEditButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        minimumSize: const Size(double.infinity, 50),
      ),
      icon: const Icon(Icons.edit, color: Colors.white),
      label: const Text(
        "Edit Player Info",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      onPressed: () => _showEditPlayerDialog(_player),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.green),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  void _showEditPlayerDialog(Player player) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: player.playerName);
    final runsController = TextEditingController(text: player.runs.toString());
    final avgController = TextEditingController(
      text: player.battingAverage.toString(),
    );
    final strikeController = TextEditingController(
      text: player.strikeRate.toString(),
    );
    final wicketsController = TextEditingController(
      text: player.wickets.toString(),
    );

    // Define allowed roles (matching backend and DB)
    final roles = ['Batsman', 'Bowler', 'All-rounder', 'Wicket-keeper'];
    String selectedRole = player.playerRole;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Edit Player Info",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Player Name"),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: "Role"),
                  items: roles.map((String role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      selectedRole = newValue;
                    }
                  },
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: runsController,
                  decoration: const InputDecoration(labelText: "Runs"),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: avgController,
                  decoration: const InputDecoration(labelText: "Batting Avg"),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                TextFormField(
                  controller: strikeController,
                  decoration: const InputDecoration(labelText: "Strike Rate"),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                TextFormField(
                  controller: wicketsController,
                  decoration: const InputDecoration(labelText: "Wickets"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          final updated = Player(
                            id: player.id,
                            playerName: nameController.text.trim(),
                            playerRole: selectedRole,
                            runs: int.tryParse(runsController.text) ?? 0,
                            matchesPlayed: player.matchesPlayed,
                            hundreds: player.hundreds,
                            fifties: player.fifties,
                            battingAverage:
                                double.tryParse(avgController.text) ?? 0.0,
                            strikeRate:
                                double.tryParse(strikeController.text) ?? 0.0,
                            wickets: int.tryParse(wicketsController.text) ?? 0,
                          );
                          Navigator.pop(context);
                          _updatePlayer(updated);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text("Save"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
