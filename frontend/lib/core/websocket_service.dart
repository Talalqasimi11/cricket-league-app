import 'dart:async';
import 'dart:developer' as developer;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_client.dart';

class WebSocketService {
  WebSocketService._();
  static final WebSocketService instance = WebSocketService._();

  IO.Socket? _socket;
  String? _currentMatchId;
  bool _isConnected = false;

  // Reconnection configuration
  static const int _maxReconnectAttempts = 5;
  static const int _initialReconnectDelay = 1000;
  static const int _maxReconnectDelay = 5000;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  // Callbacks
  Function(Map<String, dynamic>)? onScoreUpdate;
  Function(Map<String, dynamic>)? onInningsEnded;
  Function(String)? onError;
  Function()? onConnected;
  Function()? onDisconnected;

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _handleDisconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      onError?.call('Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    final delay = _initialReconnectDelay * _reconnectAttempts;
    final cappedDelay = delay > _maxReconnectDelay ? _maxReconnectDelay : delay;

    _cancelReconnectTimer();
    _reconnectTimer = Timer(Duration(milliseconds: cappedDelay), () {
      if (_currentMatchId != null) {
        connect(_currentMatchId!);
      }
    });
  }

  bool get isConnected => _isConnected;
  String? get currentMatchId => _currentMatchId;

  // Get WebSocket URL from base URL
  String _getWebSocketUrl(String baseUrl) {
    if (baseUrl.startsWith('https://')) {
      return baseUrl.replaceFirst('https://', 'wss://');
    } else {
      return baseUrl.replaceFirst('http://', 'ws://');
    }
  }

  // Additional event handlers
  Function(Map<String, dynamic>)? onSubscribed;
  Function(Map<String, dynamic>)? onSubscribeError;

  Future<void> connect(String matchId) async {
    // Don't reconnect if already connected to the same match
    if (_isConnected && _currentMatchId == matchId) {
      return;
    }

    // Disconnect if connected to a different match
    if (_currentMatchId != null && _currentMatchId != matchId) {
      await disconnect();
    }

    _currentMatchId = matchId;

    try {
      // Get base URL
      final baseUrl = await ApiClient.instance.getConfiguredBaseUrl();
      final wsUrl = _getWebSocketUrl(baseUrl);

  // Get auth token - try multiple sources
      String? token;
      try {
        token = await ApiClient.instance.token;
      } catch (e) {
        developer.log('Error getting token from ApiClient: $e');
      }

      // Fallback: try to get from shared preferences or local storage
      if (token == null || token.isEmpty) {
        // For web, try localStorage
        try {
          // This is a simplified approach - in real app you'd use proper storage
          token = ''; // Will be handled by auth middleware
        } catch (e) {
          developer.log('Error getting token from storage: $e');
        }
      }

      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Create Socket.IO connection to live-score namespace
      _socket = IO.io(
        '$wsUrl/live-score',
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': token})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(_initialReconnectDelay)
            .setReconnectionDelayMax(_maxReconnectDelay)
            .setTimeout(20000)
            .build(),
      );

      // Connection event handlers
      _socket!
        ..onConnect((_) {
          _isConnected = true;
          _reconnectAttempts = 0;
          _cancelReconnectTimer();
          onConnected?.call();
          // Subscribe to match updates
          _socket!.emit('subscribe', matchId);
        })
        ..onDisconnect((_) {
          _isConnected = false;
          onDisconnected?.call();
          _handleDisconnect();
        })
        ..onConnectError((data) {
          _isConnected = false;
          onError?.call('Connection error: ${data.toString()}');
          _handleDisconnect();
        })
        ..onError((data) {
          _isConnected = false;
          onError?.call('Socket error: ${data.toString()}');
          _handleDisconnect();
        })
        // Subscription events
        ..on('subscribed', (data) {
          if (data is Map<String, dynamic>) {
            onSubscribed?.call(data);
          }
        })
        ..on('error', (data) {
          if (data is Map<String, dynamic>) {
            onSubscribeError?.call(data);
          } else if (data != null) {
            onError?.call(data.toString());
          }
        })
        // Score updates
        ..on('scoreUpdate', (data) {
          if (data is Map<String, dynamic>) {
            onScoreUpdate?.call(data);
          }
        })
        // Innings end
        ..on('inningsEnded', (data) {
          if (data is Map<String, dynamic>) {
            onInningsEnded?.call(data);
          }
        });
    } catch (e) {
      _isConnected = false;
      onError?.call('Failed to connect: $e');
    }
  }

  Future<void> disconnect() async {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _currentMatchId = null;
  }

  void dispose() {
    disconnect();
  }

  // Subscribe to a different match without full disconnect
  Future<void> subscribeToMatch(String matchId) async {
    if (_isConnected && _socket != null) {
      _socket!.emit('subscribe', matchId);
      _currentMatchId = matchId;
    }
  }

  // Unsubscribe from current match
  Future<void> unsubscribeFromMatch() async {
    if (_isConnected && _socket != null && _currentMatchId != null) {
      _socket!.emit('unsubscribe', _currentMatchId);
      _currentMatchId = null;
    }
  }
}
