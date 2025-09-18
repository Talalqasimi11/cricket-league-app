import 'package:flutter/material.dart';

class SelectLineupScreen extends StatefulWidget {
  final String teamName;

  const SelectLineupScreen({super.key, required this.teamName});

  @override
  State<SelectLineupScreen> createState() => _SelectLineupScreenState();
}

class _SelectLineupScreenState extends State<SelectLineupScreen> {
  // Example players list (later you’ll fetch from DB)
  final List<Map<String, dynamic>> players = [
    {
      "name": "Virat Kohli",
      "role": "Batsman",
      "image":
          "https://lh3.googleusercontent.com/aida-public/AB6AXuCvS4QZWpbq0Aqf-mHBSSk51SyaCgAvbu5mDRNC1on548maEczRcLFitwJKYsaTiq7s7GCfybQhMQb20r6O3jUMNIAQi4DTpp6fTT97OK7W35yFHK23FFF4WeopwkYHzcNPkPUw9hDwq70GzFpsDFcYrv_zztqFGmx0WdjezvrIP8cX-9XcH9G_O8i-ZCKGMIgNJJDfe_xJfJ0EJscLMWA9jV_7klGluNcGYMxQpxeWVYhQM8zZgqCIGCX5hrjSZD299kmsbStD2JdB",
      "selected": true,
    },
    {
      "name": "Rohit Sharma",
      "role": "Batsman",
      "image":
          "https://lh3.googleusercontent.com/aida-public/AB6AXuBpSi4Kbmc4twBOqnj2PSqx-noe4ZISYUYRPHtCoRYKE-kr3k4F_J09JoZj9WWBmwFxJCyaYay7oYySmV2P8sIcVqlItRFrob1k0pFl6yGca5p4tq6Az02u9tqvPOOQ6nyMJw4pcYIoHFDMsPCzDnaHCbLFZ9wQCecDjtlaTNuDDEdhjNyTswghJEcy8fy6mj_SuO5BGqdS1-Ouv_XzjTEkMx9kj04fn3ygu5Ay-6_JRw4Zl1XyNl0JaJa2AJLi3tv5gd_RjhnnzoSH",
      "selected": true,
    },
    {
      "name": "Jasprit Bumrah",
      "role": "Bowler",
      "image":
          "https://lh3.googleusercontent.com/aida-public/AB6AXuCdwd9UOoYALuVupwgxFhlqIHpLo_C2JR7IxlBHSN9fA0IixC2BUXJ13cLwlOjHe7qWhDlZj6GgZajI-j3vu_DcVRK7-T723DI4oputlN4kBSJV1IQ6wuMzlNaS0wvyZykZxERti2lHpLgMRjwZ1U-icJACJ1t6HpRqJX3sHg9rDaiqZ8pNG-nWUP5nHR8FgYQmjbp_qs-_p4cykzCJqWGoiB1aCHqUHLlJ1jHauVhm9CRpR66IDk1jorvWtklPgwh6n5q75TsYyJ7c",
      "selected": true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2D2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2D2A),
        elevation: 0,
        title: Text(
          "Select Lineup (11)",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Team Players (15)",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C4A44),
                    foregroundColor: const Color(0xFF95c6a9),
                    shape: StadiumBorder(),
                  ),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text("Add Player"),
                ),
              ],
            ),
          ),

          // Players List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2D2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(radius: 22, backgroundImage: NetworkImage(player["image"])),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                player["name"],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                player["role"],
                                style: const TextStyle(color: Color(0xFF95c6a9), fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          player["selected"] ? Icons.check_circle : Icons.circle_outlined,
                          color: player["selected"] ? Colors.greenAccent : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            player["selected"] = !player["selected"];
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Confirm Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                final selected = players.where((p) => p["selected"]).toList();
                Navigator.pop(context, selected); // return selected lineup
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF36e27b),
                foregroundColor: const Color(0xFF122118),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "Confirm Lineup",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
