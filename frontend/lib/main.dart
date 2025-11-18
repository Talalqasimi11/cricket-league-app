import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'core/theme/theme_data.dart';
import 'core/theme/theme_extensions.dart';
import 'screens/splash/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'package:provider/provider.dart';
import 'core/api_client.dart';
import 'core/auth_provider.dart';
import 'features/tournaments/providers/tournament_provider.dart';
import 'features/matches/providers/live_match_provider.dart';
import 'core/database/hive_service.dart';
import 'core/caching/cache_manager.dart';
import 'core/offline/offline_manager.dart';
import 'services/api_service.dart';
import 'features/matches/screens/matches_screen.dart';
import 'features/matches/screens/live_match_view_screen.dart';
import 'features/matches/screens/scorecard_screen.dart';
import 'features/tournaments/screens/tournaments_screen.dart';
import 'features/tournaments/screens/tournament_create_screen.dart';
import 'features/tournaments/screens/tournament_team_registration_screen.dart';
import 'features/teams/screens/my_team_screen.dart';
import 'features/teams/screens/create_team_screen.dart';
import 'features/stats/screens/statistics_screen.dart';
import 'screens/team/viewer/team_dashboard_screen.dart' as viewer;
import 'screens/player/viewer/player_dashboard_screen.dart' as player_view;
import 'screens/settings/account_screen.dart';
import 'screens/settings/developer_settings_screen.dart';
import 'screens/support/contact_screen.dart';
import 'screens/support/feedback_screen.dart';
import 'widgets/route_error_widget.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized before doing any platform / binding work.
  // This prevents timing issues when ChangeNotifiers or other initialization
  // code use WidgetsBinding or schedule post-frame callbacks.
  WidgetsFlutterBinding.ensureInitialized();

  // Add error handling for uncaught exceptions
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // Add error handling for platform errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform Error: $error');
    debugPrint('Stack trace: $stack');
    return true;
  };

  // Enable faster scheduling for better performance in development
  if (kDebugMode) {
    // Debug-only logging or dev-only flags ok — do NOT try to set internal PlatformDispatcher fields.
    // Flutter manages frame pacing automatically. Manually changing internal fields can crash on many engines.
    debugPrint(
      '[main] Running in debug mode. Skipping scheduler hacks — use the profiler for performance issues.',
    );
  }

  // Simple test app - uncomment this line to bypass initialization
  /*
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Flutter App Loaded Successfully! Missing Internet or Access Network State permissions could cause connectivity issues.'),
        ),
      ),
    ),
  );
  */

  // Enable the actual app with better error handling
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> with WidgetsBindingObserver {
  bool _isInitialized = false;
  String? _initError;
  OfflineManager? _offlineManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _offlineManager?.dispose();
    HiveService().dispose();
    ApiClient.instance.dispose();
    debugPrint('[AppBootstrap] Resources disposed successfully');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.detached) {
      debugPrint('[AppLifecycle] App detached, cleaning up resources...');
      try {
        ApiClient.instance.dispose();
      } catch (e) {
        debugPrint('[AppLifecycle] Error disposing ApiClient: $e');
      }
    }
  }

  Future<void> _initializeApp() async {
    debugPrint('[AppBootstrap] Starting app initialization');

    try {
      // Initialize core services
      debugPrint('[AppBootstrap] Initializing HiveService...');
      await HiveService().init();
      debugPrint('[AppBootstrap] HiveService initialized');

      debugPrint('[AppBootstrap] Initializing CacheManager...');
      await CacheManager.instance.init();
      debugPrint('[AppBootstrap] CacheManager initialized');

      // Initialize OfflineManager
      debugPrint('[AppBootstrap] Initializing OfflineManager...');
      final apiService = ApiService();
      _offlineManager = OfflineManager(
        hiveService: HiveService(),
        apiService: apiService,
      );
      await _offlineManager!.init();
      debugPrint('[AppBootstrap] OfflineManager initialized');

      // Listen to online status changes
      _offlineManager!.onlineStatus.listen((isOnline) {
        debugPrint('[OfflineManager] Online status: $isOnline');
      });

      // Listen to pending operations count
      _offlineManager!.pendingOperationsCount.listen((count) {
        debugPrint('[OfflineManager] Pending operations: $count');
      });

      // Set custom base URL from environment variable or use platform default
      const customUrl = String.fromEnvironment('API_BASE_URL');
      if (customUrl.isNotEmpty) {
        await ApiClient.instance.setCustomBaseUrl(customUrl);
      }

      // Fire-and-forget ApiClient init (now non-blocking)
      ApiClient.instance.init();

      debugPrint('[AppBootstrap] ApiClient.init() called (not awaited)');

      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // Brief delay for stability

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
      });
      debugPrint(
        '[AppBootstrap] All services initialized - splash screen will appear',
      );
    } catch (e, stackTrace) {
      debugPrint('[AppBootstrap] App initialization error: $e\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _initError = e.toString();
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        title: 'CricLeague',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(_initError ?? 'Initializing app...'),
                if (_initError != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _initError = null;
                        _isInitialized = false;
                      });
                      _initializeApp();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        Provider<OfflineManager>.value(value: _offlineManager!),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TournamentProvider()),
        ChangeNotifierProvider(create: (_) => LiveMatchProvider()),
      ],
      child: const AuthInitializer(),
    );
  }
}

class AuthInitializer extends StatefulWidget {
  const AuthInitializer({super.key});

  @override
  State<AuthInitializer> createState() => _AuthInitializerState();
}

