// lib/features/tournaments/screens/tournament_create_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../../core/offline/offline_manager.dart';
import '../providers/tournament_provider.dart';
import 'tournament_team_registration_screen.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tournamentNameController =
      TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _selectedOvers = "10";
  bool _isSubmitting = false;

  // ---------------- Safe helpers ----------------
  String _safeString(String? value, String defaultValue) {
    if (value == null || value.isEmpty) return defaultValue;
    return value;
  }

  dynamic _safeJsonDecode(String body) {
    try {
      if (body.isEmpty) {
        throw const FormatException('Empty response body');
      }
      return jsonDecode(body);
    } catch (e) {
      debugPrint('JSON decode error: $e\nBody: $body');
      throw const FormatException('Invalid JSON response');
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  @override
  void dispose() {
    _tournamentNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_isSubmitting || !mounted) return;

    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final tournamentName = _tournamentNameController.text.trim();
      final location = _locationController.text.trim();
      final overs = int.tryParse(_selectedOvers) ?? 10;

      final tournamentData = {
        'tournament_name': tournamentName,
        'location': location,
        'overs': overs,
        'type': 'knockout', // fixed type
        'start_date': DateTime.now().toIso8601String(),
      };

      final provider = Provider.of<TournamentProvider>(context, listen: false);
      final success = await provider.createTournament(tournamentData);

      if (!mounted) return;

      if (success) {
        final offlineManager = Provider.of<OfflineManager>(
          context,
          listen: false,
        );
        if (!offlineManager.isOnline) {
          _showMessage(
            '✅ Tournament creation queued. Sync will happen when online.',
          );
          Navigator.pop(context);
        } else {
          // Try to find the new tournament to navigate
          await provider.fetchTournaments();
          final latest = provider.tournaments.isNotEmpty
              ? provider.tournaments.last
              : null;

          if (latest != null && latest.name == tournamentName) {
            _showMessage('✅ Tournament created. Add teams next.');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => TournamentTeamRegistrationScreen(
                  tournamentName: tournamentName,
                  tournamentId: latest.id,
                ),
              ),
              result: true, // Signal success to refresh parent
            );
          } else {
            _showMessage('✅ Tournament saved.');
            Navigator.pop(context, true);
          }
        }
      } else {
        String errorMessage = provider.error ?? 'Failed to create tournament';
        _showMessage(errorMessage, isError: true);
      }
    } catch (e) {
      debugPrint('Error saving tournament: $e');
      _showMessage('An error occurred. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _onCancel() {
    if (_isSubmitting) {
      _showMessage('Please wait for the current operation to complete');
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          ),
          title: const Text(
            "Create Tournament",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Tournament Name
              TextFormField(
                controller: _tournamentNameController,
                enabled: !_isSubmitting,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: "Tournament Name",
                  border: OutlineInputBorder(),
                  hintText: "Enter tournament name",
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter tournament name";
                  }
                  if (value.trim().length < 3) {
                    return "Tournament name must be at least 3 characters";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                enabled: !_isSubmitting,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: "Location / Venue",
                  border: OutlineInputBorder(),
                  hintText: "Enter venue location",
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter location";
                  }
                  if (value.trim().length < 2) {
                    return "Location must be at least 2 characters";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Overs
              TextFormField(
                initialValue: _selectedOvers,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Number of Overs per Match",
                  border: OutlineInputBorder(),
                  hintText: "Enter number of overs (e.g. 10, 20)",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter overs";
                  }
                  final n = int.tryParse(value);
                  if (n == null || n < 1 || n > 50) {
                    return "Overs must be between 1 and 50";
                  }
                  return null;
                },
                onSaved: (value) {
                  if (value != null) _selectedOvers = value;
                },
                onChanged: (value) => _selectedOvers = value,
              ),
              const SizedBox(height: 16),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: _isSubmitting ? null : _onCancel,
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: _isSubmitting ? null : _onSave,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text("Save Tournament"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
