import 'package:flutter/material.dart';

void main() {
  runApp(const CricketApp());
}

class CricketApp extends StatelessWidget {
  const CricketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cricket League',
      home: const Scaffold(
        body: Center(child: Text('🏏 Cricket League App')),

        
      ),
    );
  }
}
