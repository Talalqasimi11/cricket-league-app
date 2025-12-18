import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/team_provider.dart';
import '../models/player.dart';
import 'player_dashboard_screen.dart';
import '../../../widgets/image_upload_widget.dart';
import '../../../services/api_service.dart';
import '../../../core/api_client.dart'; // For base URL

class TeamDashboardScreen extends StatefulWidget {
  const TeamDashboardScreen({super.key});

  @override
  State<TeamDashboardScreen> createState() => _TeamDashboardScreenState();
}

class _TeamDashboardScreenState extends State<TeamDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data immediately when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeamProvider>().fetchMyTeam();
    });
  }

  // Helper to construct full image URL
  String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    // Ensure this matches your backend URL logic
    return '${ApiClient.baseUrl}$path';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text("Team Dashboard"),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () => context.read<TeamProvider>().fetchMyTeam(),
          ),
        ],
      ),
      body: Consumer<TeamProvider>(
        builder: (context, provider, child) {
          // Show full screen loader ONLY if we have no data yet
          if (provider.isLoading && !provider.hasMyTeam) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error ONLY if we have no data to show
          if (provider.error != null && !provider.hasMyTeam) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => provider.fetchMyTeam(),
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!provider.hasMyTeam) {
            return const Center(child: Text("No team data found."));
          }

          final teamData = provider.myTeamData!;
          final players = provider.myTeamPlayers;

          return RefreshIndicator(
            onRefresh: () => provider.fetchMyTeam(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTeamHeader(context, teamData),
                  const SizedBox(height: 24),
                  _buildPlayersList(context, players, provider),
                  _buildActionButtons(context, provider, teamData, players),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeamHeader(BuildContext context, Map<String, dynamic> teamData) {
    final theme = Theme.of(context);
    final name = teamData['team_name'] ?? 'Team';
    final logo = teamData['team_logo_url'] ?? teamData['team_logo'];
    final location = teamData['team_location'] ?? '';
    final trophies = teamData['trophies'] ?? 0;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surfaceContainerHighest,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: SizedBox(
              width: 120,
              height: 120,
              child: logo != null && logo.toString().isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: _getFullImageUrl(logo),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const CircularProgressIndicator(),
                      errorWidget: (_, __, ___) => Icon(
                        Icons.shield,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 60,
                      ),
                    )
                  : Icon(
                      Icons.shield,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 60,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              "$trophies Trophies",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (location.toString().isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on,
                color: theme.colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                location,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPlayersList(
    BuildContext context,
    List<Player> players,
    TeamProvider provider,
  ) {
    final theme = Theme.of(context);

    if (players.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "No players yet.",
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final captainId = provider.myTeamData?['captain_player_id']?.toString();
    final viceCaptainId = provider.myTeamData?['vice_captain_player_id']
        ?.toString();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: players.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final player = players[index];
        final isCaptain = player.id == captainId;
        final isViceCaptain = player.id == viceCaptainId;

        return Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: player.hasProfileImage
                  ? NetworkImage(_getFullImageUrl(player.playerImageUrl))
                  : null,
              child: !player.hasProfileImage
                  ? Text(
                      player.initials,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            title: Text(
              player.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              "${player.displayRole} • Avg: ${player.battingAverage.toStringAsFixed(1)}",
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCaptain)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.amber.shade700),
                    ),
                    child: Text(
                      'C',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                if (isViceCaptain)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.shade700),
                    ),
                    child: Text(
                      'VC',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () async {
              // Navigate to player details
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayerDashboardScreen(player: player),
                ),
              );
              // Refresh data when returning (in case player was edited/deleted)
              if (context.mounted) provider.fetchMyTeam();
            },
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    TeamProvider provider,
    Map<String, dynamic> teamData,
    List<Player> players,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.person_add),
                  label: const Text("Add Player"),
                  onPressed: provider.isLoading
                      ? null
                      : () => _showAddPlayerDialog(context, provider),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit Team"),
                  onPressed: provider.isLoading
                      ? null
                      : () => _showEditTeamDialog(
                          context,
                          provider,
                          teamData,
                          players,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.delete_outline),
            label: const Text("Delete Team"),
            onPressed: provider.isLoading
                ? null
                : () => _deleteTeam(context, provider),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTeam(BuildContext context, TeamProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Team'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await provider.deleteMyTeam();
      if (success && context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Team deleted')));
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to delete team')),
        );
      }
    }
  }

  void _showAddPlayerDialog(BuildContext context, TeamProvider provider) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final roles = ['Batsman', 'Bowler', 'All-rounder', 'Wicket-keeper'];
    String? selectedRole = roles[0];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Add Player"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Role",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.sports_cricket),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedRole,
                      isExpanded: true,
                      isDense: true,
                      items: roles
                          .map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => selectedRole = v),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx);
                  final success = await provider.addPlayerToMyTeam(
                    nameController.text.trim(),
                    selectedRole!,
                  );

                  if (context.mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Player added successfully'),
                        ),
                      );
                      provider.fetchMyTeam();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            provider.error ?? 'Failed to add player',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTeamDialog(
    BuildContext context,
    TeamProvider provider,
    Map<String, dynamic> teamData,
    List<Player> players,
  ) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: teamData['team_name']);
    final locationController = TextEditingController(
      text: teamData['team_location'],
    );

    // Ensure we handle potentially null logo
    String tempLogoUrl =
        teamData['team_logo_url'] ?? teamData['team_logo'] ?? '';

    String? tempCaptainId = teamData['captain_player_id']?.toString();
    String? tempViceCaptainId = teamData['vice_captain_player_id']?.toString();

    // Clean up IDs if the players no longer exist
    if (players.isNotEmpty) {
      if (!players.any((p) => p.id == tempCaptainId)) {
        tempCaptainId = null;
      }
      if (!players.any((p) => p.id == tempViceCaptainId)) {
        tempViceCaptainId = null;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Edit Team"),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Name",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: "Location",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  ImageUploadWidget(
                    label: 'Logo',
                    currentImageUrl: _getFullImageUrl(tempLogoUrl),
                    onUpload: (file) async {
                      if (teamData['id'] == null) return null;
                      // Assuming ApiService.uploadTeamLogo returns {imageUrl: "..."}
                      final res = await ApiService().uploadTeamLogo(
                        teamData['id'].toString(),
                        file,
                      );
                      return res?['imageUrl'];
                    },
                    onImageUploaded: (url) =>
                        setState(() => tempLogoUrl = url ?? ''),
                    onImageRemoved: () => setState(() => tempLogoUrl = ''),
                  ),

                  const SizedBox(height: 16),
                  if (players.isNotEmpty) ...[
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Captain",
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: tempCaptainId,
                          isExpanded: true,
                          isDense: true,
                          hint: const Text("Select Captain"),
                          items: players
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(p.displayName),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => tempCaptainId = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Vice Captain",
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: tempViceCaptainId,
                          isExpanded: true,
                          isDense: true,
                          hint: const Text("Select Vice Captain"),
                          items: players
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(p.displayName),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => tempViceCaptainId = v),
                        ),
                      ),
                    ),
                  ] else
                    const Text(
                      "Add players to assign Captain roles.",
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  if (tempCaptainId != null &&
                      tempCaptainId == tempViceCaptainId) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Captain & VC must be different'),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(ctx);

                  // Calls Provider to update the team
                  final success = await provider.updateMyTeam({
                    'team_name': nameController.text.trim(),
                    'team_location': locationController.text.trim(),
                    'team_logo_url': tempLogoUrl, // Matches backend key
                    'captain_player_id': tempCaptainId,
                    'vice_captain_player_id': tempViceCaptainId,
                  });

                  if (context.mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Team updated')),
                      );
                      provider.fetchMyTeam();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(provider.error ?? 'Update failed'),
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
