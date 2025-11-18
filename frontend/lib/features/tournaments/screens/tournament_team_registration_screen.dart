import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/team.dart';
import '../providers/tournament_provider.dart';
import '../providers/tournament_team_registration_provider.dart';
import 'tournament_draws_screen.dart';

class TournamentTeamRegistrationScreen extends StatelessWidget {
  final String tournamentName;
  final String tournamentId;

  const TournamentTeamRegistrationScreen({
    super.key,
    required this.tournamentName,
    required this.tournamentId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TournamentTeamRegistrationState(tournamentId),
      child: _TournamentTeamRegistrationView(
        tournamentName: tournamentName,
        tournamentId: tournamentId,
      ),
    );
  }
}

class _TournamentTeamRegistrationView extends StatefulWidget {
  final String tournamentName;
  final String tournamentId;

  const _TournamentTeamRegistrationView({
    required this.tournamentName,
    required this.tournamentId,
  });

  @override
  State<_TournamentTeamRegistrationView> createState() =>
      _TournamentTeamRegistrationViewState();
}

class _TournamentTeamRegistrationViewState
    extends State<_TournamentTeamRegistrationView> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<TournamentTeamRegistrationState>(
      builder: (context, state, child) {
        final selectedCount = state.selectedTeamCount;

        return WillPopScope(
          onWillPop: () async {
            if (_isProcessing) {
              _showMessage('Please wait for the current operation to complete');
              return false;
            }
            return true;
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF122118),
            appBar: AppBar(
              backgroundColor: Colors.green[700],
              elevation: 0,
              title: Text(
                "Add Teams to ${widget.tournamentName}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: _isProcessing
                    ? null
                    : () {
                        if (mounted) Navigator.pop(context);
                      },
              ),
              actions: [
                if (selectedCount > 0 && !_isProcessing)
                  IconButton(
                    icon: const Icon(Icons.clear_all, color: Colors.white),
                    onPressed: () => state.clearSelection(),
                  ),
              ],
            ),
            body: Column(
              children: [
                _SearchBar(isEnabled: !_isProcessing),
                _AddUnregisteredTeamCard(isEnabled: !_isProcessing),
                Expanded(child: _buildTeamList(context, state)),
              ],
            ),
            bottomNavigationBar: _buildBottomBar(context, selectedCount, state),
          ),
        );
      },
    );
  }

  Widget _buildTeamList(
    BuildContext context,
    TournamentTeamRegistrationState state,
  ) {
    if (state.isLoading && state.teamCount == 0) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF20DF6C)),
      );
    }

    if (state.error != null) {
      return _ErrorWidget(
        error: state.error!,
        onRetry: () => _safeRetry(state),
        onClearError: () => _safeClearError(state),
      );
    }

    if (state.filteredTeams.isEmpty) {
      return _EmptyStateWidget(
        isSearchEmpty: state.searchQuery.isNotEmpty,
        onRefresh: () => _safeRefresh(state),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _safeRefresh(state),
      color: const Color(0xFF20DF6C),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: state.filteredTeams.length,
        itemBuilder: (context, index) {
          try {
            if (index >= state.filteredTeams.length) {
              return const SizedBox.shrink();
            }

            final team = state.filteredTeams[index];
            return _TeamListItem(
              team: team,
              isSelected: state.isTeamSelected(team),
              onToggle: _isProcessing
                  ? () {}
                  : () => _safeToggleTeam(state, team),
            );
          } catch (e) {
            debugPrint('Error building team item at index $index: $e');
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    int selectedCount,
    TournamentTeamRegistrationState state,
  ) {
    final isEnabled = selectedCount >= 2 && !state.isLoading && !_isProcessing;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        color: const Color(0xFF122118),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isEnabled
                ? const Color(0xFF20DF6C)
                : const Color(0xFF366348),
            foregroundColor: const Color(0xFF122118),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            minimumSize: const Size.fromHeight(56),
          ),
          onPressed: isEnabled ? () => _addSelectedTeams(context, state) : null,
          child: _isProcessing || state.isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF122118),
                  ),
                )
              : Text("Add Selected Teams ($selectedCount)"),
        ),
      ),
    );
  }

  // Safe state operations
  Future<void> _safeRetry(TournamentTeamRegistrationState state) async {
    try {
      await state.fetchTeams();
    } catch (e) {
      debugPrint('Error retrying: $e');
      _showMessage('Failed to refresh teams');
    }
  }

  void _safeClearError(TournamentTeamRegistrationState state) {
    try {
      state.clearError();
    } catch (e) {
      debugPrint('Error clearing error state: $e');
    }
  }

  Future<void> _safeRefresh(TournamentTeamRegistrationState state) async {
    try {
      await state.fetchTeams();
    } catch (e) {
      debugPrint('Error refreshing: $e');
      _showMessage('Failed to refresh teams');
    }
  }

  void _safeToggleTeam(TournamentTeamRegistrationState state, Team team) {
    try {
      state.toggleTeamSelection(team);
    } catch (e) {
      debugPrint('Error toggling team: $e');
      _showMessage('Failed to select team');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }

  Future<void> _addSelectedTeams(
    BuildContext context,
    TournamentTeamRegistrationState state,
  ) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final success = await state.addSelectedTeams();

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ All teams added successfully'),
            backgroundColor: Color(0xFF20DF6C),
          ),
        );

        await _navigateToDraws();
      } else if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error adding teams: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${_getErrorMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _navigateToDraws() async {
    if (!mounted) return;

    try {
      final tournamentProvider = Provider.of<TournamentProvider>(
        context,
        listen: false,
      );

      final registeredTeams = await tournamentProvider.fetchTournamentTeams(
        widget.tournamentId,
      );

      if (!mounted) return;

      final teamNames = registeredTeams
          .map((t) => t.teamName ?? 'Unknown Team')
          .where((name) => name.isNotEmpty)
          .toList();

      if (teamNames.isEmpty) {
        throw Exception('No teams found for tournament');
      }

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TournamentDrawsScreen(
            tournamentName: widget.tournamentName,
            tournamentId: widget.tournamentId,
            teams: teamNames,
            isCreator: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to draws: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Teams added, but failed to load tournament: ${_getErrorMessage(e)}',
          ),
          backgroundColor: Colors.orange,
          action: SnackBarAction(label: 'Retry', onPressed: _navigateToDraws),
        ),
      );

      // Navigate back after delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error == null) return 'Unknown error';
    return error.toString().replaceAll('Exception:', '').trim();
  }
}

