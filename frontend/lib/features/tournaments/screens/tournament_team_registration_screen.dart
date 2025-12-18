import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tournament_team_registration_provider.dart';

import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/api_service.dart';

class TournamentTeamRegistrationScreen extends StatefulWidget {
  final String tournamentName;
  final String tournamentId;

  const TournamentTeamRegistrationScreen({
    super.key,
    required this.tournamentName,
    required this.tournamentId,
  });

  @override
  State<TournamentTeamRegistrationScreen> createState() =>
      _TournamentTeamRegistrationScreenState();
}

class _TournamentTeamRegistrationScreenState
    extends State<TournamentTeamRegistrationScreen> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure context is valid
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize the provider with the ID and fetch teams
      final provider = context.read<TournamentTeamRegistrationProvider>();
      provider.init(widget.tournamentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Teams'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Confirm Button
          Consumer<TournamentTeamRegistrationProvider>(
            builder: (innerContext, provider, _) {
              final count = provider.selectedTeamCount;
              return TextButton(
                onPressed: count > 0 && !provider.isLoading
                    ? () async {
                        final success = await provider.addSelectedTeams();
                        if (success && innerContext.mounted) {
                          ScaffoldMessenger.of(innerContext).showSnackBar(
                            const SnackBar(
                              content: Text('Teams added successfully!'),
                            ),
                          );
                          Navigator.pop(innerContext, true);
                        }
                      }
                    : null,
                child: Text(
                  'Confirm ($count)',
                  style: TextStyle(
                    color: count > 0 ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<TournamentTeamRegistrationProvider>(
        builder: (context, provider, _) {
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.init(widget.tournamentId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Search & Add New Team
              Container(
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.surface,
                child: Column(
                  children: [
                    TextField(
                      controller: provider.searchController,
                      decoration: InputDecoration(
                        hintText: 'Search teams...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: provider.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: provider.searchController.clear,
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddTeamDialog(context, provider),
                        icon: const Icon(Icons.add),
                        label: const Text('Create New Team'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Team List
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.filteredTeams.isEmpty
                    ? Center(
                        child: Text(
                          'No teams found',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.separated(
                        itemCount: provider.filteredTeams.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final team = provider.filteredTeams[index];
                          final isSelected = provider.isTeamSelected(team);

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (_) =>
                                provider.toggleTeamSelection(team),
                            title: Text(
                              team.teamName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(team.location ?? 'No location'),
                            secondary: CircleAvatar(
                              backgroundColor: Colors.green.shade100,
                              backgroundImage:
                                  team.teamLogoUrl != null &&
                                      team.teamLogoUrl!.isNotEmpty
                                  ? CachedNetworkImageProvider(
                                      ApiService().getImageUrl(
                                        team.teamLogoUrl,
                                      ),
                                    )
                                  : null,
                              child:
                                  team.teamLogoUrl == null ||
                                      team.teamLogoUrl!.isEmpty
                                  ? Text(
                                      team.teamName.isNotEmpty
                                          ? team.teamName[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: Colors.green.shade800,
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddTeamDialog(
    BuildContext context,
    TournamentTeamRegistrationProvider provider,
  ) {
    final nameCtrl = TextEditingController();
    final locCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Temporary Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Team Name *'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locCtrl,
              decoration: const InputDecoration(labelText: 'Location'),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          // Use Consumer to listen to local adding state if needed
          ListenableBuilder(
            listenable: provider,
            builder: (context, _) {
              return ElevatedButton(
                onPressed: provider.isAddingTeam
                    ? null
                    : () async {
                        if (nameCtrl.text.trim().isEmpty) return;

                        // Close dialog first
                        Navigator.pop(ctx);

                        final success = await provider.addUnregisteredTeam(
                          nameCtrl.text.trim(),
                          locCtrl.text.trim(),
                        );

                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Team created successfully'),
                            ),
                          );
                        }
                      },
                child: provider.isAddingTeam
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create'),
              );
            },
          ),
        ],
      ),
    );
  }
}
