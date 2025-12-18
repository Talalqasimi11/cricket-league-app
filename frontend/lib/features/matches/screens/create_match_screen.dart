// lib/features/matches/screens/create_match_screen.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_config.dart';
import '../../../core/theme/app_input_styles.dart';
import '../../../core/error_dialog.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/shared/modern_card.dart';
import '../providers/match_provider.dart';
import '../../teams/providers/team_provider.dart';
import '../../tournaments/providers/tournament_provider.dart';
import 'select_lineup_screen.dart';
import 'live_match_scoring_screen.dart';

/// Match type enum
enum MatchType {
  friendly('Friendly Match', 'friendly'),
  tournament('Tournament Match', 'tournament'),
  series('Series Match', 'series');

  const MatchType(this.label, this.value);
  final String label;
  final String value;
}

/// Over options
enum OverOption {
  ten('10 Overs', 10),
  twenty('20 Overs', 20),
  fifty('50 Overs', 50);

  const OverOption(this.label, this.value);
  final String label;
  final int value;
}

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Form fields
  MatchType? _matchType;
  OverOption? _selectedOvers;
  String? _selectedTeamAId;
  String? _selectedTeamBId;
  String? _selectedTournamentId;

  // Custom team names (if using custom teams)
  final TextEditingController _teamAController = TextEditingController();
  final TextEditingController _teamBController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();

  // Lineup data
  List<String>? _teamALineup;
  List<String>? _teamBLineup;

  bool _isLoading = false;
  bool _useCustomTeamA = false;
  bool _useCustomTeamB = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  /// Load teams and tournaments
  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final teamProvider = context.read<TeamProvider>();
    final tournamentProvider = context.read<TournamentProvider>();

    try {
      await Future.wait([
        teamProvider.fetchTeams(forceRefresh: true),
        tournamentProvider.fetchTournaments(),
      ]);
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      if (mounted) {
        _showErrorSnackBar(
          'Failed to load data. Please check your connection.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Validate form
  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    if (_matchType == null) {
      _showErrorSnackBar('Please select a match type');
      return false;
    }

    if (_matchType == MatchType.tournament && _selectedTournamentId == null) {
      _showErrorSnackBar('Please select a tournament');
      return false;
    }

    if (!_useCustomTeamA &&
        (_selectedTeamAId == null || _selectedTeamAId!.isEmpty)) {
      _showErrorSnackBar('Please select Batting Team');
      return false;
    }

    if (!_useCustomTeamB &&
        (_selectedTeamBId == null || _selectedTeamBId!.isEmpty)) {
      _showErrorSnackBar('Please select Bowling Team');
      return false;
    }

    if (_useCustomTeamA && _teamAController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter Batting Team name');
      return false;
    }

    if (_useCustomTeamB && _teamBController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter Bowling Team name');
      return false;
    }

    if (!_useCustomTeamA &&
        !_useCustomTeamB &&
        _selectedTeamAId == _selectedTeamBId) {
      _showErrorSnackBar('Teams must be different');
      return false;
    }

    if (_selectedOvers == null) {
      _showErrorSnackBar('Please select match overs');
      return false;
    }

    return true;
  }

  /// Create match
  Future<void> _createMatch() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      if (!mounted) return;
      final matchProvider = context.read<MatchProvider>();

      // ✅ Use Current Date and Time automatically
      final matchDateTime = DateTime.now();

      // Get team names
      final team1Name = _useCustomTeamA
          ? _teamAController.text.trim()
          : _getTeamName(_selectedTeamAId);

      final team2Name = _useCustomTeamB
          ? _teamBController.text.trim()
          : _getTeamName(_selectedTeamBId);

      // Prepare match data
      final matchData = {
        'match_type': _matchType!.value,
        'team1_id': _useCustomTeamA ? null : _selectedTeamAId,
        'team2_id': _useCustomTeamB ? null : _selectedTeamBId,
        'team1_name': team1Name,
        'team2_name': team2Name,
        'tournament_id': _selectedTournamentId,
        'overs': _selectedOvers!.value,
        'match_date': matchDateTime.toIso8601String(), // Auto-generated
        'venue': _venueController.text.trim(),
        'status': 'scheduled',
        if (_teamALineup != null && _teamALineup!.isNotEmpty)
          'team1_lineup': _teamALineup,
        if (_teamBLineup != null && _teamBLineup!.isNotEmpty)
          'team2_lineup': _teamBLineup,
      };

      final match = await matchProvider.createMatch(matchData);

      if (!mounted) return;

      if (match != null) {
        _showSuccessDialog(match.id.toString(), team1Name, team2Name);
      } else {
        _showErrorSnackBar(matchProvider.error ?? 'Failed to create match');
      }
    } catch (e) {
      debugPrint('Error creating match: $e');
      if (mounted) {
        await ErrorDialog.showGenericError(
          context,
          error: e,
          onRetry: _createMatch,
          showRetryButton: e is SocketException || e is TimeoutException,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Show success dialog
  void _showSuccessDialog(String matchId, String team1Name, String team2Name) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Match Created!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$team1Name vs $team2Name'),
            const SizedBox(height: 8),
            Text(
              'Match has been created successfully.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return to matches screen
            },
            child: const Text('View Matches'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to matches screen
              // Navigate to live scoring
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LiveMatchScoringScreen(
                    matchId: matchId,
                    teamA: team1Name,
                    teamB: team2Name,
                  ),
                ),
              );
            },
            child: const Text('Start Match'),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Select lineup for team
  Future<void> _selectLineup(bool isTeamA) async {
    final teamName = isTeamA
        ? (_useCustomTeamA
              ? _teamAController.text
              : _getTeamName(_selectedTeamAId))
        : (_useCustomTeamB
              ? _teamBController.text
              : _getTeamName(_selectedTeamBId));

    if (teamName.trim().isEmpty) {
      _showErrorSnackBar('Please select or enter a team name first');
      return;
    }

    final lineup = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(builder: (_) => SelectLineupScreen(teamName: teamName)),
    );

    if (lineup != null && mounted) {
      setState(() {
        if (isTeamA) {
          _teamALineup = lineup;
        } else {
          _teamBLineup = lineup;
        }
      });
    }
  }

  /// Get team name by ID
  String _getTeamName(String? teamId) {
    if (teamId == null || teamId.isEmpty) return '';
    try {
      final team = context.read<TeamProvider>().getTeamById(teamId);
      return team?.teamName ?? 'Unknown Team';
    } catch (e) {
      return 'Unknown Team';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(theme),
      body: _buildBody(theme),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.colorScheme.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: _isLoading ? null : () => Navigator.pop(context),
      ),
      title: Text(
        'Create Match',
        style: AppTypographyExtended.headlineSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(ThemeData theme) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMatchTypeSection(theme),
                const SizedBox(height: 24),

                if (_matchType == MatchType.tournament) ...[
                  _buildTournamentSection(theme),
                  const SizedBox(height: 24),
                ],

                _buildTeamsSection(theme),
                const SizedBox(height: 24),

                _buildLineupSection(theme),
                const SizedBox(height: 24),

                _buildMatchDetailsSection(theme),
                const SizedBox(height: 24),

                _buildVenueSection(theme),
                const SizedBox(height: 32),

                _buildCreateButton(theme),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        if (_isLoading) _buildLoadingOverlay(theme),
      ],
    );
  }

  Widget _buildMatchTypeSection(ThemeData theme) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Match Type',
            style: AppTypographyExtended.titleMedium.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<MatchType>(
            decoration: AppInputStyles.textFieldDecoration(
              context: context,
              hintText: 'Select Match Type',
              prefixIcon: Icons.sports_cricket,
            ),
            initialValue: _matchType,
            items: MatchType.values.map((type) {
              return DropdownMenuItem(value: type, child: Text(type.label));
            }).toList(),
            onChanged: _isLoading
                ? null
                : (value) => setState(() => _matchType = value),
            validator: (value) =>
                value == null ? 'Please select match type' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentSection(ThemeData theme) {
    return Consumer<TournamentProvider>(
      builder: (context, provider, _) {
        final bool valueExists =
            _selectedTournamentId != null &&
            provider.tournaments.any((t) => t.id == _selectedTournamentId);

        final safeValue = valueExists ? _selectedTournamentId : null;

        return ModernCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tournament',
                style: AppTypographyExtended.titleMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: AppInputStyles.textFieldDecoration(
                  context: context,
                  hintText: 'Select Tournament',
                  prefixIcon: Icons.emoji_events,
                ),
                initialValue: safeValue,
                hint: Text(
                  provider.tournaments.isEmpty
                      ? 'No tournaments found'
                      : 'Select Tournament',
                ),
                items: provider.tournaments.map((tournament) {
                  return DropdownMenuItem<String>(
                    value: tournament.id,
                    child: Text(
                      tournament.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: _isLoading || provider.tournaments.isEmpty
                    ? null
                    : (value) => setState(() => _selectedTournamentId = value),
                validator: (value) =>
                    _matchType == MatchType.tournament && value == null
                    ? 'Please select tournament'
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamsSection(ThemeData theme) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Teams',
            style: AppTypographyExtended.titleMedium.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                // ✅ Changed Title to Batting Team
                child: _buildTeamSelector(theme, 'Batting Team', isTeamA: true),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'VS',
                  style: AppTypographyExtended.titleLarge.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                // ✅ Changed Title to Bowling Team
                child: _buildTeamSelector(
                  theme,
                  'Bowling Team',
                  isTeamA: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: Robust Team Selector with corrected Dropdown logic
  Widget _buildTeamSelector(
    ThemeData theme,
    String label, {
    required bool isTeamA,
  }) {
    final useCustom = isTeamA ? _useCustomTeamA : _useCustomTeamB;
    final selectedTeamId = isTeamA ? _selectedTeamAId : _selectedTeamBId;
    final controller = isTeamA ? _teamAController : _teamBController;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypographyExtended.labelLarge.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Consumer<TeamProvider>(
                builder: (context, provider, _) {
                  if (provider.teams.isEmpty && !useCustom) {
                    return SizedBox(
                      height: 24,
                      width: 24,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.refresh, size: 16),
                        onPressed: () =>
                            provider.fetchTeams(forceRefresh: true),
                        tooltip: "Reload Teams",
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Custom Team',
              style: AppTypographyExtended.bodySmall,
            ),
            value: useCustom,
            onChanged: _isLoading
                ? null
                : (value) {
                    setState(() {
                      if (isTeamA) {
                        _useCustomTeamA = value ?? false;
                        if (_useCustomTeamA) _selectedTeamAId = null;
                      } else {
                        _useCustomTeamB = value ?? false;
                        if (_useCustomTeamB) _selectedTeamBId = null;
                      }
                    });
                  },
          ),
          const SizedBox(height: 8),

          if (useCustom)
            TextFormField(
              controller: controller,
              decoration: AppInputStyles.textFieldDecoration(
                context: context,
                hintText: 'Team Name',
                prefixIcon: Icons.shield,
              ),
              validator: (value) =>
                  value?.trim().isEmpty ?? true ? 'Enter team name' : null,
              enabled: !_isLoading,
            )
          else
            Consumer<TeamProvider>(
              builder: (context, provider, _) {
                // Filter invalid teams & Remove Duplicates
                final uniqueTeams = <String>{};
                final validTeams = provider.teams.where((t) {
                  final id = t.id.toString();
                  if (id.isEmpty) return false;
                  if (uniqueTeams.contains(id)) return false;
                  uniqueTeams.add(id);
                  return true;
                }).toList();

                // Ensure strict string comparison
                final bool valueExists =
                    selectedTeamId != null &&
                    validTeams.any((t) => t.id.toString() == selectedTeamId);

                final safeValue = valueExists ? selectedTeamId : null;

                return DropdownButtonFormField<String>(
                  key: ValueKey(
                    'dropdown_${isTeamA ? "A" : "B"}',
                  ), // Forces rebuild when switching modes
                  decoration: AppInputStyles.textFieldDecoration(
                    context: context,
                    hintText: 'Select Team',
                    prefixIcon: Icons.shield,
                  ),
                  initialValue: safeValue,
                  isExpanded: true,
                  hint: Text(
                    validTeams.isEmpty ? 'No teams found' : 'Select Team',
                  ),
                  items: validTeams.map((team) {
                    return DropdownMenuItem<String>(
                      value: team.id.toString(),
                      child: Text(
                        team.teamName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: _isLoading || validTeams.isEmpty
                      ? null
                      : (value) {
                          setState(() {
                            if (isTeamA) {
                              _selectedTeamAId = value;
                              _teamALineup = null; // Reset lineup on change
                            } else {
                              _selectedTeamBId = value;
                              _teamBLineup = null;
                            }
                          });
                        },
                  validator: (value) =>
                      !useCustom && (value == null || value.isEmpty)
                      ? 'Select team'
                      : null,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLineupSection(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : () => _selectLineup(true),
            icon: Icon(
              _teamALineup != null && _teamALineup!.isNotEmpty
                  ? Icons.check_circle
                  : Icons.people_outline,
            ),
            label: Text(
              _teamALineup != null && _teamALineup!.isNotEmpty
                  ? 'Batting Team (${_teamALineup!.length})'
                  : 'Batting Lineup',
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : () => _selectLineup(false),
            icon: Icon(
              _teamBLineup != null && _teamBLineup!.isNotEmpty
                  ? Icons.check_circle
                  : Icons.people_outline,
            ),
            label: Text(
              _teamBLineup != null && _teamBLineup!.isNotEmpty
                  ? 'Bowling Team (${_teamBLineup!.length})'
                  : 'Bowling Lineup',
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchDetailsSection(ThemeData theme) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Match Details',
            style: AppTypographyExtended.titleMedium.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<OverOption>(
            decoration: AppInputStyles.textFieldDecoration(
              context: context,
              hintText: 'Match Overs',
              prefixIcon: Icons.timelapse,
            ),
            initialValue: _selectedOvers,
            items: OverOption.values.map((option) {
              return DropdownMenuItem(value: option, child: Text(option.label));
            }).toList(),
            onChanged: _isLoading
                ? null
                : (value) => setState(() => _selectedOvers = value),
            validator: (value) => value == null ? 'Please select overs' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildVenueSection(ThemeData theme) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Venue',
            style: AppTypographyExtended.titleMedium.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _venueController,
            decoration: AppInputStyles.textFieldDecoration(
              context: context,
              hintText: 'Match Venue',
              prefixIcon: Icons.location_on,
            ),
            validator: (value) =>
                value?.trim().isEmpty ?? true ? 'Enter venue' : null,
            enabled: !_isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton(ThemeData theme) {
    return PrimaryButton(
      text: 'Create Match',
      onPressed: _isLoading ? null : _createMatch,
      isLoading: _isLoading,
      fullWidth: true,
      size: ButtonSize.large,
      icon: Icons.add_circle,
    );
  }

  Widget _buildLoadingOverlay(ThemeData theme) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Creating match...'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