class _SearchBar extends StatelessWidget {
  final bool isEnabled;

  const _SearchBar({this.isEnabled = true});

  @override
  Widget build(BuildContext context) {
    return Consumer<TournamentTeamRegistrationState>(
      builder: (context, state, child) {
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: state.searchController,
            enabled: isEnabled,
            style: TextStyle(
              color: isEnabled ? Colors.white : Colors.white.withOpacity(0.5),
            ),
            decoration: InputDecoration(
              hintText: "Search teams...",
              hintStyle: const TextStyle(color: Color(0xFF95C6A9)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF95C6A9)),
              suffixIcon: state.searchQuery.isNotEmpty && isEnabled
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xFF95C6A9)),
                      onPressed: () {
                        try {
                          state.clearSearch();
                        } catch (e) {
                          debugPrint('Error clearing search: $e');
                        }
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF1A2C22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xFF366348)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(
                  color: Color(0xFF20DF6C),
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xFF366348)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AddUnregisteredTeamCard extends StatelessWidget {
  final bool isEnabled;

  const _AddUnregisteredTeamCard({this.isEnabled = true});

  @override
  Widget build(BuildContext context) {
    return Consumer<TournamentTeamRegistrationState>(
      builder: (context, state, child) {
        final canAdd = isEnabled && !state.isAddingTeam;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: InkWell(
            onTap: canAdd ? () => _showAddTeamDialog(context, state) : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF366348)),
                color: !canAdd
                    ? const Color(0xFF1A2C22).withOpacity(0.5)
                    : const Color(0xFF1A2C22),
              ),
              child: Row(
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: !canAdd
                          ? const Color(0xFF366348).withOpacity(0.5)
                          : const Color(0xFF1A2C22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: state.isAddingTeam
                        ? const Center(
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF20DF6C),
                              ),
                            ),
                          )
                        : Icon(
                            Icons.add,
                            size: 30,
                            color: canAdd
                                ? const Color(0xFF20DF6C)
                                : const Color(0xFF20DF6C).withOpacity(0.5),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Add unregistered team",
                          style: TextStyle(
                            color: canAdd
                                ? const Color(0xFF20DF6C)
                                : const Color(0xFF20DF6C).withOpacity(0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "Quickly add a team's basic details",
                          style: TextStyle(
                            fontSize: 13,
                            color: canAdd
                                ? const Color(0xFF95C6A9)
                                : const Color(0xFF95C6A9).withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddTeamDialog(
    BuildContext context,
    TournamentTeamRegistrationState state,
  ) async {
    try {
      final result = await showDialog<Map<String, String>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _AddTeamDialog(),
      );

      if (result == null || !context.mounted) return;

      final teamName = result['name']?.trim() ?? '';
      if (teamName.isEmpty) return;

      final location = result['location']?.trim() ?? '';

      final success = await state.addUnregisteredTeam(teamName, location);

      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Team added successfully'),
            backgroundColor: Color(0xFF20DF6C),
          ),
        );
      } else if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error showing add team dialog: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _AddTeamDialog extends StatefulWidget {
  const _AddTeamDialog();

  @override
  State<_AddTeamDialog> createState() => _AddTeamDialogState();
}

class _AddTeamDialogState extends State<_AddTeamDialog> {
  final _teamNameController = TextEditingController();
  final _teamLocationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _teamNameController.dispose();
    _teamLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isSubmitting,
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Add New Team',
          style: TextStyle(color: Colors.black87),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _teamNameController,
                enabled: !_isSubmitting,
                style: const TextStyle(color: Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Team Name *',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Team name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Team name must be at least 2 characters';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _teamLocationController,
                enabled: !_isSubmitting,
                style: const TextStyle(color: Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Location (Optional)',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    if (mounted) Navigator.pop(context);
                  },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF20DF6C),
              foregroundColor: const Color(0xFF122118),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF122118),
                    ),
                  )
                : const Text('Add Team'),
          ),
        ],
      ),
    );
  }

  void _handleSubmit() {
    if (_isSubmitting) return;

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);

      final name = _teamNameController.text.trim();
      final location = _teamLocationController.text.trim();

      if (mounted) {
        Navigator.pop(context, {'name': name, 'location': location});
      }
    }
  }
}

