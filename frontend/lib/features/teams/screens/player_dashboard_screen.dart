import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../services/api_client.dart';
import '../models/player.dart';
import '../../../core/theme/theme_config.dart';
import '../../../widgets/image_upload_widget.dart';

class PlayerDashboardScreen extends StatefulWidget {
  final Player player;

  const PlayerDashboardScreen({super.key, required this.player});

  @override
  State<PlayerDashboardScreen> createState() => _PlayerDashboardScreenState();
}

class _PlayerDashboardScreenState extends State<PlayerDashboardScreen> {
  static const List<String> _allowedRoles = [
    'Batsman',
    'Bowler',
    'All-rounder',
    'Wicket-keeper',
  ];
  late Player _player;
  bool _isLoading = false;
  final _storage = const FlutterSecureStorage();
  late final ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    _apiClient = ApiClient.instance;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.secondaryGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DISMISS',
          onPressed: () {},
          textColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> _handleAuthError() async {
    await _storage.delete(key: 'jwt_token');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session expired. Please login again.'),
        backgroundColor: Colors.orange,
      ),
    );
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _showEditPlayerDialog() async {
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    String currentRole = _player.playerRole;
    final nameController = TextEditingController(text: _player.playerName);
    final runsController = TextEditingController(text: _player.runs.toString());
    final avgController = TextEditingController(
      text: _player.battingAverage.toString(),
    );
    final strikeController = TextEditingController(
      text: _player.strikeRate.toString(),
    );
    final wicketsController = TextEditingController(
      text: _player.wickets.toString(),
    );

    final nameFocus = FocusNode();
    final runsFocus = FocusNode();
    final avgFocus = FocusNode();
    final strikeFocus = FocusNode();
    final wicketsFocus = FocusNode();

    void disposeResources() {
      nameController.dispose();
      runsController.dispose();
      avgController.dispose();
      strikeController.dispose();
      wicketsController.dispose();
      nameFocus.dispose();
      runsFocus.dispose();
      avgFocus.dispose();
      strikeFocus.dispose();
      wicketsFocus.dispose();
    }

    await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return PopScope(
            canPop: true,
            onPopInvokedWithResult: (bool didPop, dynamic result) {
              if (didPop) {
                disposeResources();
              }
            },
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setDialogState) {
                Future<void> handleSubmit() async {
                  if (!formKey.currentState!.validate()) return;
                  setDialogState(() => isSubmitting = true);
                  try {
                    final updated = _player.copyWith(
                      playerName: nameController.text.trim(),
                      playerRole: currentRole,
                      runs: int.tryParse(runsController.text) ?? _player.runs,
                      battingAverage:
                          double.tryParse(avgController.text) ??
                          _player.battingAverage,
                      strikeRate:
                          double.tryParse(strikeController.text) ??
                          _player.strikeRate,
                      wickets:
                          int.tryParse(wicketsController.text) ??
                          _player.wickets,
                    );

                    await _updatePlayer(updated);
                    if (context.mounted) Navigator.of(context).pop();
                  } finally {
                    if (context.mounted) setDialogState(() => isSubmitting = false);
                  }
                }

                return AlertDialog(
                  title: const Text('Edit Player'),
                  content: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: nameController,
                            focusNode: nameFocus,
                            decoration: const InputDecoration(
                              labelText: 'Player Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Player name is required';
                              }
                              if (v.trim().length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => runsFocus.requestFocus(),
                            enabled: !isSubmitting,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: currentRole,
                            decoration: const InputDecoration(
                              labelText: 'Role',
                              border: OutlineInputBorder(),
                            ),
                            items: _allowedRoles
                                .map(
                                  (role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(role),
                                  ),
                                )
                                .toList(),
                            onChanged: isSubmitting
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setDialogState(() => currentRole = value);
                                    }
                                  },
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          // Player Photo Upload
                          ImageUploadWidget(
                            title: 'Player Photo',
                            uploadType: 'player',
                            entityId: _player.id,
                            initialImageUrl: _player.playerImageUrl,
                            onSuccess: (imageUrl) {
                              // Update player photo URL when uploaded
                              debugPrint('Player photo uploaded: $imageUrl');
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: runsController,
                            focusNode: runsFocus,
                            decoration: const InputDecoration(
                              labelText: 'Runs',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              final runs = int.tryParse(value);
                              if (runs == null) return 'Must be a number';
                              if (runs < 0) return 'Cannot be negative';
                              return null;
                            },
                            onFieldSubmitted: (_) => avgFocus.requestFocus(),
                            enabled: !isSubmitting,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: avgController,
                            focusNode: avgFocus,
                            decoration: const InputDecoration(
                              labelText: 'Batting Average',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              final avg = double.tryParse(value);
                              if (avg == null) return 'Must be a number';
                              if (avg < 0) return 'Cannot be negative';
                              return null;
                            },
                            onFieldSubmitted: (_) => strikeFocus.requestFocus(),
                            enabled: !isSubmitting,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: strikeController,
                            focusNode: strikeFocus,
                            decoration: const InputDecoration(
                              labelText: 'Strike Rate',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              final sr = double.tryParse(value);
                              if (sr == null) return 'Must be a number';
                              if (sr < 0) return 'Cannot be negative';
                              return null;
                            },
                            onFieldSubmitted: (_) =>
                                wicketsFocus.requestFocus(),
                            enabled: !isSubmitting,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: wicketsController,
                            focusNode: wicketsFocus,
                            decoration: const InputDecoration(
                              labelText: 'Wickets',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              final w = int.tryParse(value);
                              if (w == null) return 'Must be a number';
                              if (w < 0) return 'Cannot be negative';
                              return null;
                            },
                            enabled: !isSubmitting,
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: isSubmitting
                          ? null
                          : () {
                              disposeResources();
                              Navigator.of(context).pop();
                            },
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: isSubmitting ? null : handleSubmit,
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
  }

  Future<void> _updatePlayer(Player updatedPlayer) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final token = await _storage.read(key: 'jwt_token');
    try {
      final response = await _apiClient.put(
        "/players/${_player.id}",
        headers: {"Authorization": "Bearer $token"},
        body: updatedPlayer.toJson(),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          setState(() => _player = Player.fromJson(data['player']));
          _showSuccessMessage('Player information updated successfully');
        } catch (e) {
          _showErrorMessage('Invalid response format from server');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        await _handleAuthError();
      } else if (response.statusCode == 404) {
        _showErrorMessage('Player not found');
      } else {
        try {
          final data = jsonDecode(response.body);
          _showErrorMessage(data['message'] ?? 'Failed to update player');
        } catch (_) {
          _showErrorMessage('Failed to update player');
        }
      }
    } catch (e) {
      if (mounted) _showErrorMessage('Network error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildStatCard(IconData icon, String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: Colors.green),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildPlayerHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.green,
          child: Text(
            _player.playerName.isNotEmpty
                ? _player.playerName[0].toUpperCase()
                : '?',
            style: const TextStyle(fontSize: 42, color: Colors.white),
          ),
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
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard(Icons.sports_cricket, 'Runs', _player.runs.toString()),
        _buildStatCard(
          Icons.leaderboard,
          'Batting Avg',
          _player.battingAverage.toStringAsFixed(2),
        ),
        _buildStatCard(
          Icons.trending_up,
          'Strike Rate',
          _player.strikeRate.toStringAsFixed(2),
        ),
        _buildStatCard(Icons.sports, 'Wickets', _player.wickets.toString()),
      ],
    );
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
          onPressed: () => Navigator.pop(context, _player),
        ),
        title: const Text(
          'Player Dashboard',
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
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      'Edit Player Info',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: _showEditPlayerDialog,
                  ),
                ],
              ),
            ),
    );
  }
}
