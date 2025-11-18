import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../../core/api_client.dart';
import '../../../core/offline/offline_manager.dart';
import '../../../models/pending_operation.dart';
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
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedOvers = "10";
  bool _isSubmitting = false;

  // Safe helpers
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
    } on FormatException catch (e) {
      debugPrint('JSON decode error: $e');
      debugPrint('Response body: $body');
      throw FormatException('Invalid JSON response: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected decode error: $e');
      rethrow;
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

  String _formatDate(DateTime date) {
    try {
      return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return 'Invalid date';
    }
  }

  @override
  void dispose() {
    _tournamentNameController.dispose();
    _locationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    if (_isSubmitting || !mounted) return;

    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: isStart
            ? (_startDate ?? DateTime.now())
            : (_endDate ?? _startDate ?? DateTime.now()),
        firstDate: DateTime(2024),
        lastDate: DateTime(2100),
      );

      if (picked == null || !mounted) return;

      setState(() {
        if (isStart) {
          _startDate = picked;
          _startDateController.text = _formatDate(picked);

          // If end date is before new start date, clear it
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
            _endDateController.text = '';
          }
        } else {
          _endDate = picked;
          _endDateController.text = _formatDate(picked);
        }
      });
    } catch (e) {
      debugPrint('Error picking date: $e');
      _showMessage('Failed to select date', isError: true);
    }
  }

  bool _validateDates() {
    if (_startDate == null) {
      _showMessage('Please select a start date', isError: true);
      return false;
    }

    if (_endDate != null) {
      if (_endDate!.isBefore(_startDate!)) {
        _showMessage('End date cannot be before start date', isError: true);
        return false;
      }

      // Check if dates are the same
      if (_endDate!.isAtSameMomentAs(_startDate!)) {
        _showMessage('End date should be after start date', isError: true);
        return false;
      }
    }

    return true;
  }

  Future<void> _onSave() async {
    if (_isSubmitting || !mounted) return;

    // Validate form
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    // Validate dates
    if (!_validateDates()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final tournamentName = _tournamentNameController.text.trim();
      final location = _locationController.text.trim();
      final overs = int.tryParse(_selectedOvers) ?? 10;

      if (tournamentName.isEmpty) {
        _showMessage('Tournament name is required', isError: true);
        return;
      }

      if (location.isEmpty) {
        _showMessage('Location is required', isError: true);
        return;
      }

      final tournamentData = {
        'tournament_name': tournamentName,
        'start_date': _startDate!.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
        'location': location,
        'overs': overs,
      };

      // Get offline manager safely
      OfflineManager? offlineManager;
      try {
        offlineManager = Provider.of<OfflineManager>(context, listen: false);
      } catch (e) {
        debugPrint('Error getting offline manager: $e');
      }

      // Check if offline
      if (offlineManager != null && !offlineManager.isOnline) {
        await _handleOfflineCreation(offlineManager, tournamentData);
        return;
      }

      // Online flow
      await _handleOnlineCreation(tournamentData, tournamentName);
    } catch (e, stackTrace) {
      debugPrint('Error saving tournament: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        final errorMessage = e is SocketException
            ? 'No internet connection. Please check your network and try again.'
            : 'Failed to create tournament: ${_getErrorMessage(e)}';
        _showMessage(errorMessage, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleOfflineCreation(
    OfflineManager offlineManager,
    Map<String, dynamic> tournamentData,
  ) async {
    try {
      await offlineManager.queueOperation(
        operationType: OperationType.create,
        entityType: 'tournament',
        entityId: 0,
        data: tournamentData,
      );

      if (!mounted) return;

      _showMessage('✅ Tournament creation queued for sync when online');

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error queuing offline operation: $e');
      if (mounted) {
        _showMessage('Failed to queue tournament creation', isError: true);
      }
    }
  }

  Future<void> _handleOnlineCreation(
    Map<String, dynamic> tournamentData,
    String tournamentName,
  ) async {
    try {
      final resp = await ApiClient.instance.post(
        '/api/tournaments',
        body: tournamentData,
      );

      if (!mounted) return;

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        await _handleSuccessResponse(resp, tournamentName);
      } else {
        await _handleErrorResponse(resp);
      }
    } catch (e) {
      debugPrint('Error in online creation: $e');
      rethrow;
    }
  }

  Future<void> _handleSuccessResponse(
    dynamic resp,
    String tournamentName,
  ) async {
    try {
      final data = _safeJsonDecode(resp.body);

      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid response format');
      }

      debugPrint('Tournament creation response: $data');

      final tournamentId = _safeString(data['tournament_id']?.toString(), '');

      if (tournamentId.isEmpty) {
        _showMessage(
          'Failed to get tournament ID. Please try again.',
          isError: true,
        );
        return;
      }

      if (!mounted) return;

      _showMessage('✅ Tournament created. Add teams next.');

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TournamentTeamRegistrationScreen(
            tournamentName: tournamentName,
            tournamentId: tournamentId,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error handling success response: $e');
      if (mounted) {
        _showMessage('Failed to process response', isError: true);
      }
    }
  }

  Future<void> _handleErrorResponse(dynamic resp) async {
    try {
      String errorMessage;

      if (resp.statusCode == 400) {
        try {
          final data = _safeJsonDecode(resp.body);
          errorMessage = data is Map<String, dynamic>
              ? (data['error']?.toString() ?? 'Invalid tournament data')
              : 'Invalid tournament data';
        } catch (e) {
          errorMessage = 'Invalid tournament data';
        }
      } else if (resp.statusCode == 401 || resp.statusCode == 403) {
        errorMessage = 'Authentication failed. Please log in again.';
      } else if (resp.statusCode >= 500) {
        errorMessage = 'Server error. Please try again later.';
      } else {
        errorMessage = 'Failed to create tournament (${resp.statusCode})';
      }

      _showMessage(errorMessage, isError: true);
    } catch (e) {
      debugPrint('Error handling error response: $e');
      _showMessage('An error occurred', isError: true);
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error == null) return 'Unknown error';
    final message = error.toString();
    return message.replaceAll('Exception:', '').trim();
  }

  void _onCancel() {
    if (_isSubmitting) {
      _showMessage('Please wait for the current operation to complete');
      return;
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSubmitting) {
          _showMessage('Please wait for the current operation to complete');
          return false;
        }
        return true;
      },
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

              // Start & End Dates
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _isSubmitting
                          ? null
                          : () => _pickDate(context, true),
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _startDateController,
                          decoration: InputDecoration(
                            labelText: "Start Date",
                            border: const OutlineInputBorder(),
                            hintText: "Select start date",
                            suffixIcon: Icon(
                              Icons.calendar_today,
                              color: _isSubmitting
                                  ? Colors.grey
                                  : Theme.of(context).primaryColor,
                            ),
                          ),
                          validator: (value) {
                            if (_startDate == null) {
                              return "Select start date";
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _isSubmitting
                          ? null
                          : () => _pickDate(context, false),
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _endDateController,
                          decoration: InputDecoration(
                            labelText: "End Date (Optional)",
                            border: const OutlineInputBorder(),
                            hintText: "Select end date",
                            suffixIcon: Icon(
                              Icons.calendar_today,
                              color: _isSubmitting
                                  ? Colors.grey
                                  : Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Overs
              DropdownButtonFormField<String>(
                value: _selectedOvers,
                items: ["5", "10", "20", "50"]
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e, child: Text("$e Overs")),
                    )
                    .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _selectedOvers = value);
                        }
                      },
                decoration: const InputDecoration(
                  labelText: "Number of Overs per Match",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Tournament Type (fixed knockout)
              const TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: "Tournament Type",
                  hintText: "Knockout only",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

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
