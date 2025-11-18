import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api_client.dart';
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
      if (body.isEmpty) {
        throw const FormatException('Empty response body');
      }
      return jsonDecode(body);
    } on FormatException catch (e) {
      debugPrint('JSON decode error: $e');
      debugPrint('Response body: $body');
      throw FormatException('Invalid JSON response: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected decode error: $e');
      rethrow;
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  String _getInitial(String name) {
    try {
      if (name.isEmpty) return '?';
      return name.trim()[0].toUpperCase();
    } catch (e) {
      debugPrint('Error getting initial: $e');
      return '?';
    }
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
    if (!mounted || _isDisposed) return;
    
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

  Future<void> _showEditPlayerDialog() async {
    if (_isLoading || _isDisposed || !mounted) return;

    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    String currentRole = _safeString(_player.playerRole, _allowedRoles[0]);
    String? uploadedImageUrl;

    final nameController = TextEditingController(
      text: _safeString(_player.playerName, ''),
    );
    final runsController = TextEditingController(
      text: _safeInt(_player.runs, 0).toString(),
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

    final nameFocus = FocusNode();
    final runsFocus = FocusNode();
    final avgFocus = FocusNode();
    final strikeFocus = FocusNode();
    final wicketsFocus = FocusNode();

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
                  final playerName = nameController.text.trim();
                  final runs = int.tryParse(runsController.text.trim()) ??
                      _player.runs;
                  final battingAverage =
                      double.tryParse(avgController.text.trim()) ??
                          _player.battingAverage;
                  final strikeRate =
                      double.tryParse(strikeController.text.trim()) ??
                          _player.strikeRate;
                  final wickets =
                      int.tryParse(wicketsController.text.trim()) ??
                          _player.wickets;

                  if (playerName.isEmpty) {
                    throw Exception('Player name cannot be empty');
                  }

                  final updated = _player.copyWith(
                    playerName: playerName,
                    playerRole: currentRole,
                    runs: runs,
                    battingAverage: battingAverage,
                    strikeRate: strikeRate,
                    wickets: wickets,
                    playerImageUrl: uploadedImageUrl ?? _player.playerImageUrl,
                  );

                  await _updatePlayer(updated);

                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  debugPrint('Error in handleSubmit: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
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
                          textCapitalization: TextCapitalization.words,
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
                            if (v.trim().length > 50) {
                              return 'Name must not exceed 50 characters';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => runsFocus.requestFocus(),
                          enabled: !isSubmitting,
                          maxLength: 50,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: currentRole,
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
                          validator: (v) => v == null ? 'Role is required' : null,
                        ),
                        const SizedBox(height: 12),
                        ImageUploadWidget(
                          label: 'Player Photo',
                          currentImageUrl: _player.playerImageUrl,
                          onImageUploaded: (imageUrl) {
                            debugPrint('Player photo uploaded: $imageUrl');
                            uploadedImageUrl = imageUrl;
                          },
                          onImageRemoved: () {
                            debugPrint('Player photo removed');
                            uploadedImageUrl = '';
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
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            final runs = int.tryParse(value.trim());
                            if (runs == null) return 'Must be a valid number';
                            if (runs < 0) return 'Cannot be negative';
                            if (runs > 1000000) return 'Value too large';
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
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            final avg = double.tryParse(value.trim());
                            if (avg == null) return 'Must be a valid number';
                            if (avg < 0) return 'Cannot be negative';
                            if (avg > 1000) return 'Value too large';
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
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            final sr = double.tryParse(value.trim());
                            if (sr == null) return 'Must be a valid number';
                            if (sr < 0) return 'Cannot be negative';
                            if (sr > 1000) return 'Value too large';
                            return null;
                          },
                          onFieldSubmitted: (_) => wicketsFocus.requestFocus(),
                          enabled: !isSubmitting,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: wicketsController,
                          focusNode: wicketsFocus,
                          decoration: const InputDecoration(
                            labelText: 'Wickets',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            final w = int.tryParse(value.trim());
                            if (w == null) return 'Must be a valid number';
                            if (w < 0) return 'Cannot be negative';
                            if (w > 10000) return 'Value too large';
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
                            if (Navigator.canPop(context)) {
                              Navigator.of(context).pop();
                            }
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
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing edit dialog: $e');
      _showErrorMessage('Failed to open edit dialog');
    } finally {
      // Dispose resources after dialog is closed
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
  }

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
      if (playerId.isEmpty) {
        throw Exception('Invalid player ID');
      }

      Map<String, dynamic> playerJson;
      try {
        playerJson = updatedPlayer.toJson();
      } catch (e) {
        debugPrint('Error serializing player: $e');
        throw Exception('Failed to prepare player data');
      }

      final response = await _apiClient.put(
        "/players/$playerId",
        headers: {"Authorization": "Bearer $token"},
        body: playerJson,
      );

      if (!mounted || _isDisposed) return;

      if (response.statusCode == 200) {
        await _handleSuccessResponse(response);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        await _handleAuthError();
      } else if (response.statusCode == 404) {
        _showErrorMessage('Player not found');
      } else {
        await _handleErrorResponse(response);
      }
    } catch (e, stackTrace) {
      debugPrint('Error updating player: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted && !_isDisposed) {
        _showErrorMessage('Network error: ${e.toString()}');
      }
    } finally {
      if (!_isDisposed) {
        _safeSetState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSuccessResponse(dynamic response) async {
    try {
      final data = _safeJsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid response format');
      }

      final playerData = data['player'];
      if (playerData == null) {
        throw const FormatException('Player data not found in response');
      }

      if (playerData is! Map<String, dynamic>) {
        throw FormatException('Invalid player data type: ${playerData.runtimeType}');
      }

      final updatedPlayer = Player.fromJson(playerData);

      if (!_isDisposed) {
        _safeSetState(() => _player = updatedPlayer);
        _showSuccessMessage('Player information updated successfully');
      }
    } catch (e) {
      debugPrint('Error handling success response: $e');
      _showErrorMessage('Failed to process server response');
    }
  }

  Future<void> _handleErrorResponse(dynamic response) async {
    try {
      final data = _safeJsonDecode(response.body);
      
      String message = 'Failed to update player';
      if (data is Map<String, dynamic>) {
        message = data['message']?.toString() ??
            data['error']?.toString() ??
            message;
      }
      
      _showErrorMessage(message);
    } catch (e) {
      debugPrint('Error parsing error response: $e');
      _showErrorMessage('Failed to update player');
    }
  }

  Widget _buildStatCard(IconData icon, String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerHeader() {
    final playerName = _safeString(_player.playerName, 'Unknown Player');
    final playerRole = _safeString(_player.playerRole, 'Unknown Role');

    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.green,
          backgroundImage: _player.playerImageUrl != null &&
                  _player.playerImageUrl!.isNotEmpty
              ? NetworkImage(_player.playerImageUrl!)
              : null,
          child: _player.playerImageUrl == null ||
                  _player.playerImageUrl!.isEmpty
              ? Text(
                  _getInitial(playerName),
                  style: const TextStyle(fontSize: 42, color: Colors.white),
                )
              : null,
          onBackgroundImageError: (exception, stackTrace) {
            debugPrint('Error loading player image: $exception');
          },
        ),
        const SizedBox(height: 10),
        Text(
          playerName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          playerRole,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final runs = _safeInt(_player.runs, 0);
    final battingAvg = _safeDouble(_player.battingAverage, 0.0);
    final strikeRate = _safeDouble(_player.strikeRate, 0.0);
    final wickets = _safeInt(_player.wickets, 0);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard(Icons.sports_cricket, 'Runs', runs.toString()),
        _buildStatCard(
          Icons.leaderboard,
          'Batting Avg',
          battingAvg.toStringAsFixed(2),
        ),
        _buildStatCard(
          Icons.trending_up,
          'Strike Rate',
          strikeRate.toStringAsFixed(2),
        ),
        _buildStatCard(Icons.sports, 'Wickets', wickets.toString()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please wait for the update to complete'),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: _isLoading
                ? null
                : () {
                    if (mounted && !_isDisposed) {
                      Navigator.pop(context, _player);
                    }
                  },
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
                      onPressed: _isLoading ? null : _showEditPlayerDialog,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}