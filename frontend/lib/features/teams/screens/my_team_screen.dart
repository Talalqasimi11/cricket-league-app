import 'package:flutter/material.dart';
import 'team_dashboard_screen.dart';

class MyTeamScreen extends StatelessWidget {
  const MyTeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        elevation: 0,
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile avatar + name + email
          Column(
            children: [
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 56,
                    backgroundImage: NetworkImage(
                      "https://lh3.googleusercontent.com/a-/profile.png",
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                        onPressed: () {
                          // TODO: change profile picture
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "Ethan Carter",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const Text(
                "ethan.carter@email.com",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // My Teams Section
          const Text(
            "My Teams",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.grey.shade800,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  "https://picsum.photos/200/200",
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              title: const Text(
                "Cricket Club",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("Team Captain", style: TextStyle(color: Colors.grey)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onTap: () {
                // TODO: Navigate to team details
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeamDashboardScreen(
                      teamName: "Titans XI",
                      teamLogoUrl: "https://example.com/logo.png",
                      trophies: 3,
                      players: [
                        Player(name: "Arjun Sharma", role: "Captain", imageUrl: "..."),
                        Player(name: "Rohan Verma", role: "Batsman", imageUrl: "..."),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // My Matches Section
          const Text(
            "My Matches",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.grey.shade800,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      "https://picsum.photos/200/201",
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: const Text(
                    "Cricket Club vs Titans",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text("Won", style: TextStyle(color: Colors.green)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  onTap: () {
                    // TODO: Navigate to match details
                  },
                ),
                const Divider(color: Colors.grey),
                ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      "https://picsum.photos/200/202",
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: const Text(
                    "Cricket Club vs Warriors",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text("Lost", style: TextStyle(color: Colors.red)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  onTap: () {
                    // TODO: Navigate to match details
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Logout button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade800,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              // TODO: logout logic
            },
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey.shade900,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        currentIndex: 3, // Profile active
        onTap: (index) {
          // TODO: navigation handling
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.sports_cricket), label: "Matches"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Stats"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
