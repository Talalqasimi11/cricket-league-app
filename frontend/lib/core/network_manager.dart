import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class NetworkManager {
  static final NetworkManager _instance = NetworkManager._internal();
  static NetworkManager get instance => _instance;

  final _connectivity = Connectivity();
  bool _hasConnection = true;
  StreamController<bool> connectionChangeController =
      StreamController.broadcast();

  NetworkManager._internal() {
    _startMonitoring();
  }

  bool get hasConnection => _hasConnection;

  void _startMonitoring() {
    _connectivity.onConnectivityChanged.listen((result) async {
      if (result == ConnectivityResult.none) {
        _hasConnection = false;
        connectionChangeController.add(false);
      } else {
        // Verify actual internet connection
        try {
          // Try to reach our backend's health endpoint
          final response = await Api.checkHealth();
          _hasConnection = response;
          connectionChangeController.add(response);
        } catch (e) {
          _hasConnection = false;
          connectionChangeController.add(false);
        }
      }
    });
  }

  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    if (result == ConnectivityResult.none) {
      _hasConnection = false;
      connectionChangeController.add(false);
      return false;
    }

    try {
      final response = await Api.checkHealth();
      _hasConnection = response;
      connectionChangeController.add(response);
      return response;
    } catch (e) {
      _hasConnection = false;
      connectionChangeController.add(false);
      return false;
    }
  }

  void dispose() {
    connectionChangeController.close();
  }
}

class Api {
  static Future<bool> checkHealth() async {
    try {
      final response = await ApiClient.instance.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Health check failed: $e');
      return false;
    }
  }
}
