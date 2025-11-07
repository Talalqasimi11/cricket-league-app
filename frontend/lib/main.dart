<<<<<<< Local
<<<<<<< Local
<<<<<<< Local
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
import 'features/matches/screens/matches_screen.dart';
import 'features/matches/screens/live_match_view_screen.dart';
import 'features/matches/screens/scorecard_screen.dart';
import 'features/tournaments/screens/tournaments_screen.dart';
import 'features/tournaments/screens/tournament_create_screen.dart';
import 'features/tournaments/screens/tournament_team_registration_screen.dart'
    as team_reg;
import 'features/teams/screens/my_team_screen.dart';
import 'screens/team/viewer/team_dashboard_screen.dart' as viewer;
import 'screens/player/viewer/player_dashboard_screen.dart' as player_view;
import 'screens/settings/account_screen.dart';
import 'screens/settings/developer_settings_screen.dart';
import 'screens/support/contact_screen.dart';
import 'screens/support/feedback_screen.dart';

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
  debugPrint('[main] Running in debug mode. Skipping scheduler hacks — use the profiler for performance issues.');
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

class _AppBootstrapState extends State<AppBootstrap> {
  bool _isInitialized = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    debugPrint('[AppBootstrap] Starting non-blocking app initialization');

    try {
      // Set hardcoded ngrok URL for physical device communication
      await ApiClient.instance.setCustomBaseUrl('https://foveolar-louetta-unradiant.ngrok-free.dev');

      // Fire-and-forget ApiClient init (now non-blocking)
      ApiClient.instance.init();

      debugPrint('[AppBootstrap] ApiClient.init() called (not awaited)');

      // No other initialization needed - everything runs in background
      // Add other async initialization here if needed (all fire-and-forget)

      await Future.delayed(const Duration(milliseconds: 100)); // Brief delay for stability

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
      });
      debugPrint('[AppBootstrap] _isInitialized set to true - splash screen will appear immediately');
    } catch (e) {
      debugPrint('[AppBootstrap] App initialization error (should not block): $e');
      // Even on error, proceed with _isInitialized = true to show splash
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        // Don't set _initError - we want splash to show regardless
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
        // AuthProvider created normally. Its initialization which needs context
        // will be done inside AuthInitializer (after the first frame).
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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

    // Delay actual auth initialization to after the first frame so that
    // Provider.of(context) and other context-bound calls are safe and we
    // avoid triggering rebuilds during widget mounting.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }

  Future<void> _initializeAuth() async {
    try {
      // listen: false is used because we're calling this in init; we don't want
      // this method to subscribe the initState to changes.
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initializeAuth();
      setState(() {
        _authInitialized = true;
      });
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      // Continue even if auth init fails; app shows UI and user can retry/login.
      setState(() {
        _authInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_authInitialized) {
      return const MaterialApp(
        title: 'CricLeague',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
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

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
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
            '/tournaments/create': (context) => const CreateTournamentScreen(),
            '/account': (context) => const AccountScreen(),
            '/developer-settings': (context) => const DeveloperSettingsScreen(),
            '/contact': (context) => const ContactScreen(),
            '/feedback': (context) => const FeedbackScreen(),
          },
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/team/view':
                final args = settings.arguments as Map<String, dynamic>?;
                final teamIdString = args?['teamId']?.toString();
                final teamName = args?['teamName']?.toString();
                if (teamIdString == null) {
                  return MaterialPageRoute(
                    builder: (_) => const Scaffold(
                      body: Center(child: Text('Missing teamId')),
                    ),
                  );
                }
                final teamId = int.tryParse(teamIdString);
                if (teamId == null) {
                  return MaterialPageRoute(
                    builder: (_) => const Scaffold(
                      body: Center(child: Text('Invalid teamId')),
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
                  return MaterialPageRoute(
                    builder: (_) => const Scaffold(
                      body: Center(child: Text('Missing matchId')),
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
                  return MaterialPageRoute(
                    builder: (_) => const Scaffold(
                      body: Center(child: Text('Missing matchId')),
                    ),
                  );
                }
                return MaterialPageRoute(
                  builder: (_) => ScorecardScreen(matchId: matchId),
                );
              case '/tournaments/register-teams':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (_) => team_reg.RegisterTeamsScreen(
                    tournamentName: (args?['tournamentName'] ?? '') as String,
                    tournamentId: args?['tournamentId']?.toString(),
                  ),
                );
              case '/player/view':
                final args = settings.arguments as Map<String, dynamic>?;
                if (args == null) {
                  return MaterialPageRoute(
                    builder: (_) => const Scaffold(
                      body: Center(child: Text('Missing player args')),
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
      },
    );
  }
}
=======
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
import 'features/matches/screens/matches_screen.dart';
import 'features/matches/screens/live_match_view_screen.dart';
import 'features/matches/screens/scorecard_screen.dart';
import 'features/tournaments/screens/tournaments_screen.dart';
import 'features/tournaments/screens/tournament_create_screen.dart';
import 'features/tournaments/screens/tournament_team_registration_screen.dart'
    as team_reg;
import 'features/teams/screens/my_team_screen.dart';
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
  debugPrint('[main] Running in debug mode. Skipping scheduler hacks — use the profiler for performance issues.');
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

class _AppBootstrapState extends State<AppBootstrap> {
  bool _isInitialized = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    debugPrint('[AppBootstrap] Starting non-blocking app initialization');

    try {
      // Set hardcoded ngrok URL for physical device communication
      await ApiClient.instance.setCustomBaseUrl('https://foveolar-louetta-unradiant.ngrok-free.dev');

      // Fire-and-forget ApiClient init (now non-blocking)
      ApiClient.instance.init();

      debugPrint('[AppBootstrap] ApiClient.init() called (not awaited)');

      // No other initialization needed - everything runs in background
      // Add other async initialization here if needed (all fire-and-forget)

      await Future.delayed(const Duration(milliseconds: 100)); // Brief delay for stability

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
      });
      debugPrint('[AppBootstrap] _isInitialized set to true - splash screen will appear immediately');
    } catch (e) {
      debugPrint('[AppBootstrap] App initialization error (should not block): $e');
      // Even on error, proceed with _isInitialized = true to show splash
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        // Don't set _initError - we want splash to show regardless
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
        // AuthProvider created normally. Its initialization which needs context
        // will be done inside AuthInitializer (after the first frame).
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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

class _AuthInitializerState extends State<AuthInitializer> with WidgetsBindingObserver {
  bool _authInitialized = false;

  @override
  void initState() {
    super.initState();
    
    // Add lifecycle observer to handle app termination
    WidgetsBinding.instance.addObserver(this);

    // Delay actual auth initialization to after the first frame so that
    // Provider.of(context) and other context-bound calls are safe and we
    // avoid triggering rebuilds during widget mounting.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }
  
  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    // Clean up ApiClient resources
    try {
      ApiClient.instance.dispose();
      debugPrint('[AuthInitializer] ApiClient disposed successfully');
    } catch (e) {
      debugPrint('[AuthInitializer] Error disposing ApiClient: $e');
    }
    
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.detached:
        // App is being terminated, clean up resources
        debugPrint('[AppLifecycle] App detached, cleaning up resources...');
        try {
          ApiClient.instance.dispose();
        } catch (e) {
          debugPrint('[AppLifecycle] Error disposing ApiClient: $e');
        }
        break;
      case AppLifecycleState.paused:
        debugPrint('[AppLifecycle] App paused');
        break;
      case AppLifecycleState.resumed:
        debugPrint('[AppLifecycle] App resumed');
        break;
      case AppLifecycleState.inactive:
        debugPrint('[AppLifecycle] App inactive');
        break;
      case AppLifecycleState.hidden:
        debugPrint('[AppLifecycle] App hidden');
        break;
    }
  }

  Future<void> _initializeAuth() async {
    try {
      // listen: false is used because we're calling this in init; we don't want
      // this method to subscribe the initState to changes.
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initializeAuth();
      setState(() {
        _authInitialized = true;
      });
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      // Continue even if auth init fails; app shows UI and user can retry/login.
      setState(() {
        _authInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_authInitialized) {
      return const MaterialApp(
        title: 'CricLeague',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
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

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
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
            '/tournaments/create': (context) => const CreateTournamentScreen(),
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
                  debugPrint('[Navigation] Error: Missing teamId for route ${settings.name}');
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
                  debugPrint('[Navigation] Error: Invalid teamId "$teamIdString" for route ${settings.name}');
                  return MaterialPageRoute(
                    builder: (_) => RouteErrorWidget(
                      error: 'The team ID "$teamIdString" is not valid. Please try again.',
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
                  debugPrint('[Navigation] Error: Missing matchId for route ${settings.name}');
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
                  debugPrint('[Navigation] Error: Missing matchId for route ${settings.name}');
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
                  builder: (_) => team_reg.RegisterTeamsScreen(
                    tournamentName: (args?['tournamentName'] ?? '') as String,
                    tournamentId: args?['tournamentId']?.toString(),
                  ),
                );
                
              case '/player/view':
                final args = settings.arguments as Map<String, dynamic>?;
                
                if (args == null) {
                  debugPrint('[Navigation] Error: Missing arguments for route ${settings.name}');
                  return MaterialPageRoute(
                    builder: (_) => const RouteErrorWidget(
                      error: 'Player information is required to view player details',
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
      },
    );
  }
}
>>>>>>> Remote
=======
=======
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
import 'features/matches/screens/matches_screen.dart';
import 'features/matches/screens/live_match_view_screen.dart';
import 'features/matches/screens/scorecard_screen.dart';
import 'features/tournaments/screens/tournaments_screen.dart';
import 'features/tournaments/screens/tournament_create_screen.dart';
import 'features/tournaments/screens/tournament_team_registration_screen.dart'
    as team_reg;
import 'features/teams/screens/my_team_screen.dart';
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
  debugPrint('[main] Running in debug mode. Skipping scheduler hacks — use the profiler for performance issues.');
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

class _AppBootstrapState extends State<AppBootstrap> {
  bool _isInitialized = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    debugPrint('[AppBootstrap] Starting non-blocking app initialization');

    try {
      // Set hardcoded ngrok URL for physical device communication
      await ApiClient.instance.setCustomBaseUrl('https://foveolar-louetta-unradiant.ngrok-free.dev');

      // Fire-and-forget ApiClient init (now non-blocking)
      ApiClient.instance.init();

      debugPrint('[AppBootstrap] ApiClient.init() called (not awaited)');

      // No other initialization needed - everything runs in background
      // Add other async initialization here if needed (all fire-and-forget)

      await Future.delayed(const Duration(milliseconds: 100)); // Brief delay for stability

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
      });
      debugPrint('[AppBootstrap] _isInitialized set to true - splash screen will appear immediately');
    } catch (e) {
      debugPrint('[AppBootstrap] App initialization error (should not block): $e');
      // Even on error, proceed with _isInitialized = true to show splash
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        // Don't set _initError - we want splash to show regardless
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
        // AuthProvider created normally. Its initialization which needs context
        // will be done inside AuthInitializer (after the first frame).
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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

class _AuthInitializerState extends State<AuthInitializer> with WidgetsBindingObserver {
  bool _authInitialized = false;

  @override
  void initState() {
    super.initState();
    
    // Add lifecycle observer to handle app termination
    WidgetsBinding.instance.addObserver(this);

    // Delay actual auth initialization to after the first frame so that
    // Provider.of(context) and other context-bound calls are safe and we
    // avoid triggering rebuilds during widget mounting.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }
  
  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    // Clean up ApiClient resources
    try {
      ApiClient.instance.dispose();
      debugPrint('[AuthInitializer] ApiClient disposed successfully');
    } catch (e) {
      debugPrint('[AuthInitializer] Error disposing ApiClient: $e');
    }
    
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.detached:
        // App is being terminated, clean up resources
        debugPrint('[AppLifecycle] App detached, cleaning up resources...');
        try {
          ApiClient.instance.dispose();
        } catch (e) {
          debugPrint('[AppLifecycle] Error disposing ApiClient: $e');
        }
        break;
      case AppLifecycleState.paused:
        debugPrint('[AppLifecycle] App paused');
        break;
      case AppLifecycleState.resumed:
        debugPrint('[AppLifecycle] App resumed');
        break;
      case AppLifecycleState.inactive:
        debugPrint('[AppLifecycle] App inactive');
        break;
      case AppLifecycleState.hidden:
        debugPrint('[AppLifecycle] App hidden');
        break;
    }
  }

  Future<void> _initializeAuth() async {
    try {
      // listen: false is used because we're calling this in init; we don't want
      // this method to subscribe the initState to changes.
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initializeAuth();
      setState(() {
        _authInitialized = true;
      });
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      // Continue even if auth init fails; app shows UI and user can retry/login.
      setState(() {
        _authInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_authInitialized) {
      return const MaterialApp(
        title: 'CricLeague',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
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

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
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
            '/tournaments/create': (context) => const CreateTournamentScreen(),
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
                  debugPrint('[Navigation] Error: Missing teamId for route ${settings.name}');
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
                  debugPrint('[Navigation] Error: Invalid teamId "$teamIdString" for route ${settings.name}');
                  return MaterialPageRoute(
                    builder: (_) => RouteErrorWidget(
                      error: 'The team ID "$teamIdString" is not valid. Please try again.',
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
                  debugPrint('[Navigation] Error: Missing matchId for route ${settings.name}');
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
                  debugPrint('[Navigation] Error: Missing matchId for route ${settings.name}');
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
                  builder: (_) => team_reg.RegisterTeamsScreen(
                    tournamentName: (args?['tournamentName'] ?? '') as String,
                    tournamentId: args?['tournamentId']?.toString(),
                  ),
                );
                
              case '/player/view':
                final args = settings.arguments as Map<String, dynamic>?;
                
                if (args == null) {
                  debugPrint('[Navigation] Error: Missing arguments for route ${settings.name}');
                  return MaterialPageRoute(
                    builder: (_) => const RouteErrorWidget(
                      error: 'Player information is required to view player details',
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
      },
    );
  }
}

>>>>>>> Remote
=======
﻿import 'package:flutter/material.dart';
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
import 'features/matches/screens/matches_screen.dart';
import 'features/matches/screens/live_match_view_screen.dart';
import 'features/matches/screens/scorecard_screen.dart';
import 'features/tournaments/screens/tournaments_screen.dart';
import 'features/tournaments/screens/tournament_create_screen.dart';
import 'features/tournaments/screens/tournament_team_registration_screen.dart'
    as team_reg;
import 'features/teams/screens/my_team_screen.dart';
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
  debugPrint('[main] Running in debug mode. Skipping scheduler hacks — use the profiler for performance issues.');
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

class _AppBootstrapState extends State<AppBootstrap> {
  bool _isInitialized = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    debugPrint('[AppBootstrap] Starting non-blocking app initialization');

    try {
      // Set hardcoded ngrok URL for physical device communication
      await ApiClient.instance.setCustomBaseUrl('https://foveolar-louetta-unradiant.ngrok-free.dev');

      // Fire-and-forget ApiClient init (now non-blocking)
      ApiClient.instance.init();

      debugPrint('[AppBootstrap] ApiClient.init() called (not awaited)');

      // No other initialization needed - everything runs in background
      // Add other async initialization here if needed (all fire-and-forget)

      await Future.delayed(const Duration(milliseconds: 100)); // Brief delay for stability

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
      });
      debugPrint('[AppBootstrap] _isInitialized set to true - splash screen will appear immediately');
    } catch (e) {
      debugPrint('[AppBootstrap] App initialization error (should not block): $e');
      // Even on error, proceed with _isInitialized = true to show splash
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        // Don't set _initError - we want splash to show regardless
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
        // AuthProvider created normally. Its initialization which needs context
        // will be done inside AuthInitializer (after the first frame).
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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

class _AuthInitializerState extends State<AuthInitializer> with WidgetsBindingObserver {
  bool _authInitialized = false;

  @override
  void initState() {
    super.initState();
    
    // Add lifecycle observer to handle app termination
    WidgetsBinding.instance.addObserver(this);

    // Delay actual auth initialization to after the first frame so that
    // Provider.of(context) and other context-bound calls are safe and we
    // avoid triggering rebuilds during widget mounting.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }
  
  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    // Clean up ApiClient resources
    try {
      ApiClient.instance.dispose();
      debugPrint('[AuthInitializer] ApiClient disposed successfully');
    } catch (e) {
      debugPrint('[AuthInitializer] Error disposing ApiClient: $e');
    }
    
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.detached:
        // App is being terminated, clean up resources
        debugPrint('[AppLifecycle] App detached, cleaning up resources...');
        try {
          ApiClient.instance.dispose();
        } catch (e) {
          debugPrint('[AppLifecycle] Error disposing ApiClient: $e');
        }
        break;
      case AppLifecycleState.paused:
        debugPrint('[AppLifecycle] App paused');
        break;
      case AppLifecycleState.resumed:
        debugPrint('[AppLifecycle] App resumed');
        break;
      case AppLifecycleState.inactive:
        debugPrint('[AppLifecycle] App inactive');
        break;
      case AppLifecycleState.hidden:
        debugPrint('[AppLifecycle] App hidden');
        break;
    }
  }

  Future<void> _initializeAuth() async {
    try {
      // listen: false is used because we're calling this in init; we don't want
      // this method to subscribe the initState to changes.
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initializeAuth();
      setState(() {
        _authInitialized = true;
      });
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      // Continue even if auth init fails; app shows UI and user can retry/login.
      setState(() {
        _authInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_authInitialized) {
      return const MaterialApp(
        title: 'CricLeague',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
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

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
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
            '/tournaments/create': (context) => const CreateTournamentScreen(),
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
                  debugPrint('[Navigation] Error: Missing teamId for route ${settings.name}');
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
                  debugPrint('[Navigation] Error: Invalid teamId "$teamIdString" for route ${settings.name}');
                  return MaterialPageRoute(
                    builder: (_) => RouteErrorWidget(
                      error: 'The team ID "$teamIdString" is not valid. Please try again.',
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
                  debugPrint('[Navigation] Error: Missing matchId for route ${settings.name}');
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
                  debugPrint('[Navigation] Error: Missing matchId for route ${settings.name}');
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
                  builder: (_) => team_reg.RegisterTeamsScreen(
                    tournamentName: (args?['tournamentName'] ?? '') as String,
                    tournamentId: args?['tournamentId']?.toString(),
                  ),
                );
                
              case '/player/view':
                final args = settings.arguments as Map<String, dynamic>?;
                
                if (args == null) {
                  debugPrint('[Navigation] Error: Missing arguments for route ${settings.name}');
                  return MaterialPageRoute(
                    builder: (_) => const RouteErrorWidget(
                      error: 'Player information is required to view player details',
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
      },
    );
  }
}
=======
=======
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
import 'features/matches/screens/matches_screen.dart';
import 'features/matches/screens/live_match_view_screen.dart';
import 'features/matches/screens/scorecard_screen.dart';
import 'features/tournaments/screens/tournaments_screen.dart';
import 'features/tournaments/screens/tournament_create_screen.dart';
import 'features/tournaments/screens/tournament_team_registration_screen.dart'
    as team_reg;
import 'features/teams/screens/my_team_screen.dart';
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
  debugPrint('[main] Running in debug mode. Skipping scheduler hacks — use the profiler for performance issues.');
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

class _AppBootstrapState extends State<AppBootstrap> {
  bool _isInitialized = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    debugPrint('[AppBootstrap] Starting non-blocking app initialization');

    try {
      // Set hardcoded ngrok URL for physical device communication
      await ApiClient.instance.setCustomBaseUrl('https://foveolar-louetta-unradiant.ngrok-free.dev');

      // Fire-and-forget ApiClient init (now non-blocking)
      ApiClient.instance.init();

      debugPrint('[AppBootstrap] ApiClient.init() called (not awaited)');

      // No other initialization needed - everything runs in background
      // Add other async initialization here if needed (all fire-and-forget)

      await Future.delayed(const Duration(milliseconds: 100)); // Brief delay for stability

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
      });
      debugPrint('[AppBootstrap] _isInitialized set to true - splash screen will appear immediately');
    } catch (e) {
      debugPrint('[AppBootstrap] App initialization error (should not block): $e');
      // Even on error, proceed with _isInitialized = true to show splash
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        // Don't set _initError - we want splash to show regardless
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
        // AuthProvider created normally. Its initialization which needs context
        // will be done inside AuthInitializer (after the first frame).
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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

class _AuthInitializerState extends State<AuthInitializer> with WidgetsBindingObserver {
  bool _authInitialized = false;

  @override
  void initState() {
    super.initState();
    
    // Add lifecycle observer to handle app termination
    WidgetsBinding.instance.addObserver(this);

    // Delay actual auth initialization to after the first frame so that
    // Provider.of(context) and other context-bound calls are safe and we
    // avoid triggering rebuilds during widget mounting.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }
  
  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    // Clean up ApiClient resources
    try {
      ApiClient.instance.dispose();
      debugPrint('[AuthInitializer] ApiClient disposed successfully');
    } catch (e) {
      debugPrint('[AuthInitializer] Error disposing ApiClient: $e');
    }
    
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.detached:
        // App is being terminated, clean up resources
        debugPrint('[AppLifecycle] App detached, cleaning up resources...');
        try {
          ApiClient.instance.dispose();
        } catch (e) {
          debugPrint('[AppLifecycle] Error disposing ApiClient: $e');
        }
        break;
      case AppLifecycleState.paused:
        debugPrint('[AppLifecycle] App paused');
        break;
      case AppLifecycleState.resumed:
        debugPrint('[AppLifecycle] App resumed');
        break;
      case AppLifecycleState.inactive:
        debugPrint('[AppLifecycle] App inactive');
        break;
      case AppLifecycleState.hidden:
        debugPrint('[AppLifecycle] App hidden');
        break;
    }
  }

  Future<void> _initializeAuth() async {
    try {
      // listen: false is used because we're calling this in init; we don't want
      // this method to subscribe the initState to changes.
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initializeAuth();
      setState(() {
        _authInitialized = true;
      });
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      // Continue even if auth init fails; app shows UI and user can retry/login.
      setState(() {
        _authInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_authInitialized) {
      return const MaterialApp(
        title: 'CricLeague',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
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

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
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
            '/tournaments/create': (context) => const CreateTournamentScreen(),
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
                  debugPrint('[Navigation] Error: Missing teamId for route ${settings.name}');
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
                  debugPrint('[Navigation] Error: Invalid teamId "$teamIdString" for route ${settings.name}');
                  return MaterialPageRoute(
                    builder: (_) => RouteErrorWidget(
                      error: 'The team ID "$teamIdString" is not valid. Please try again.',
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
                  debugPrint('[Navigation] Error: Missing matchId for route ${settings.name}');
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
                  debugPrint('[Navigation] Error: Missing matchId for route ${settings.name}');
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
                  builder: (_) => team_reg.RegisterTeamsScreen(
                    tournamentName: (args?['tournamentName'] ?? '') as String,
                    tournamentId: args?['tournamentId']?.toString(),
                  ),
                );
                
              case '/player/view':
                final args = settings.arguments as Map<String, dynamic>?;
                
                if (args == null) {
                  debugPrint('[Navigation] Error: Missing arguments for route ${settings.name}');
                  return MaterialPageRoute(
                    builder: (_) => const RouteErrorWidget(
                      error: 'Player information is required to view player details',
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
      },
    );
  }
}

>>>>>>> Remote
>>>>>>> Remote