class _AuthInitializerState extends State<AuthInitializer> {
  bool _authInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }

  Future<void> _initializeAuth() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initializeAuth();

      // Set offline manager for providers that need it
      final offlineManager = context.read<OfflineManager>();
      context.read<TournamentProvider>().setOfflineManager(offlineManager);

      debugPrint('[AuthInitializer] OfflineManager set on TournamentProvider');

      setState(() {
        _authInitialized = true;
      });
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      setState(() {
        _authInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_authInitialized) {
      return MaterialApp(
        title: 'CricLeague',
        debugShowCheckedModeBanner: false,
        theme: AppThemeData.light(),
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initializing authentication...'),
              ],
            ),
          ),
        ),
      );
    }

    // Validate theme in debug mode
    if (kDebugMode) {
      ThemeValidator.validateTheme(AppThemeData.light());
      ThemeValidator.logThemeInfo(AppThemeData.light());
    }

    return MaterialApp(
      title: 'CricLeague',
      debugShowCheckedModeBanner: false,
      theme: AppThemeData.light(),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/matches': (context) => const MatchesScreen(),
        '/tournaments': (context) =>
            const TournamentsScreen(isCaptain: true),
        '/my-team': (context) => const MyTeamScreen(),
        '/my-team/create': (context) => const CreateTeamScreen(),
        '/tournaments/create': (context) => const CreateTournamentScreen(),
        '/stats': (context) => const StatisticsScreen(),
        '/account': (context) => const AccountScreen(),
        '/developer-settings': (context) => const DeveloperSettingsScreen(),
        '/contact': (context) => const ContactScreen(),
        '/feedback': (context) => const FeedbackScreen(),
      },
      onGenerateRoute: (settings) {
        debugPrint('[Navigation] Navigating to: ${settings.name}');

        switch (settings.name) {
          case '/team/view':
            final args = settings.arguments as Map<String, dynamic>?;
            final teamIdString = args?['teamId']?.toString();
            final teamName = args?['teamName']?.toString();

            if (teamIdString == null) {
              debugPrint(
                '[Navigation] Error: Missing teamId for route ${settings.name}',
              );
              return MaterialPageRoute(
                builder: (_) => const RouteErrorWidget(
                  error: 'Team ID is required to view team details',
                  routeName: '/team/view',
                  title: 'Missing Team Information',
                ),
              );
            }

            final teamId = int.tryParse(teamIdString);
            if (teamId == null) {
              debugPrint(
                '[Navigation] Error: Invalid teamId "$teamIdString" for route ${settings.name}',
              );
              return MaterialPageRoute(
                builder: (_) => RouteErrorWidget(
                  error:
                      'The team ID "$teamIdString" is not valid. Please try again.',
                  routeName: '/team/view',
                  title: 'Invalid Team ID',
                ),
              );
            }

            return MaterialPageRoute(
              builder: (_) => viewer.TeamDashboardScreen(
                teamId: teamId,
                teamName: teamName,
              ),
            );

          case '/matches/live':
            final args = settings.arguments as Map<String, dynamic>?;
            final matchId = args?['matchId']?.toString();

            if (matchId == null) {
              debugPrint(
                '[Navigation] Error: Missing matchId for route ${settings.name}',
              );
              return MaterialPageRoute(
                builder: (_) => const RouteErrorWidget(
                  error: 'Match ID is required to view live match',
                  routeName: '/matches/live',
                  title: 'Missing Match Information',
                ),
              );
            }

            return MaterialPageRoute(
              builder: (_) => LiveMatchViewScreen(matchId: matchId),
            );

          case '/matches/scorecard':
            final args = settings.arguments as Map<String, dynamic>?;
            final matchId = args?['matchId']?.toString();

            if (matchId == null) {
              debugPrint(
                '[Navigation] Error: Missing matchId for route ${settings.name}',
              );
              return MaterialPageRoute(
                builder: (_) => const RouteErrorWidget(
                  error: 'Match ID is required to view scorecard',
                  routeName: '/matches/scorecard',
                  title: 'Missing Match Information',
                ),
              );
            }

            return MaterialPageRoute(
              builder: (_) => ScorecardScreen(matchId: matchId),
            );

          case '/tournaments/register-teams':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => TournamentTeamRegistrationScreen(
                tournamentName: (args?['tournamentName'] ?? '') as String,
                tournamentId: (args?['tournamentId']?.toString() ?? ''),
              ),
            );

          case '/player/view':
            final args = settings.arguments as Map<String, dynamic>?;

            if (args == null) {
              debugPrint(
                '[Navigation] Error: Missing arguments for route ${settings.name}',
              );
              return MaterialPageRoute(
                builder: (_) => const RouteErrorWidget(
                  error:
                      'Player information is required to view player details',
                  routeName: '/player/view',
                  title: 'Missing Player Information',
                ),
              );
            }

            return MaterialPageRoute(
              builder: (_) => player_view.PlayerDashboardScreen(
                playerName: (args['playerName'] ?? '').toString(),
                role: (args['role'] ?? '').toString(),
                teamName: (args['teamName'] ?? '').toString(),
                imageUrl: (args['imageUrl'] ?? 'https://picsum.photos/200')
                    .toString(),
                runs:
                    int.tryParse(args['runs']?.toString() ?? '') ??
                    (args['runs'] is int ? args['runs'] as int : 0),
                battingAvg:
                    double.tryParse(args['battingAvg']?.toString() ?? '') ??
                    0,
                strikeRate:
                    double.tryParse(args['strikeRate']?.toString() ?? '') ??
                    0,
                wickets:
                    int.tryParse(args['wickets']?.toString() ?? '') ??
                    (args['wickets'] is int ? args['wickets'] as int : 0),
              ),
            );
        }
        return null;
      },
    );
  }
}
