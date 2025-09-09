// lib/features/tournaments/widgets/tournament_filter_tabs.dart
import 'package:flutter/material.dart';

class TournamentFilterTabs extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onChanged;

  const TournamentFilterTabs({super.key, required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tabs = ["All", "My Tournaments", "Past"];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(tabs.length, (index) {
        final isSelected = selectedIndex == index;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(index),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                tabs[index],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
