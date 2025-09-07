import 'package:flutter/material.dart';
import 'navigation/bottom_nav.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cricket League App',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const BottomNav(),
    );
  }
}
