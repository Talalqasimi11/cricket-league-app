import 'package:flutter/material.dart';
import '../team/team_dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data (we'll replace with provider/backend later)
    final List<Map<String, String>> teams = [
      {"name": "Warriors", "trophies": "3"},
      {"name": "Titans", "trophies": "5"},
      {"name": "Strikers", "trophies": "2"},
      {"name": "Riders", "trophies": "1"},
      {"name": "Falcons", "trophies": "0"},
    ];

    final List<Map<String, String>> upcomingMatches = [
      {"match": "Warriors vs Titans", "time": "Today 4:00 PM"},
      {"match": "Strikers vs Riders", "time": "Tomorrow 10:00 AM"},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Home"), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: ListView(
            children: [
              const SizedBox(height: 12),
              // Search
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search teams, players...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                ),
              ),
              const SizedBox(height: 16),

              // Upcoming matches (horizontal)
              const Text("Upcoming / Live Matches", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: upcomingMatches.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final m = upcomingMatches[index];
                    return Container(
                      width: 260,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m["match"]!, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(m["time"]!, style: const TextStyle(color: Colors.black54)),
                          const Spacer(),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: ElevatedButton(
                              onPressed: () {
                                // TODO: open match details / live screen
                              },
                              child: const Text("View"),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // Teams header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("All Teams", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  // optional action for filter/sort
                  // IconButton(icon: Icon(Icons.filter_list), onPressed: () {})
                ],
              ),
              const SizedBox(height: 8),

              // Teams list
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: teams.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final team = teams[index];
                  return Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[700],
                        child: Text(team["name"]![0], style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(team["name"]!),
                      subtitle: Text("🏆 ${team['trophies']} trophies"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Open Team Dashboard (detail)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeamDashboardScreen(teamName: team["name"]!),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
