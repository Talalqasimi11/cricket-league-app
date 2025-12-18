// lib/features/tournaments/widgets/tournament_filter_tabs.dart
import 'package:flutter/material.dart';

class TournamentFilterTabs extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onChanged;

  const TournamentFilterTabs({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  // [CHANGED] Simplified tabs for better UX: Live, Completed, and Creator Dashboard
  static const List<String> _tabs = ["Live", "Completed", "My Tournaments"];

  // [CHANGED] Tooltip now points to index 2
  static const Map<int, String> _tooltips = {
    2: 'Shows tournaments you created. Tap to manage or edit them.',
  };

  // Safe index validation
  bool _isValidIndex(int index) {
    return index >= 0 && index < _tabs.length;
  }

  // Get safe selected index
  int _getSafeSelectedIndex() {
    if (_isValidIndex(selectedIndex)) {
      return selectedIndex;
    }
    debugPrint('Invalid selectedIndex: $selectedIndex, defaulting to 0');
    return 0;
  }

  // Handle tab tap safely
  void _handleTabTap(int index) {
    try {
      if (!_isValidIndex(index)) {
        debugPrint('Invalid tab index: $index');
        return;
      }
      onChanged(index);
    } catch (e) {
      debugPrint('Error handling tab tap: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return _buildTabs();
    } catch (e) {
      debugPrint('Error building tournament filter tabs: $e');
      return _buildErrorState();
    }
  }

  Widget _buildTabs() {
    final safeSelectedIndex = _getSafeSelectedIndex();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        _tabs.length,
        (index) => _buildTab(index, safeSelectedIndex),
        growable: false,
      ),
    );
  }

  Widget _buildTab(int index, int safeSelectedIndex) {
    try {
      if (index < 0 || index >= _tabs.length) {
        debugPrint('Invalid tab index in build: $index');
        return const Expanded(child: SizedBox.shrink());
      }

      final isSelected = safeSelectedIndex == index;
      final tabLabel = _tabs[index];
      final tooltip = _tooltips[index];

      Widget content = GestureDetector(
        onTap: () => _handleTabTap(index),
        child: Semantics(
          label: tabLabel,
          button: true,
          selected: isSelected,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected ? Colors.green : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              tabLabel,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );

      // Wrap content with Tooltip if tooltip message exists
      if (tooltip != null && tooltip.isNotEmpty) {
        content = Tooltip(message: tooltip, child: content);
      }

      return Expanded(child: content);
    } catch (e) {
      debugPrint('Error building tab at index $index: $e');
      return const Expanded(child: SizedBox.shrink());
    }
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Text(
            'Error loading filters',
            style: TextStyle(color: Colors.red.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
