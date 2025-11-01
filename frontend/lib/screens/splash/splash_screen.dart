import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;
  Timer? _navigationTimer;
  List<ConnectivityResult> _initialConnectivity = [ConnectivityResult.mobile];

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _progressAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_progressController);
    _progressController.forward();

    _initialize();
  }

  Future<void> _initialize() async {
    // Step 1: Check initial connectivity
    await _checkInitialConnectivity();

    // Step 2: Wait for splash duration
    _navigationTimer = Timer(const Duration(milliseconds: 3200), () async {
      if (!mounted) return;

      // Step 3: Initialize auth
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initializeAuth();

      // Step 4: Navigate based on auth state
      final route = authProvider.isAuthenticated ? '/home' : '/login';
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(route);
      }
    });
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      _initialConnectivity = connectivity;
      debugPrint('Initial connectivity: $_initialConnectivity');
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
      _initialConnectivity = [ConnectivityResult.none];
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  Widget _buildConnectivityStatus(ConnectivityResult connectivityResult) {
    const primaryGreen = Color(0xFF38E07B);
    const mediumGreen = Color(0xFF366348);

    final isOffline = connectivityResult == ConnectivityResult.none;
    final connectivityIcon = isOffline ? Icons.wifi_off : Icons.wifi;
    final connectivityText = isOffline
        ? 'Offline Mode — Some features may be unavailable'
        : 'Your Local Cricket Hub';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              connectivityIcon,
              color: isOffline ? Colors.orange : const Color(0xFF96C5A9),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              isOffline ? 'Offline' : 'Online',
              style: TextStyle(
                color: isOffline ? Colors.orange : const Color(0xFF96C5A9),
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Getting things ready...',
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
        Text(
          connectivityText,
          style: TextStyle(
            color: isOffline ? Colors.orange : const Color(0xFF96C5A9),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF38E07B);
    const darkGreen = Color(0xFF122118);

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
                    child: Icon(Icons.emoji_events,
                        color: Colors.white, size: 80),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'CricLeague',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              StreamBuilder<List<ConnectivityResult>>(
                stream: Connectivity().onConnectivityChanged,
                initialData: _initialConnectivity,
                builder: (context, snapshot) {
                  final connectivityResult =
                      snapshot.data?.isNotEmpty == true ? snapshot.data!.first : ConnectivityResult.none;
                  return _buildConnectivityStatus(connectivityResult);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
