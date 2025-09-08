import 'package:flutter/material.dart';
import '../../widgets/bottom_nav.dart';
import '../team/viewer/team_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _teams = [
    {
      "name": "Titans XI",
      "trophies": 3,
      "image": "https://via.placeholder.com/300x300.png?text=Titans+XI",
    },
    {
      "name": "Warriors CC",
      "trophies": 2,
      "image": "https://via.placeholder.com/300x300.png?text=Warriors+CC",
    },
    {
      "name": "Strikers United",
      "trophies": 1,
      "image": "https://via.placeholder.com/300x300.png?text=Strikers+United",
    },
    {
      "name": "Raptors CC",
      "trophies": 4,
      "image": "https://via.placeholder.com/300x300.png?text=Raptors+CC",
    },
  ];

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _homeTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              const Text('All Teams', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search teams by name',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _teams.length,
            itemBuilder: (context, index) {
              final t = _teams[index];
              return GestureDetector(
                onTap: () {
                  // pass team data to dashboard
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeamDashboardScreen(
                        teamName: t['name'] as String,
                        imageUrl: t['image'] as String,
                        trophies: t['trophies'] as int,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: const [
                      BoxShadow(color: Color(0x11000000), blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(t['image'], width: 56, height: 56, fit: BoxFit.cover),
                    ),
                    title: Text(t['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Row(
                      children: [
                        const Icon(Icons.emoji_events, size: 16, color: Color(0xFF20DF6C)),
                        const SizedBox(width: 6),
                        Text(
                          '${t['trophies']} Trophies',
                          style: const TextStyle(color: Color(0xFF20DF6C)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _placeholder(String title) {
    return Center(
      child: Text(title, style: const TextStyle(fontSize: 20, color: Colors.grey)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _homeTab(),
      _placeholder('Matches - coming soon'),
      _placeholder('Tournaments - coming soon'),
      _placeholder('My Team - coming soon'),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: BottomNavBar(currentIndex: _selectedIndex, onTap: _onNavTapped),
    );
  }
}
