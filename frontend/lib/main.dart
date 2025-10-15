import 'package:flutter/material.dart';
import 'screens/splash/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'features/matches/screens/matches_screen.dart';
import 'features/matches/screens/live_match_view_screen.dart';
import 'features/matches/screens/scorecard_screen.dart';
import 'features/tournaments/screens/tournaments_screen.dart';
import 'features/tournaments/screens/tournament_create_screen.dart';
import 'features/tournaments/screens/tournament_team_registration_screen.dart';
import 'features/teams/screens/my_team_screen.dart';
import 'screens/team/viewer/team_dashboard_screen.dart' as viewer;
import 'screens/player/viewer/player_dashboard_screen.dart' as player_view;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CricLeague',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF20DF6C),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        // Avoid forcing white text globally on buttons; let defaults ensure proper contrast.
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/matches': (context) => const MatchesScreen(),
        '/tournaments': (context) => const TournamentsScreen(isCaptain: true),
        '/my-team': (context) => const MyTeamScreen(),
        '/tournaments/create': (context) => const CreateTournamentScreen(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/team/view':
            final args = settings.arguments as Map<String, dynamic>?;
            final teamId = args?['teamId']?.toString();
            final teamName = args?['teamName']?.toString();
            if (teamId == null) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(body: Center(child: Text('Missing teamId'))),
              );
            }
            return MaterialPageRoute(
              builder: (_) => viewer.TeamDashboardScreen(teamId: teamId, teamName: teamName),
            );
          case '/matches/live':
            final args = settings.arguments as Map<String, dynamic>?;
            final matchId = args?['matchId']?.toString();
            if (matchId == null) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(body: Center(child: Text('Missing matchId'))),
              );
            }
            return MaterialPageRoute(builder: (_) => LiveMatchViewScreen(matchId: matchId));
          case '/matches/scorecard':
            final args = settings.arguments as Map<String, dynamic>?;
            final matchId = args?['matchId']?.toString();
            if (matchId == null) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(body: Center(child: Text('Missing matchId'))),
              );
            }
            return MaterialPageRoute(builder: (_) => ScorecardScreen(matchId: matchId));
          case '/tournaments/register-teams':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => RegisterTeamsScreen(
                tournamentName: (args?['tournamentName'] ?? '') as String,
                tournamentId: args?['tournamentId']?.toString(),
              ),
            );
          case '/player/view':
            final args = settings.arguments as Map<String, dynamic>?;
            if (args == null) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(body: Center(child: Text('Missing player args'))),
              );
            }
            return MaterialPageRoute(
              builder: (_) => player_view.PlayerDashboardScreen(
                playerName: (args['playerName'] ?? '').toString(),
                role: (args['role'] ?? '').toString(),
                teamName: (args['teamName'] ?? '').toString(),
                imageUrl: (args['imageUrl'] ?? 'https://picsum.photos/200').toString(),
                runs: int.tryParse(args['runs']?.toString() ?? '') ?? (args['runs'] is int ? args['runs'] as int : 0),
                battingAvg: double.tryParse(args['battingAvg']?.toString() ?? '') ?? 0,
                strikeRate: double.tryParse(args['strikeRate']?.toString() ?? '') ?? 0,
                wickets: int.tryParse(args['wickets']?.toString() ?? '') ?? (args['wickets'] is int ? args['wickets'] as int : 0),
              ),
            );
        }
        return null;
      },
    );
  }
}
