// lib/features/tournaments/widgets/tournament_card.dart
import 'package:flutter/material.dart';
import '../models/tournament_model.dart';

class TournamentCard extends StatelessWidget {
  final TournamentModel tournament;
  final VoidCallback? onTap; // 🔹 optional tap handler

  const TournamentCard({super.key, required this.tournament, this.onTap});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "ongoing":
        return Colors.green[300]!;
      case "upcoming":
        return Colors.orange[300]!;
      case "completed":
        return Colors.grey[400]!;
      default:
        return Colors.blue[200]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // 🔹 Navigate to draws/details if provided
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
              // 🔹 Title + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tournament.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Chip(
                    label: Text(
                      tournament.status,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                    backgroundColor: _getStatusColor(tournament.status),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 🔹 Date + Location
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(tournament.dateRange),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(tournament.location),
                ],
              ),

              const SizedBox(height: 8),

              // 🔹 Type + Overs
              Text(
                "Type: ${tournament.type} | Overs: ${tournament.overs}",
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
