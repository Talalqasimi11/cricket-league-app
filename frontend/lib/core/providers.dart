import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/matches/providers/live_match_provider.dart';
import '../features/tournaments/providers/tournament_provider.dart';
import '../features/tournaments/providers/tournament_stats_provider.dart';
import 'auth_provider.dart';
import 'database/hive_service.dart';
import 'offline/offline_manager.dart';
import 'caching/cache_manager.dart';
import '../services/api_service.dart';

/// A widget that provides all the app's providers to its descendants
class AppProviders extends StatefulWidget {
  final Widget child;

  const AppProviders({super.key, required this.child});

  @override
  State<AppProviders> createState() => _AppProvidersState();
}

class _AppProvidersState extends State<AppProviders> {
  late OfflineManager _offlineManager;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      final apiService = ApiService();
      _offlineManager = OfflineManager(
        hiveService: HiveService(),
        apiService: apiService,
      );
      await _offlineManager.init();

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      debugPrint('[AppProviders] Initialization error: $e');
      if (mounted) {
        setState(() {
          _initialized = true; // Continue even on error
        });
      }
    }
  }

  @override
  void dispose() {
    _offlineManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TournamentProvider()),
        ChangeNotifierProvider(create: (_) => LiveMatchProvider()),
        Provider<OfflineManager>.value(value: _offlineManager),
        Provider<CacheManager>.value(value: CacheManager.instance),
        Provider<CacheManager>.value(value: CacheManager.instance),
        Provider<HiveService>.value(value: HiveService()),
        ChangeNotifierProvider(create: (_) => TournamentStatsProvider()),
      ],
      child: widget.child,
    );
  }
}

/// Extension methods for easy provider access
extension ProviderExtension on BuildContext {
  // Auth provider
  AuthProvider get authProvider => read<AuthProvider>();
  AuthProvider get watchAuthProvider => watch<AuthProvider>();

  // Tournament provider
  TournamentProvider get tournamentProvider => read<TournamentProvider>();
  TournamentProvider get watchTournamentProvider => watch<TournamentProvider>();

  // Live match provider
  LiveMatchProvider get liveMatchProvider => read<LiveMatchProvider>();
  LiveMatchProvider get watchLiveMatchProvider => watch<LiveMatchProvider>();

  // Offline manager
  OfflineManager get offlineManager => read<OfflineManager>();

  // Cache manager
  CacheManager get cacheManager => read<CacheManager>();

  // Hive service
  HiveService get hiveService => read<HiveService>();
}
