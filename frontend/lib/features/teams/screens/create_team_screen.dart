import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/team_provider.dart';
import '../../../core/offline/offline_manager.dart';
import '../../../models/pending_operation.dart';
import '../../../core/theme/theme_config.dart';
import '../../../widgets/custom_button.dart';
import '../../../core/theme/app_input_styles.dart';

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Local loading state for offline operations (Provider handles online loading)
  bool _isQueuingOffline = false;

  @override
  void dispose() {
    _teamNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Validate team name
  String? _validateTeamName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Team name is required';
    final trimmed = value.trim();
    if (trimmed.length < 3) return 'Team name must be at least 3 characters';
    if (trimmed.length > 50) return 'Team name must not exceed 50 characters';
    if (!RegExp(r'^[a-zA-Z0-9\s\-]+$').hasMatch(trimmed)) {
      return 'Alphanumeric characters, spaces, and hyphens only';
    }
    return null;
  }

  /// Validate location
  String? _validateLocation(String? value) {
    if (value == null || value.trim().isEmpty) return 'Location is required';
    if (value.trim().length < 2) {
      return 'Location must be at least 2 characters';
    }
    return null;
  }

  /// Create team
  Future<void> _createTeam() async {
    final provider = Provider.of<TeamProvider>(context, listen: false);
    if (provider.isLoading || _isQueuingOffline) return;

    if (!_formKey.currentState!.validate()) return;

    // Prepare Data
    final body = {
      'team_name': _teamNameController.text.trim(),
      'team_location': _locationController.text.trim(),
    };

    // 1. Check Offline Manager
    OfflineManager? offlineManager;
    try {
      offlineManager = Provider.of<OfflineManager>(context, listen: false);
    } catch (_) {
      // OfflineManager might not be available in all contexts (e.g. testing)
    }

    // 2. Handle Offline Flow
    if (offlineManager != null && !offlineManager.isOnline) {
      setState(() => _isQueuingOffline = true);
      try {
        await offlineManager.queueOperation(
          operationType: OperationType.create,
          entityType: 'team',
          entityId: 0, // 0 or temp ID for creation
          data: body,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Team creation queued (Offline)')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to queue offline: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isQueuingOffline = false);
      }
      return;
    }

    // 3. Handle Online Flow via Provider
    final success = await provider.createTeam(body);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Team created successfully')),
      );
      Navigator.pop(context, true);
    } else {
      final error = provider.error ?? 'Failed to create team';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  void _handleCancel() {
    final provider = Provider.of<TeamProvider>(context, listen: false);
    if (provider.isLoading || _isQueuingOffline) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Watch provider for loading state and errors
    final provider = Provider.of<TeamProvider>(context);
    final isLoading = provider.isLoading || _isQueuingOffline;

    return PopScope(
      canPop: !isLoading,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for operation to complete'),
          ),
        );
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            'Create Team',
            style: AppTypographyExtended.headlineSmall.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: isLoading ? null : _handleCancel,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Info text
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Create your cricket team to start participating in tournaments.',
                          style: AppTypographyExtended.bodyMedium.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Team Name
                TextFormField(
                  controller: _teamNameController,
                  enabled: !isLoading,
                  validator: _validateTeamName,
                  textCapitalization: TextCapitalization.words,
                  // [Refactored] Use shared styles
                  decoration: AppInputStyles.textFieldDecoration(
                    context: context,
                    hintText: 'Team Name',
                    prefixIcon: Icons.sports_cricket,
                  ),
                  maxLength: 50,
                ),
                const SizedBox(height: 16),

                // Location
                TextFormField(
                  controller: _locationController,
                  enabled: !isLoading,
                  validator: _validateLocation,
                  textCapitalization: TextCapitalization.words,
                  // [Refactored] Use shared styles
                  decoration: AppInputStyles.textFieldDecoration(
                    context: context,
                    hintText: 'Location (City/Region)',
                    prefixIcon: Icons.location_on,
                  ),
                  maxLength: 100,
                ),
                const SizedBox(height: 16),

                const SizedBox(height: 24),

                // Submit Button
                PrimaryButton(
                  text: "Create Team",
                  onPressed: isLoading ? null : _createTeam,
                  isLoading: isLoading,
                  fullWidth: true,
                  size: ButtonSize.large,
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: isLoading ? null : _handleCancel,
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isLoading
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
