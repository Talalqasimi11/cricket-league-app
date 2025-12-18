// matches/screens/select_lineup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../teams/models/player.dart'; // [FIXED] Import correct Player model
import '../../teams/providers/team_provider.dart';

class SelectLineupScreen extends StatefulWidget {
  final String teamName;

  const SelectLineupScreen({super.key, required this.teamName});

  @override
  State<SelectLineupScreen> createState() => _SelectLineupScreenState();
}

class _SelectLineupScreenState extends State<SelectLineupScreen> {
  // Max players to select for playing XI
  static const int maxSelection = 11;

  List<Player> _players = [];
  bool _isLoading = true;

  // Search and filter
  final TextEditingController _searchCtrl = TextEditingController();
  String _roleFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPlayers();
    });
  }

  Future<void> _fetchPlayers() async {
    setState(() {
      _isLoading = true;
    });

    final teamProvider = context.read<TeamProvider>();

    // Find team by name (safe check)
    // In a real app, passing teamId to this screen is safer than teamName
    final team = teamProvider.teams.firstWhere(
      (t) => t.teamName == widget.teamName,
      orElse: () => throw Exception('Team not found'),
    );

    // fetch players returns List<Player> from teams/models/player.dart
    final players = await teamProvider.getPlayers(team.id);

    if (mounted) {
      setState(() {
        _players = players;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Using 'selected' property. Note: Ideally, 'selected' should not be on the model
  // but managed in a local Set<String> of selected IDs to avoid mutating global state.
  // Assuming the Player model has a mutable 'selected' field for this screen's logic.
  // If the Player model is immutable, you will need a local Set<String> _selectedIds.
  // BELOW assumes Player model has mutable `bool selected`.

  // [FIX] Since the Player model is likely immutable or shared,
  // it is safer to track selection locally using a Set of IDs.
  final Set<String> _selectedIds = {};

  int get _selectedCount => _selectedIds.length;

  List<Player> get _filteredPlayers {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _players.where((p) {
      final name = p.playerName
          .toLowerCase(); // Changed .name to .playerName based on typical model
      final role = p.playerRole; // Changed .role to .playerRole
      final matchesQuery = q.isEmpty || name.contains(q);
      final matchesRole = _roleFilter == 'All' || role == _roleFilter;
      return matchesQuery && matchesRole;
    }).toList();
  }

  void _toggleSelect(Player player) {
    final isSelected = _selectedIds.contains(player.id);

    if (!isSelected && _selectedCount >= maxSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You can select only $maxSelection players'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      if (isSelected) {
        _selectedIds.remove(player.id);
      } else {
        _selectedIds.add(player.id);
      }
    });
  }

  void _clearAll() {
    setState(() {
      _selectedIds.clear();
    });
  }

  void _selectFirstN(int n) {
    setState(() {
      _selectedIds.clear();
      for (var i = 0; i < _players.length && i < n; i++) {
        _selectedIds.add(_players[i].id);
      }
    });
  }

  Future<void> _addPlayerDialog() async {
    final nameCtrl = TextEditingController();
    // Removed imageCtrl as it wasn't used in createPlayer call in original code effectively
    String role = 'Batsman';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Add Player',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameCtrl,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    // Using standard InputDecoration for consistency
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  dropdownColor: theme.colorScheme.surface,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Batsman', child: Text('Batsman')),
                    DropdownMenuItem(value: 'Bowler', child: Text('Bowler')),
                    DropdownMenuItem(
                      value: 'All-rounder',
                      child: Text('All-rounder'),
                    ),
                    DropdownMenuItem(
                      value: 'Wicket-Keeper',
                      child: Text('Wicket-Keeper'),
                    ),
                  ],
                  onChanged: (v) => role = v ?? 'Batsman',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      if (!mounted) return;
      final teamProvider = context.read<TeamProvider>();
      try {
        final team = teamProvider.teams.firstWhere(
          (t) => t.teamName == widget.teamName,
        );

        final newPlayer = await teamProvider.createPlayer(team.id, {
          'player_name': nameCtrl.text.trim(),
          'player_role': role,
          'is_temporary': true,
        });

        if (newPlayer != null) {
          await _fetchPlayers();
        }
      } catch (e) {
        debugPrint('Error adding player: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        title: Text(
          "Select Lineup ($_selectedCount/$maxSelection)",
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Clear all',
            icon: Icon(Icons.clear_all, color: theme.colorScheme.onPrimary),
            onPressed: _selectedCount == 0 ? null : _clearAll,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header + controls
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.teamName,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "Total: ${_players.length}",
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Search + Add
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Search players...',
                                prefixIcon: const Icon(Icons.search),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _addPlayerDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                            ),
                            icon: const Icon(Icons.person_add, size: 18),
                            label: const Text("Add"),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Role filters
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Wrap(
                          spacing: 8,
                          children:
                              [
                                'All',
                                'Batsman',
                                'Bowler',
                                'All-rounder',
                                'Wicket-Keeper',
                              ].map((r) {
                                return ChoiceChip(
                                  label: Text(r),
                                  selected: _roleFilter == r,
                                  onSelected: (_) =>
                                      setState(() => _roleFilter = r),
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Players List
                Expanded(
                  child: _filteredPlayers.isEmpty
                      ? const Center(child: Text('No players found'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _filteredPlayers.length,
                          itemBuilder: (context, index) {
                            final player = _filteredPlayers[index];
                            final isSelected = _selectedIds.contains(player.id);

                            return _PlayerTile(
                              player: player,
                              isSelected: isSelected,
                              onTap: () => _toggleSelect(player),
                            );
                          },
                        ),
                ),

                // Actions
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _selectFirstN(maxSelection),
                          child: const Text('Auto-select 11'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _selectedCount == maxSelection
                              ? () {
                                  // Return list of IDs or Names based on what previous screen expects
                                  // Assuming it expects a list of IDs/Strings
                                  Navigator.pop(context, _selectedIds.toList());
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                          child: const Text("Confirm"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final Player player;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlayerTile({
    required this.player,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: isSelected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surface,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Text(
            player.playerName.isNotEmpty ? player.playerName[0] : '?',
          ),
        ),
        title: Text(
          player.playerName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(player.playerRole),
        trailing: Checkbox(value: isSelected, onChanged: (val) => onTap()),
      ),
    );
  }
}
