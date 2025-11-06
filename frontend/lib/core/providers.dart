import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/matches/providers/live_match_provider.dart';
import '../features/tournaments/providers/tournament_provider.dart';
import 'auth_provider.dart';

/// A widget that provides all the app's providers to its descendants
class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TournamentProvider()),
        ChangeNotifierProvider(create: (_) => LiveMatchProvider()),
      ],
      child: child,
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
}
