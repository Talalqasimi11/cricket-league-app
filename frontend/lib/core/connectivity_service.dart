import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// A service that monitors network connectivity and provides callbacks
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOffline = false;

  /// Returns the current offline status
  bool get isOffline => _isOffline;

  /// Start monitoring connectivity changes
  void startMonitoring({
    required Function(bool isOffline) onConnectivityChanged,
  }) {
    // Cancel any existing subscription
    _connectivitySubscription?.cancel();
    
    // Start new subscription
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final isConnected = results.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet,
      );

      _isOffline = !isConnected;
      onConnectivityChanged(_isOffline);
    });
  }

  /// Check current connectivity status
  Future<bool> checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _isOffline = !results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet,
    );
    return _isOffline;
  }

  /// Stop monitoring connectivity changes
  void stopMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Display a banner when offline
  static Widget offlineBanner() {
    return Container(
      width: double.infinity,
      color: Colors.red.shade700,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'You are offline',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}