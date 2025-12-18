import 'package:flutter/material.dart';
import '../models/tournament_model.dart';

class TournamentCard extends StatelessWidget {
  final TournamentModel tournament;
  final VoidCallback? onTap;
  final bool isCreator;

  const TournamentCard({
    super.key,
    required this.tournament,
    this.onTap,
    this.isCreator = false,
  });

  // Helper to safely get name
  String get _safeName =>
      (tournament.name.isNotEmpty) ? tournament.name : 'Unnamed Tournament';

  // Helper to safely get date range
  String get _safeDateRange =>
      (tournament.dateRange.isNotEmpty) ? tournament.dateRange : 'Date TBD';

  Color _getStatusColor(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.active:
        return Colors.green.shade300;
      case TournamentStatus.upcoming:
        return Colors.orange.shade300;
      case TournamentStatus.completed:
        return Colors.grey.shade400;
    }
  }

  String _getStatusText(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.active:
        return 'Active';
      case TournamentStatus.upcoming:
        return 'Upcoming';
      case TournamentStatus.completed:
        return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access properties via local helpers instead of model getters
    final name = _safeName;

    // Access status via the model's getter (which should exist as it's an Enum mapping)
    // If tournamentStatus getter is missing, we fall back to parsing the string manually
    final status = tournament.tournamentStatus;

    final dateRange = _safeDateRange;

    return InkWell(
      onTap: onTap,
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
              // Name + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(dateRange, style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
