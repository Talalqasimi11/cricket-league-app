import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'network_manager.dart';

/// A WebSocket manager for handling live match updates
class WebSocketManager {
  static final WebSocketManager _instance = WebSocketManager._internal();
  static WebSocketManager get instance => _instance;

  WebSocketChannel? _channel;
  bool _isConnected = false;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  static const Duration pingInterval = Duration(seconds: 30);
  static const Duration reconnectDelay = Duration(seconds: 5);

  final _messageController = StreamController<dynamic>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();

  Stream<dynamic> get messageStream => _messageController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  bool get isConnected => _isConnected;

  WebSocketManager._internal();

  Future<void> connect(String matchId) async {
    if (_isConnected) return;

    try {
      final wsUrl = await _getWebSocketUrl(matchId);
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel?.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: true,
      );

      _isConnected = true;
      _connectionStatusController.add(true);
      _reconnectAttempts = 0;
      _startPingTimer();

      debugPrint('WebSocket connected successfully');
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
      _handleError(e);
    }
  }

  Future<String> _getWebSocketUrl(String matchId) async {
    final baseUrl = ApiClient.baseUrl;
    final wsBase = baseUrl.replaceFirst('http', 'ws');
    final token = await ApiClient.instance.token;
    return '$wsBase/ws/matches/$matchId${token != null ? '?token=$token' : ''}';
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (_) => _sendPing());
  }

  void _sendPing() {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode({'type': 'ping'}));
      } catch (e) {
        debugPrint('Error sending ping: $e');
        _handleError(e);
      }
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);

      if (data['type'] == 'pong') {
        // Handle pong response
        return;
      }

      _messageController.add(data);
    } catch (e) {
      debugPrint('Error processing message: $e');
    }
  }

  void _handleError(dynamic error) {
    debugPrint('WebSocket error: $error');
    _isConnected = false;
    _connectionStatusController.add(false);
    _attemptReconnect();
  }

  void _handleDisconnect() {
    debugPrint('WebSocket disconnected');
    _isConnected = false;
    _connectionStatusController.add(false);
    _pingTimer?.cancel();
    _attemptReconnect();
  }

  void _attemptReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      debugPrint('Max reconnection attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      reconnectDelay * (_reconnectAttempts + 1),
      () async {
        if (!_isConnected &&
            await NetworkManager.instance.checkConnectivity()) {
          _reconnectAttempts++;
          debugPrint('Attempting to reconnect (attempt $_reconnectAttempts)');
          connect(await _getCurrentMatchId());
        }
      },
    );
  }

  Future<String> _getCurrentMatchId() async {
    // Implement logic to get current match ID from state management
    // For now, return empty string
    return '';
  }

  void sendMessage(Map<String, dynamic> message) {
    if (!_isConnected) {
      debugPrint('Cannot send message: WebSocket not connected');
      return;
    }

    try {
      _channel?.sink.add(jsonEncode(message));
    } catch (e) {
      debugPrint('Error sending message: $e');
      _handleError(e);
    }
  }

  Future<void> disconnect() async {
    _isConnected = false;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    await _channel?.sink.close();
    _connectionStatusController.add(false);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionStatusController.close();
  }
}
