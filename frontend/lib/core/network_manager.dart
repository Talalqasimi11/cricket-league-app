import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http; // Use raw http package
import 'api_client.dart';

class NetworkManager {
  static final NetworkManager _instance = NetworkManager._internal();
  static NetworkManager get instance => _instance;

  final _connectivity = Connectivity();
  
  // Default to true to allow initial requests
  bool _hasConnection = true;
  
  final StreamController<bool> _connectionChangeController = StreamController.broadcast();

  NetworkManager._internal() {
    _startMonitoring();
  }

  bool get hasConnection => _hasConnection;
  Stream<bool> get onConnectionChanged => _connectionChangeController.stream;

  void _startMonitoring() {
    _connectivity.onConnectivityChanged.listen((results) async {
      // Check if any physical connection exists (WiFi/Mobile/Ethernet)
      bool hasPhysicalConnection = !results.contains(ConnectivityResult.none);

      if (!hasPhysicalConnection) {
        _updateConnectionStatus(false);
      } else {
        // We have a physical connection, now verify internet access
        final hasInternet = await _checkServerHealth();
        _updateConnectionStatus(hasInternet);
      }
    });
  }

  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    
    if (results.contains(ConnectivityResult.none)) {
      _updateConnectionStatus(false);
      return false;
    }

    final hasInternet = await _checkServerHealth();
    _updateConnectionStatus(hasInternet);
    return hasInternet;
  }

  void _updateConnectionStatus(bool isConnected) {
    if (_hasConnection != isConnected) {
      _hasConnection = isConnected;
      _connectionChangeController.add(isConnected);
      debugPrint('[NetworkManager] Connection status changed: $isConnected');
    }
  }

  /// INDEPENDENT HEALTH CHECK
  /// Uses raw http to avoid circular dependency with ApiClient
  Future<bool> _checkServerHealth() async {
    try {
      // Get base URL safely. ApiClient's config is just reading storage/env, so it's safe.
      final baseUrl = await ApiClient.instance.getConfiguredBaseUrl();
      final uri = Uri.parse('$baseUrl/health');
      
      // Short timeout for ping
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      // debugPrint('[NetworkManager] Health check failed: $e');
      return false;
    }
  }

  void dispose() {
    _connectionChangeController.close();
  }
}