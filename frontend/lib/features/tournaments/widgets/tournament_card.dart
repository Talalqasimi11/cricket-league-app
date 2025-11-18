// lib/features/tournaments/widgets/tournament_card.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/api_client.dart';
import '../models/tournament_model.dart';

class TournamentCard extends StatefulWidget {
  final TournamentModel tournament;
  final VoidCallback? onTap;
  final bool isCaptain;
  final VoidCallback? onTournamentStarted;

  const TournamentCard({
    super.key,
    required this.tournament,
    this.onTap,
    this.isCaptain = false,
    this.onTournamentStarted,
  });

  @override
  State<TournamentCard> createState() => _TournamentCardState();
}

class _TournamentCardState extends State<TournamentCard> {
  bool _isStarting = false;

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

  TournamentStatus _safeGetTournamentStatus(String? status) {
    try {
      return TournamentStatus.fromString(status ?? 'upcoming');
    } catch (e) {
      debugPrint('Error parsing tournament status: $e');
      return TournamentStatus.upcoming;
    }
  }

  Color _getStatusColor(String? status) {
    try {
      final tournamentStatus = _safeGetTournamentStatus(status);
      
      switch (tournamentStatus) {
        case TournamentStatus.active:
          return Colors.green[300] ?? Colors.green;
        case TournamentStatus.upcoming:
          return Colors.orange[300] ?? Colors.orange;
        case TournamentStatus.completed:
          return Colors.grey[400] ?? Colors.grey;
      }
    } catch (e) {
      debugPrint('Error getting status color: $e');
      return Colors.grey[400] ?? Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    try {
      if (status == null || status.isEmpty) return 'Upcoming';
      
      // Capitalize first letter
      return status[0].toUpperCase() + status.substring(1).toLowerCase();
    } catch (e) {
      debugPrint('Error formatting status text: $e');
      return 'Unknown';
    }
  }

  bool _canStartTournament() {
    try {
      final status = _safeString(widget.tournament.status, '');
      return status.toLowerCase() == 'upcoming' && widget.isCaptain;
    } catch (e) {
      debugPrint('Error checking start permission: $e');
      return false;
    }
  }

  Future<void> _startTournament() async {
    if (_isStarting || !mounted) return;

    // Validate tournament ID
    final tournamentId = _safeString(widget.tournament.id, '');
    if (tournamentId.isEmpty) {
      _showMessage('Invalid tournament ID', isError: true);
      return;
    }

    setState(() => _isStarting = true);

    try {
      final response = await ApiClient.instance.put(
        '/api/tournaments/$tournamentId/start',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showMessage('✅ Tournament started successfully!');
        
        // Wait a bit before calling callback
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (mounted) {
          widget.onTournamentStarted?.call();
        }
      } else {
        await _handleErrorResponse(response);
      }
    } catch (e, stackTrace) {
      debugPrint('Error starting tournament: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        _showMessage(
          'Error starting tournament: ${_getErrorMessage(e)}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  Future<void> _handleErrorResponse(dynamic response) async {
    try {
      final data = _safeJsonDecode(response.body);
      
      String errorMessage = 'Failed to start tournament';
      
      if (data is Map<String, dynamic>) {
        errorMessage = _safeString(
          data['error']?.toString(),
          'Failed to start tournament',
        );
      }

      _showMessage(errorMessage, isError: true);
    } catch (e) {
      debugPrint('Error handling error response: $e');
      _showMessage('Failed to start tournament', isError: true);
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error == null) return 'Unknown error';
    final message = error.toString();
    return message.replaceAll('Exception:', '').trim();
  }

  void _handleCardTap() {
    if (_isStarting) return;
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    try {
      return _buildCard();
    } catch (e) {
      debugPrint('Error building tournament card: $e');
      return _buildErrorCard();
    }
  }

  Widget _buildCard() {
    final tournamentName = _safeString(widget.tournament.name, 'Unnamed Tournament');
    final dateRange = _safeString(widget.tournament.dateRange, 'Date TBD');
    final location = _safeString(widget.tournament.location, 'Location TBD');
    final type = _safeString(widget.tournament.type, 'Knockout');
    final overs = widget.tournament.overs ?? 20;
    final status = _safeString(widget.tournament.status, 'upcoming');

    return InkWell(
      onTap: widget.onTap != null ? _handleCardTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tournamentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      _getStatusText(status),
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                    backgroundColor: _getStatusColor(status),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Date + Location
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      dateRange,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Type + Overs + Start Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Type: $type | Overs: $overs",
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_canStartTournament()) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isStarting ? null : _startTournament,
                      icon: _isStarting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Start'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                        minimumSize: const Size(70, 32),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Error loading tournament',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}