class _TeamListItem extends StatelessWidget {
  final Team team;
  final bool isSelected;
  final VoidCallback onToggle;

  const _TeamListItem({
    required this.team,
    required this.isSelected,
    required this.onToggle,
  });

  String _safeString(String? value, String defaultValue) {
    if (value == null || value.isEmpty) return defaultValue;
    return value;
  }

  int _safeInt(int? value, int defaultValue) {
    return value ?? defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    final teamName = _safeString(team.teamName, 'Unknown Team');
    final location = _safeString(team.location, '');
    final trophies = _safeInt(team.trophies, 0);

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A3826) : const Color(0xFF1A2C22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF20DF6C)
                : const Color(0xFF366348),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1A2C22),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield, color: Color(0xFF20DF6C)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teamName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (location.isNotEmpty)
                    Text(
                      location,
                      style: const TextStyle(
                        color: Color(0xFF95C6A9),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 12,
                        color: const Color(0xFF95C6A9).withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$trophies trophies',
                        style: const TextStyle(
                          color: Color(0xFF95C6A9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Checkbox(
              value: isSelected,
              onChanged: (_) => onToggle(),
              activeColor: const Color(0xFF20DF6C),
              side: const BorderSide(color: Color(0xFF366348)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final VoidCallback onClearError;

  const _ErrorWidget({
    required this.error,
    required this.onRetry,
    required this.onClearError,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Color(0xFF95C6A9), fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF20DF6C),
                    foregroundColor: const Color(0xFF122118),
                  ),
                ),
                TextButton.icon(
                  onPressed: onClearError,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Dismiss'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF95C6A9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateWidget extends StatelessWidget {
  final bool isSearchEmpty;
  final VoidCallback onRefresh;

  const _EmptyStateWidget({
    required this.isSearchEmpty,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearchEmpty ? Icons.search_off : Icons.groups_outlined,
            size: 64,
            color: const Color(0xFF95C6A9).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isSearchEmpty ? 'No teams match your search' : 'No teams available',
            style: const TextStyle(color: Color(0xFF95C6A9), fontSize: 16),
          ),
          if (!isSearchEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Try adding a new team or check back later',
              style: TextStyle(
                color: const Color(0xFF95C6A9).withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF20DF6C),
                foregroundColor: const Color(0xFF122118),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
