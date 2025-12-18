import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/team_provider.dart';
import 'team_dashboard_screen.dart';
import '../../../core/caching/cache_manager.dart';
import '../../../core/api_client.dart'; // ✅ Required for Base URL

class MyTeamScreen extends StatefulWidget {
  const MyTeamScreen({super.key});

  @override
  State<MyTeamScreen> createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends State<MyTeamScreen> {
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<TeamProvider>(context, listen: false).fetchMyTeam();
      });
      _isInit = false;
    }
  }

  Future<void> _refresh() async {
    await Provider.of<TeamProvider>(context, listen: false).fetchMyTeam();
  }

  // ✅ FIX: Helper to convert relative paths to full URLs
  String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${ApiClient.baseUrl}$path';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface, // Improved background color
      appBar: AppBar(
        title: const Text(
          "My Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Consumer<TeamProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Check for Unauthorized error
          if (provider.error == 'Unauthorized' ||
              (provider.error != null && provider.error!.contains('401'))) {
            return _buildLoginRequiredState(context, theme);
          }

          if (provider.error != null && !provider.hasMyTeam) {
            return _buildErrorState(
              theme,
              provider.error!,
              provider.fetchMyTeam,
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                _buildProfileSection(theme, provider.myTeamData),
                const SizedBox(height: 24),

                // Section Title
                Text(
                  "Team Management",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMyTeamSection(theme, provider),

                const SizedBox(height: 24),
                Text(
                  "Recent Activity",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMyMatchesSection(theme),

                const SizedBox(height: 40),
                _buildLogoutButton(context, theme),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginRequiredState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 60,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Login Required',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please login to view and manage your team.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
              ),
              child: const Text('Login Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Connection Issue',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(ThemeData theme, Map<String, dynamic>? data) {
    final cs = theme.colorScheme;
    final name = data?['owner_name']?.toString() ?? 'Team Owner';
    final phone =
        data?['owner_phone']?.toString() ??
        data?['captain_phone']?.toString() ??
        '';
    // ✅ FIX: Use full URL for profile image
    final imagePath =
        data?['owner_image']?.toString() ?? data?['captain_image']?.toString();
    final imageUrl = _getFullImageUrl(imagePath);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          _buildProfileAvatar(cs, imageUrl),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back,",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.primary,
                  ),
                ),
                Text(
                  name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_iphone,
                        size: 14,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _maskPhone(phone),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _maskPhone(String phone) {
    if (phone.length <= 4) return phone;
    return '****${phone.substring(phone.length - 4)}';
  }

  Widget _buildProfileAvatar(ColorScheme cs, String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: cs.surface, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 40,
        backgroundColor: cs.primaryContainer,
        backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
        child: imageUrl.isEmpty
            ? Icon(Icons.person, color: cs.onPrimaryContainer, size: 40)
            : null,
      ),
    );
  }

  Widget _buildMyTeamSection(ThemeData theme, TeamProvider provider) {
    return provider.hasMyTeam
        ? _buildTeamCard(context, theme, provider.myTeamData!)
        : _buildCreateTeamCard(context, theme);
  }

  Widget _buildTeamCard(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> teamData,
  ) {
    final cs = theme.colorScheme;
    final teamName = teamData['team_name'] ?? 'Team Name';
    final matchesWon = teamData['matches_won'] ?? 0;

    // ✅ FIX: Use full URL for team logo
    final logoPath = teamData['team_logo_url'] ?? teamData['team_logo'];
    final logoUrl = _getFullImageUrl(logoPath);

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TeamDashboardScreen()),
          );
          if (context.mounted) {
            Provider.of<TeamProvider>(context, listen: false).fetchMyTeam();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildTeamLogo(cs, logoUrl),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teamName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Matches Won: $matchesWon",
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit_outlined, size: 20, color: cs.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamLogo(ColorScheme cs, String url) {
    return Hero(
      tag: 'team_logo',
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: url.isNotEmpty
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.shield, color: cs.onSurfaceVariant),
                )
              : Icon(Icons.shield, color: cs.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildCreateTeamCard(BuildContext context, ThemeData theme) {
    final cs = theme.colorScheme;
    return Card(
      elevation: 0,
      color: cs.primaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
          child: Icon(Icons.add, color: cs.onPrimary, size: 24),
        ),
        title: Text(
          "Create Your Team",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
        ),
        subtitle: const Text("Join tournaments and manage players"),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: cs.primary),
        onTap: () async {
          final result = await Navigator.pushNamed(context, '/my-team/create');
          if (result == true && context.mounted) {
            Provider.of<TeamProvider>(context, listen: false).fetchMyTeam();
          }
        },
      ),
    );
  }

  Widget _buildMyMatchesSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.sports_cricket,
            size: 40,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            "No recent matches found",
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Matches you participate in will appear here.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.error.withValues(alpha: 0.5),
            ),
          ),
          foregroundColor: theme.colorScheme.error,
        ),
        onPressed: () async {
          await const FlutterSecureStorage().delete(key: 'jwt_token');
          await CacheManager.instance.clearAll();

          if (context.mounted) {
            Provider.of<TeamProvider>(context, listen: false).clear();
            Navigator.pushReplacementNamed(context, '/login');
          }
        },
        icon: const Icon(Icons.logout),
        label: const Text(
          "Logout",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
