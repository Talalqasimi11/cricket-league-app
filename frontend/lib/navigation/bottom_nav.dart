import 'package:flutter/material.dart';
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
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    MatchesScreen(),
    TournamentsScreen(),
    MyTeamScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_cricket),
            label: "Matches",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: "Tournament",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: "My Team",
          ),
        ],
      ),
    );
  }
}
