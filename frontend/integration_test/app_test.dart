import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:frontend/main.dart' as app;
import 'package:frontend/core/auth_provider.dart';
import 'package:frontend/features/tournaments/providers/tournament_provider.dart';
import 'package:frontend/features/matches/providers/live_match_provider.dart';
import 'package:provider/provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End App Test', () {
    testWidgets('App should start and initialize properly', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify app loads to splash screen
      expect(find.text('CricLeague'), findsOneWidget);
    });

    testWidgets('Login flow should work', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to login
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(find.byType(TextFormField).first, '1234567890');
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      // Tap login button
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Verify logged in state
      final context = tester.element(find.byType(MaterialApp));
      expect(context.read<AuthProvider>().isAuthenticated, true);
    });

    testWidgets('Tournament list should load', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to tournaments
      await tester.tap(find.text('Tournaments'));
      await tester.pumpAndSettle();

      // Verify tournaments load
      final context = tester.element(find.byType(MaterialApp));
      expect(context.read<TournamentProvider>().isLoading, false);
      expect(context.read<TournamentProvider>().error, null);
    });

    testWidgets('Live match viewing should work', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to live matches
      await tester.tap(find.text('Live Matches'));
      await tester.pumpAndSettle();

      // Select first match if available
      final liveMatchProvider = tester
          .element(find.byType(MaterialApp))
          .read<LiveMatchProvider>();

      if (liveMatchProvider.matches.isNotEmpty) {
        final firstMatch = liveMatchProvider.matches.first;
        await tester.tap(find.text(firstMatch.team1Name));
        await tester.pumpAndSettle();

        // Verify match details load
        expect(find.text('Live Score'), findsOneWidget);
        expect(
          find.text('${firstMatch.team1Name} vs ${firstMatch.team2Name}'),
          findsOneWidget,
        );
      }
    });

    testWidgets('Theme switching should work', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Toggle theme
      await tester.tap(find.text('Dark Mode'));
      await tester.pumpAndSettle();

      // Verify theme changed
      final context = tester.element(find.byType(MaterialApp));
      expect(Theme.of(context).brightness, Brightness.dark);
    });
  });
}
