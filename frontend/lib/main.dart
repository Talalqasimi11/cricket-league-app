import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

// Core
import 'core/theme/theme_data.dart';
import 'core/api_client.dart';
import 'core/auth_provider.dart';
import 'core/auth_error_handler.dart';
import 'core/database/hive_service.dart';
import 'core/caching/cache_manager.dart';
import 'core/offline/offline_manager.dart';
import 'services/api_service.dart';
import 'services/activity_service.dart';

// Models
import 'features/teams/models/player.dart'; // ✅ Added Player Model

// Providers
import 'features/tournaments/providers/tournament_provider.dart';
import 'features/tournaments/providers/tournament_team_registration_provider.dart';
import 'features/matches/providers/live_match_provider.dart';
import 'features/matches/providers/match_provider.dart';
import 'features/teams/providers/team_provider.dart';
import 'features/tournaments/providers/tournament_stats_provider.dart';

// Screens
import 'screens/splash/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'features/matches/screens/matches_screen.dart';
import 'features/matches/screens/live_match_view_screen.dart';
import 'features/matches/screens/scorecard_screen.dart';
import 'features/tournaments/screens/tournaments_screen.dart';
import 'features/tournaments/screens/tournament_create_screen.dart';
import 'features/tournaments/screens/tournament_team_registration_screen.dart';
import 'features/teams/screens/my_team_screen.dart';
import 'features/teams/screens/create_team_screen.dart';
import 'features/stats/screens/statistics_screen.dart';
import 'screens/settings/account_screen.dart';
import 'screens/support/contact_screen.dart';
import 'screens/support/feedback_screen.dart';
import 'widgets/route_error_widget.dart';

