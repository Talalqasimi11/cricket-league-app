import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api_client.dart';
import '../../../services/api_service.dart';
import '../models/player.dart';
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
  bool _isDisposed = false;
  final _storage = const FlutterSecureStorage();
  late final ApiClient _apiClient;

  // Safe helpers
  String _safeString(String? value, String defaultValue) {
    if (value == null || value.isEmpty) return defaultValue;
    return value;
  }

  double _safeDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  int _safeInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    if (value is num) return value.toInt();
    return defaultValue;
  }

  dynamic _safeJsonDecode(String body) {
    try {
      if (body.isEmpty) throw const FormatException('Empty response body');
      return jsonDecode(body);
    } catch (e) {
      debugPrint('JSON decode error: $e');
      return {}; // Return empty map on error to prevent crashes
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  String _getInitial(String name) {
    if (name.isEmpty) return '?';
    return name.trim()[0].toUpperCase();
  }

  // Helper to construct full image URL
  String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    // Remove leading slash if strictly needed, though usually standardizing on one is best
    return '${ApiClient.baseUrl}$path';
  }

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    _apiClient = ApiClient.instance;
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _showSuccessMessage(String message) {
    if (!mounted || _isDisposed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted || _isDisposed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleAuthError() async {
    try {
      await _storage.delete(key: 'jwt_token');
    } catch (e) {
      debugPrint('Error deleting token: $e');
    }

    if (!mounted || _isDisposed) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session expired. Please login again.'),
        backgroundColor: Colors.orange,
      ),
    );

    if (mounted && !_isDisposed) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // ✅ DELETE FUNCTIONALITY
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Player'),
        content: Text(
          'Are you sure you want to delete ${_player.playerName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deletePlayer();
    }
  }

  Future<void> _deletePlayer() async {
    if (!mounted || _isDisposed) return;
    _safeSetState(() => _isLoading = true);

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        await _handleAuthError();
        return;
      }

      final response = await _apiClient.delete(
        '/api/players/${_player.id}',
        headers: {"Authorization": "Bearer $token"},
      );

      if (!mounted || _isDisposed) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        _showSuccessMessage('Player deleted successfully');
        // Pass 'deleted' string or null back to indicate deletion if needed,
        // usually popping with null when expecting a Player object implies deletion handling in parent
        Navigator.pop(context, null);
      } else {
        _showErrorMessage('Failed to delete player: ${response.statusCode}');
        _safeSetState(() => _isLoading = false);
      }
    } catch (e) {
      _showErrorMessage('Error deleting player: $e');
      _safeSetState(() => _isLoading = false);
    }
  }

  Future<void> _showEditPlayerDialog() async {
    if (_isLoading || _isDisposed || !mounted) return;

    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    String currentRole = _safeString(_player.playerRole, _allowedRoles[0]);
    String? uploadedImageUrl = _player.playerImageUrl;

    final nameController = TextEditingController(
      text: _safeString(_player.playerName, ''),
    );
    final matchesController = TextEditingController(
      text: _safeInt(_player.matchesPlayed, 0).toString(),
    );
    final runsController = TextEditingController(
      text: _safeInt(_player.runs, 0).toString(),
    );
    final hundredsController = TextEditingController(
      text: _safeInt(_player.hundreds, 0).toString(),
    );
    final fiftiesController = TextEditingController(
      text: _safeInt(_player.fifties, 0).toString(),
    );
    final avgController = TextEditingController(
      text: _safeDouble(_player.battingAverage, 0.0).toStringAsFixed(2),
    );
    final strikeController = TextEditingController(
      text: _safeDouble(_player.strikeRate, 0.0).toStringAsFixed(2),
    );
    final wicketsController = TextEditingController(
      text: _safeInt(_player.wickets, 0).toString(),
    );

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              Future<void> handleSubmit() async {
                final form = formKey.currentState;
                if (form == null || !form.validate()) return;

                setDialogState(() => isSubmitting = true);

                try {
                  // Create Updated Player Object locally
                  final updatedPlayer = _player.copyWith(
                    playerName: nameController.text.trim(),
                    playerRole: currentRole,
                    matchesPlayed:
                        int.tryParse(matchesController.text.trim()) ?? 0,
                    runs: int.tryParse(runsController.text.trim()) ?? 0,
                    hundreds: int.tryParse(hundredsController.text.trim()) ?? 0,
                    fifties: int.tryParse(fiftiesController.text.trim()) ?? 0,
                    wickets: int.tryParse(wicketsController.text.trim()) ?? 0,
                    battingAverage:
                        double.tryParse(avgController.text.trim()) ?? 0.0,
                    strikeRate:
                        double.tryParse(strikeController.text.trim()) ?? 0.0,
                    playerImageUrl: uploadedImageUrl,
                  );

                  // Call the update function
                  await _updatePlayer(updatedPlayer);

                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (context.mounted) {
                    setDialogState(() => isSubmitting = false);
                  }
                }
              }

              return AlertDialog(
                title: const Text('Edit Player Stats'),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Basic Info
                        TextFormField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Player Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _allowedRoles.contains(currentRole)
                              ? currentRole
                              : _allowedRoles[0],
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.sports_cricket),
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
                              : (val) =>
                                    setDialogState(() => currentRole = val!),
                        ),
                        const SizedBox(height: 12),

                        ImageUploadWidget(
                          label: 'Player Photo',
                          currentImageUrl: _getFullImageUrl(uploadedImageUrl),
                          onUpload: (file) async {
                            if (_player.id.isEmpty) return null;
                            // Assuming ApiService handles the multipart upload
                            final res = await ApiService().uploadPlayerPhoto(
                              _player.id,
                              file,
                            );
                            // Ensure we catch the URL from the response properly
                            if (res != null && res.containsKey('imageUrl')) {
                              return res['imageUrl'];
                            }
                            return null;
                          },
                          onImageUploaded: (url) {
                            setDialogState(() => uploadedImageUrl = url);
                          },
                          onImageRemoved: () {
                            setDialogState(() => uploadedImageUrl = '');
                          },
                        ),

                        const SizedBox(height: 20),
                        const Text(
                          "Match Statistics",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),

                        // Stats Grid inputs
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: matchesController,
                                decoration: const InputDecoration(
                                  labelText: 'Matches',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: runsController,
                                decoration: const InputDecoration(
                                  labelText: 'Runs',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: hundredsController,
                                decoration: const InputDecoration(
                                  labelText: '100s',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: fiftiesController,
                                decoration: const InputDecoration(
                                  labelText: '50s',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: avgController,
                                decoration: const InputDecoration(
                                  labelText: 'Average',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: strikeController,
                                decoration: const InputDecoration(
                                  labelText: 'Strike Rate',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: wicketsController,
                                decoration: const InputDecoration(
                                  labelText: 'Wickets',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: isSubmitting ? null : handleSubmit,
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      _showErrorMessage('Failed to open edit dialog');
    }
  }

  // ✅ CRITICAL FIX: Ensure Keys Match Backend Controller
  Future<void> _updatePlayer(Player updatedPlayer) async {
    if (!mounted || _isDisposed) return;

    _safeSetState(() => _isLoading = true);

    try {
      final token = await _storage.read(key: 'jwt_token');

      if (token == null || token.isEmpty) {
        await _handleAuthError();
        return;
      }

      final playerId = _safeString(_player.id, '');
      if (playerId.isEmpty) throw Exception('Invalid player ID');

      // ⚠️ IMPORTANT: Construct Map manually to match backend exactly
      // Backend expects 'player_image_url', NOT 'image' or 'path'
      final Map<String, dynamic> requestBody = {
        'player_name': updatedPlayer.playerName,
        'player_role': updatedPlayer.playerRole,
        'player_image_url':
            updatedPlayer.playerImageUrl, // This matches backend validation
        'runs': updatedPlayer.runs,
        'matches_played': updatedPlayer.matchesPlayed,
        'wickets': updatedPlayer.wickets,
        'batting_average': updatedPlayer.battingAverage,
        'strike_rate': updatedPlayer.strikeRate,
        'hundreds': updatedPlayer.hundreds,
        'fifties': updatedPlayer.fifties,
      };

      // Remove nulls to avoid backend validation errors
      requestBody.removeWhere((key, value) => value == null);

      final response = await _apiClient.put(
        "/api/players/$playerId",
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body:
            requestBody, // Send map, not .toJson() (unless you are 100% sure toJson matches this)
      );

      if (!mounted || _isDisposed) return;

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);

        // Handle response wrapper { "message": "...", "player": {...} }
        final playerData = (data is Map && data.containsKey('player'))
            ? data['player']
            : data;

        if (playerData != null) {
          final newPlayer = Player.fromJson(playerData);
          _safeSetState(() => _player = newPlayer);
          _showSuccessMessage('Player updated successfully');
        } else {
          // Fallback if backend doesn't return full object, trust local update
          _safeSetState(() => _player = updatedPlayer);
          _showSuccessMessage('Player updated');
        }
      } else if (response.statusCode == 401) {
        await _handleAuthError();
      } else {
        // Parse error message
        final errorData = _safeJsonDecode(response.body);
        final errorMsg =
            errorData['error'] ?? 'Update failed: ${response.statusCode}';
        _showErrorMessage(errorMsg);
      }
    } catch (e) {
      _showErrorMessage('Error: $e');
    } finally {
      if (!_isDisposed) _safeSetState(() => _isLoading = false);
    }
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: theme.colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ PopScope: Return the updated _player object when going back
    return PopScope(
      canPop: !_isLoading,
      onPopInvokedWithResult: (didPop, result) {
        // This is handled by leading/onPressed manually, but serves as fallback
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Player Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            // ✅ Return the updated player data to previous screen
            onPressed: _isLoading
                ? null
                : () => Navigator.pop(context, _player),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Header
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage:
                          (_player.playerImageUrl != null &&
                              _player.playerImageUrl!.isNotEmpty)
                          ? NetworkImage(
                              _getFullImageUrl(_player.playerImageUrl),
                            )
                          : null,
                      child:
                          (_player.playerImageUrl == null ||
                              _player.playerImageUrl!.isEmpty)
                          ? Text(
                              _getInitial(_player.playerName),
                              style: TextStyle(
                                fontSize: 48,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _player.playerName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(_player.playerRole),
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      labelStyle: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Stats Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.4,
                      children: [
                        _buildStatCard(
                          context,
                          Icons.sports_cricket,
                          'Matches',
                          _player.matchesPlayed.toString(),
                        ),
                        _buildStatCard(
                          context,
                          Icons.scoreboard,
                          'Runs',
                          _player.runs.toString(),
                        ),
                        _buildStatCard(
                          context,
                          Icons.stars,
                          'Centuries',
                          _player.hundreds.toString(),
                        ),
                        _buildStatCard(
                          context,
                          Icons.star_half,
                          'Fifties',
                          _player.fifties.toString(),
                        ),
                        _buildStatCard(
                          context,
                          Icons.leaderboard,
                          'Average',
                          _player.battingAverage.toStringAsFixed(2),
                        ),
                        _buildStatCard(
                          context,
                          Icons.speed,
                          'Strike Rate',
                          _player.strikeRate.toStringAsFixed(2),
                        ),
                        _buildStatCard(
                          context,
                          Icons.sports_baseball,
                          'Wickets',
                          _player.wickets.toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Edit Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _showEditPlayerDialog,
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Profile & Stats'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Delete Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _confirmDelete,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete Player'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(color: theme.colorScheme.error),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
