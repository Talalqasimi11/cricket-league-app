import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'api_client.dart';

/// Global authentication error handler that triggers automatic logout
/// when token expiry is detected
class AuthErrorHandler {
  static StreamController<AuthErrorEvent>? _authErrorController;
  static bool _isInitialized = false;

  /// Initialize the auth error handler
  static void initialize(BuildContext context) {
    if (_isInitialized) return;

    _authErrorController = StreamController<AuthErrorEvent>.broadcast();
    _isInitialized = true;

    // Listen for auth errors and trigger logout
    _authErrorController?.stream.listen((event) {
      if (context.mounted) {
        _handleAuthError(context, event);
      }
    });

    // Also listen to ApiClient's global auth failure stream
    ApiClient.instance.onAuthFailure.listen((_) {
      if (context.mounted) {
        triggerAuthError(context, AuthErrorEvent(reason: 'API_AUTH_FAILURE'));
      }
    });
  }

  /// Trigger an authentication error event
  static void triggerAuthError(BuildContext context, AuthErrorEvent event) {
    if (!_isInitialized) {
      initialize(context);
    }
    _authErrorController?.add(event);
  }

  /// Handle authentication error by triggering logout
  static void _handleAuthError(
    BuildContext context,
    AuthErrorEvent event,
  ) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      debugPrint(
        'AuthErrorHandler: Triggering automatic logout due to: ${event.reason}',
      );

      // Show a brief message about session expiry
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Your session has expired. Please log in again.'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(8),
          duration: const Duration(seconds: 3),
        ),
      );

      // Trigger logout
      await authProvider.logout();

      // [Fixed] Check if context is still mounted after the async logout gap
      if (!context.mounted) return;

      // Navigate to login screen if not already there
      if (ModalRoute.of(context)?.settings.name != '/login') {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      debugPrint('AuthErrorHandler: Error during logout: $e');
    }
  }

  /// Check if current context has valid authentication
  static bool isAuthenticated(BuildContext context) {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      return authProvider.isAuthenticated;
    } catch (e) {
      return false;
    }
  }

  /// Dispose the controller
  static void dispose() {
    _authErrorController?.close();
    _authErrorController = null;
    _isInitialized = false;
  }
}

/// Auth error event class
class AuthErrorEvent {
  final String reason;
  final DateTime timestamp;

  AuthErrorEvent({required this.reason}) : timestamp = DateTime.now();

  @override
  String toString() => 'AuthErrorEvent(reason: $reason, time: $timestamp)';
}