// Viewer Screens (Aliased to avoid conflicts)
import 'screens/team/viewer/team_dashboard_screen.dart' as viewer;
// ✅ Update this import path to where you saved the viewer screen from the previous step
import 'screens/player/viewer/player_dashboard_viewer_screen.dart'
    as player_view;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform Error: $error');
    debugPrint('Stack trace: $stack');
    return true;
  };

  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap>
    with WidgetsBindingObserver {
  bool initialized = false;
  String? initError;
  OfflineManager? offlineManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    offlineManager?.dispose();
    HiveService().dispose();
    ApiClient.instance.dispose();
    AuthErrorHandler.dispose();
    super.dispose();
  }

  Future<void> initialize() async {
    try {
      await HiveService().init();
      await CacheManager.instance.init();

      final apiService = ApiService();
      offlineManager = OfflineManager(
        hiveService: HiveService(),
        apiService: apiService,
      );
      await offlineManager!.init();

      ApiClient.instance.init();

      // Log App Open
      await ActivityService().logAppOpen();

      await Future.delayed(const Duration(milliseconds: 80));

      if (!mounted) return;
      setState(() {
        initialized = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        initError = e.toString();
        initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Initializing app'),
              ],
            ),
          ),
        ),
      );
    }

    if (initError != null || offlineManager == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 12),
                Text(initError ?? 'Initialization failed'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      initError = null;
                      initialized = false;
                      offlineManager = null;
                    });
                    initialize();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        Provider<OfflineManager>.value(value: offlineManager!),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TournamentProvider()),
        ChangeNotifierProvider(
          create: (_) => TournamentTeamRegistrationProvider(),
        ),
        ChangeNotifierProvider(create: (_) => LiveMatchProvider()),
        ChangeNotifierProvider(create: (_) => MatchProvider()),
        ChangeNotifierProvider(create: (_) => TeamProvider()),
        ChangeNotifierProvider(create: (_) => TournamentStatsProvider()),
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
  bool authReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initAuth();
    });
  }

  Future<void> initAuth() async {
    try {
      final auth = context.read<AuthProvider>();
      await auth.initializeAuth();

      if (!mounted) return;

      final offline = context.read<OfflineManager>();
      context.read<TournamentProvider>().setOfflineManager(offline);

      AuthErrorHandler.initialize(context);

      setState(() {
        authReady = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        authReady = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!authReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppThemeData.light(),
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Authenticating'),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemeData.light(),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/matches': (context) => const MatchesScreen(),
        '/tournaments': (context) => const TournamentsScreen(isCaptain: true),
        '/my-team': (context) => const MyTeamScreen(),
        '/my-team/create': (context) => const CreateTeamScreen(),
        '/tournaments/create': (context) => const CreateTournamentScreen(),
        '/stats': (context) => const StatisticsScreen(),
        '/account': (context) => const AccountScreen(),
        '/contact': (context) => const ContactScreen(),
        '/feedback': (context) => const FeedbackScreen(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/team/view':
            final args = settings.arguments as Map?;
            final idString = args?['teamId']?.toString();
            final name = args?['teamName']?.toString();

            if (idString == null) {
              return MaterialPageRoute(
                builder: (_) => const RouteErrorWidget(
                  error: 'Team ID is required',
                  routeName: '/team/view',
                  title: 'Missing Team Information',
                ),
              );
            }

            final id = int.tryParse(idString);
            if (id == null) {
              return MaterialPageRoute(
                builder: (_) => const RouteErrorWidget(
                  error: 'Invalid team ID',
                  routeName: '/team/view',
                  title: 'Invalid ID',
                ),
              );
            }

            return MaterialPageRoute(
              builder: (_) =>
                  viewer.TeamDashboardScreen(teamId: id, teamName: name),
            );

          case '/matches/live':
            final args = settings.arguments as Map?;
            final matchId = args?['matchId']?.toString();

            if (matchId == null) {
              return MaterialPageRoute(
                builder: (_) => const RouteErrorWidget(
                  error: 'Match ID required',
                  routeName: '/matches/live',
                  title: 'Missing Match ID',
                ),
              );
            }

            return MaterialPageRoute(
              builder: (_) => LiveMatchViewScreen(matchId: matchId),
            );

          case '/matches/scorecard':
            final args = settings.arguments as Map?;
            final matchId = args?['matchId']?.toString();

            if (matchId == null) {
              return MaterialPageRoute(
                builder: (_) => const RouteErrorWidget(
                  error: 'Match ID required',
                  routeName: '/matches/scorecard',
                  title: 'Missing Match ID',
                ),
              );
            }

            return MaterialPageRoute(
              builder: (_) => ScorecardScreen(matchId: matchId),
            );

          case '/tournaments/register-teams':
            final args = settings.arguments as Map?;
            return MaterialPageRoute(
              builder: (_) => TournamentTeamRegistrationScreen(
                tournamentName: (args?['tournamentName'] ?? '') as String,
                tournamentId: (args?['tournamentId']?.toString() ?? ''),
              ),
            );

          // ✅ UPDATED PLAYER VIEW ROUTE TO SUPPORT NEW MODEL
          case '/player/view':
            final args = settings.arguments;

            if (args == null) {
              return MaterialPageRoute(
                builder: (_) => const RouteErrorWidget(
                  error: 'Player information missing',
                  routeName: '/player/view',
                  title: 'Missing Information',
                ),
              );
            }

            // Case 1: Arguments are already a Player object
            if (args is Player) {
              return MaterialPageRoute(
                builder: (_) =>
                    player_view.PlayerDashboardViewerScreen(player: args),
              );
            }

            // Case 2: Arguments are a Map (JSON) - Parse it safely
            if (args is Map<String, dynamic>) {
              try {
                final player = Player.fromJson(args);
                return MaterialPageRoute(
                  builder: (_) =>
                      player_view.PlayerDashboardViewerScreen(player: player),
                );
              } catch (e) {
                return MaterialPageRoute(
                  builder: (_) => RouteErrorWidget(
                    error: 'Error parsing player data: $e',
                    routeName: '/player/view',
                    title: 'Data Error',
                  ),
                );
              }
            }

            return MaterialPageRoute(
              builder: (_) => const RouteErrorWidget(
                error: 'Invalid argument type',
                routeName: '/player/view',
                title: 'Error',
              ),
            );
        }

        return null;
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => RouteErrorWidget(
          error: 'Unknown route',
          routeName: settings.name ?? '',
          title: 'Not Found',
        ),
      ),
    );
  }
}
