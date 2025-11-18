
import 'dart:async';
import 'dart:developer' as developer;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_client.dart';


enum WebSocketState {
  disconnected,
  connecting,
  connected,
  disposed,
}





class WebSocketService {
  WebSocketService._();
  static final WebSocketService instance = WebSocketService._();

  IO.Socket? _socket;
  String? _currentMatchId;
  WebSocketState _state = WebSocketState.disconnected;

  // Reconnection configuration
  static const int _maxReconnectAttempts = 5;
  static const int _initialReconnectDelay = 1000;
  static const int _maxReconnectDelay = 5000;
  static const int _connectionTimeout = 20000;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _connectionTimeoutTimer;

  // Callbacks
  Function(Map<String, dynamic>)? onScoreUpdate;
  Function(Map<String, dynamic>)? onInningsEnded;
  Function(String)? onError;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(Map<String, dynamic>)? onSubscribed;
  Function(Map<String, dynamic>)? onSubscribeError;

  void _setState(WebSocketState newState) {
    _state = newState;
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _cancelConnectionTimeout() {
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = null;
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

  bool get isConnected => _state == WebSocketState.connected;
  String? get currentMatchId => _currentMatchId;

  // Get WebSocket URL from base URL
  String _getWebSocketUrl(String baseUrl) {
    if (baseUrl.startsWith('https://')) {
      return baseUrl.replaceFirst('https://', 'wss://');
    } else {
      return baseUrl.replaceFirst('http://', 'ws://');
    }
  }

  Future<void> connect(String matchId) async {
    // Validate state - don't connect if disposed
    if (_state == WebSocketState.disposed) {
      developer.log('[WebSocket] Cannot connect - service disposed');
      return;
    }
    
    // Don't reconnect if already connected to the same match
    if (_state == WebSocketState.connected && _currentMatchId == matchId) {
      developer.log('[WebSocket] Already connected to match $matchId');
      return;
    }
    
    // Don't allow connection if currently connecting
    if (_state == WebSocketState.connecting) {
      developer.log('[WebSocket] Connection already in progress');
      return;
    }

    // Disconnect if connected to a different match
    if (_currentMatchId != null && _currentMatchId != matchId) {
      developer.log('[WebSocket] Disconnecting from previous match $_currentMatchId');
      await disconnect();
    }

    _setState(WebSocketState.connecting);
    _currentMatchId = matchId;

    // Start connection timeout
    _cancelConnectionTimeout();
    _connectionTimeoutTimer = Timer(const Duration(milliseconds: _connectionTimeout), () {
      if (_state == WebSocketState.connecting) {
        developer.log('[WebSocket] Connection timeout');
        _setState(WebSocketState.disconnected);
        onError?.call('Connection timeout after ${_connectionTimeout}ms');
        _handleDisconnect();
      }
    });

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

      // Create Socket.IO connection options
      final options = IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(_initialReconnectDelay)
          .setReconnectionDelayMax(_maxReconnectDelay)
          .setTimeout(_connectionTimeout);

      // Only set auth if token is available (for authenticated users)
      if (token != null && token.isNotEmpty) {
        options.setAuth({'token': token});
      }

      // Create Socket.IO connection to live-score namespace
      _socket = IO.io('$wsUrl/live-score', options.build());

      // Connection event handlers
      _socket!
        ..onConnect((_) {
          _cancelConnectionTimeout();
          _setState(WebSocketState.connected);
          _reconnectAttempts = 0;
          _cancelReconnectTimer();
          developer.log('[WebSocket] Connected to match $matchId');
          onConnected?.call();
          // Subscribe to match updates with proper payload format
          _socket!.emit('subscribe', {'matchId': matchId});
        })
        ..onDisconnect((_) {
          _cancelConnectionTimeout();
          developer.log('[WebSocket] Disconnected');
          if (_state != WebSocketState.disposed) {
            _setState(WebSocketState.disconnected);
            onDisconnected?.call();
            _handleDisconnect();
          }
        })
        ..onConnectError((data) {
          _cancelConnectionTimeout();
          developer.log('[WebSocket] Connection error: $data');
          if (_state != WebSocketState.disposed) {
            _setState(WebSocketState.disconnected);
            onError?.call('Connection error: ${data.toString()}');
            _handleDisconnect();
          }
        })
        ..onError((data) {
          developer.log('[WebSocket] Socket error: $data');
          onError?.call('Socket error: ${data.toString()}');
        })
        // Subscription events
        ..on('subscribed', (data) {
          if (data is Map<String, dynamic>) {
            developer.log('[WebSocket] Subscribed to match updates');
            onSubscribed?.call(data);
          }
        })
        ..on('error', (data) {
          if (data is Map<String, dynamic>) {
            developer.log('[WebSocket] Subscription error: $data');
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
      _cancelConnectionTimeout();
      _setState(WebSocketState.disconnected);
      developer.log('[WebSocket] Failed to connect: $e');
      onError?.call('Failed to connect: $e');
    }
  }

  Future<void> disconnect() async {
    developer.log('[WebSocket] Disconnecting...');
    
    // Cancel all timers
    _cancelReconnectTimer();
    _cancelConnectionTimeout();
    
    // Clear event handlers before disconnecting
    _socket?.clearListeners();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    
    _setState(WebSocketState.disconnected);
    _currentMatchId = null;
    _reconnectAttempts = 0;
    
    developer.log('[WebSocket] Disconnected successfully');
  }

  void dispose() {
    developer.log('[WebSocket] Disposing service...');
    
    _setState(WebSocketState.disposed);
    
    // Cancel all timers
    _cancelReconnectTimer();
    _cancelConnectionTimeout();
    
    // Clear all callbacks to prevent memory leaks
    onScoreUpdate = null;
    onInningsEnded = null;
    onError = null;
    onConnected = null;
    onDisconnected = null;
    onSubscribed = null;
    onSubscribeError = null;
    
    // Disconnect socket
    _socket?.clearListeners();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    
    _currentMatchId = null;
    _reconnectAttempts = 0;
    
    developer.log('[WebSocket] Service disposed successfully');
  }

  // Subscribe to a different match without full disconnect
  Future<void> subscribeToMatch(String matchId) async {
    if (_state == WebSocketState.connected && _socket != null) {
      developer.log('[WebSocket] Subscribing to match $matchId');
      _socket!.emit('subscribe', {'matchId': matchId});
      _currentMatchId = matchId;
    } else {
      developer.log('[WebSocket] Cannot subscribe - not connected (state: $_state)');
    }
  }

  // Unsubscribe from current match
  Future<void> unsubscribeFromMatch() async {
    if (_state == WebSocketState.connected && _socket != null && _currentMatchId != null) {
      developer.log('[WebSocket] Unsubscribing from match $_currentMatchId');
      _socket!.emit('unsubscribe', {'matchId': _currentMatchId});
      _currentMatchId = null;
    } else {
      developer.log('[WebSocket] Cannot unsubscribe - not connected or no active match');
    }
  }
}

