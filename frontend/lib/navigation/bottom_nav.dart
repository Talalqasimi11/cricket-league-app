import 'package:flutter/material.dart';

// Import all screens
import '../screens/home/home_screen.dart';
import '../screens/matches/matches_screen.dart';
import '../screens/tournaments/tournaments_screen.dart';
import '../screens/team/my_team_screen.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    MatchesScreen(),
    TournamentsScreen(),
    MyTeamScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.sports_cricket), label: "Matches"),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: "Tournaments"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "My Team"),
        ],
      ),
    );
  }
}
