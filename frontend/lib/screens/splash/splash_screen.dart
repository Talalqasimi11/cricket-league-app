import 'dart:async';
import 'package:flutter/material.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_progressController);
    _progressController.forward();

    // navigate after 3s
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF38E07B);
    const darkGreen = Color(0xFF122118);
    const mediumGreen = Color(0xFF366348);
    const lightGreen = Color(0xFF96C5A9);

    return Scaffold(
      backgroundColor: darkGreen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.sports_cricket, color: primaryGreen, size: 100),
                  const Positioned(
                    top: -10,
                    right: -20,
                    child: Icon(Icons.emoji_events, color: Colors.white, size: 80),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'CricLeague',
                style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Column(
                children: [
                  const Text(
                    'Loading...',
                    style: TextStyle(
                      color: Color(0xFF96C5A9),
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 320),
                    height: 10,
                    decoration: BoxDecoration(
                      color: mediumGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, _) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progressAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: primaryGreen,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your Local Cricket Hub',
                    style: TextStyle(color: Color(0xFF96C5A9), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
